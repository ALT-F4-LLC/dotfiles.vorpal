-- Rex configuration.

-- host_worktree: open an existing project worktree on this machine or another Rex host.
--
-- Projects live at ~/Development/repository/github.com/ALT-F4-LLC/<project>.git
-- on every host, with one directory per worktree. A worktree name may contain
-- slashes, such as feature/docket-daemon.
--
-- The action keeps one session per worktree on its host, labelled
-- "<project>:<worktree>", and reuses it when present. From the palette it asks
-- for a host, then for a worktree on that host. From the CLI:
--
--   rex do host_worktree host=r210-01 project=docket worktree=feature/docket-daemon
--
-- host=local, listed first in the palette as "This machine", opens the
-- worktree on this machine through its own server.
--
-- The app only switches to the session, from the palette or the CLI, when its
-- Remote Control setting is on; otherwise the action reports that as an error
-- after opening the session. Add switch=false to only open it.
--
-- Hosts are reached with rex.server(label), this machine with rex.call. The only filesystem view a host
-- offers is a terminal block's list_dir method, so listings go through a
-- terminal block on that host. Paths enter terminals only through the cwd
-- option, never through shell text.

local ROOT = "Development/repository/github.com/ALT-F4-LLC"
local TERMINAL = "com.superlogical.terminal"
local SHELL_FLAVOR = "com.superlogical.terminal.shell"
local PROBE_LABEL = "host_worktree-probe"

-- The host label that means this machine, reached through the home server.
local LOCAL = "local"

-- Directories of a bare repository that are never worktrees.
local GIT_INTERNAL = {
  branches = true, hooks = true, info = true, logs = true,
  objects = true, refs = true, remotes = true, worktrees = true,
}

-- Host shells don't report their directory (OSC 7), so the terminal reports
-- it once at start, then execs the login shell. The text is constant: the
-- directory comes from the block's cwd option.
local WRAPPER =
  [[printf '\033]7;file://%s%s\033\\' "$(uname -n)" "$PWD"; exec "${SHELL:-/bin/sh}" -l]]

-- Remote calls, session creation, and verification must fit in the action's
-- 30 second limit. Time spent waiting on a prompt doesn't count. The action
-- spends at most BUDGET seconds outside prompts, and gives each rex
-- subprocess what is left, capped by its kind. The opening worker stops
-- before creating after CREATE_DEADLINE and waits at most PWD_WAIT for a new
-- terminal, so it finishes within its cap.
local BUDGET = 27
local CAP = { hosts = 5, list = 10, open = 20 }
local CREATE_DEADLINE = 6
local PWD_WAIT = 5

-- The longest session label, which bounds the worktree names the action can
-- open and so how deep the picker looks.
local MAX_LABEL = 128

-- A probe removes its own session after PROBE_LIFETIME seconds, longer than
-- any run, so a worker killed by its timeout leaves nothing behind. The
-- text is constant; rex sets REX_SESSION in each terminal.
local PROBE_LIFETIME = 30
local PROBE_COMMAND = {
  "/bin/sh", "-c", "sleep " .. PROBE_LIFETIME .. '; exec rex kill "$REX_SESSION"',
}

-- When the action must finish by, moved later by time spent in prompts.
local deadline = nil

local function fail(msg)
  error("host_worktree: " .. msg, 0)
end

local function sleep(seconds)
  if rex.sleep then return rex.sleep(seconds) end
  rex.exec({ "sleep", tostring(seconds) })
end

local function contains(list, value)
  for _, v in ipairs(list) do
    if v == value then return true end
  end
  return false
end

-- Validation ---------------------------------------------------------------

local function check_project(project)
  project = project:gsub("%.git$", "")
  if project == "" or project == "." or project == ".."
      or not project:match("^[%w][%w._-]*$") or #project > 100 then
    fail(string.format("project %q is not a valid project name", project))
  end
  return project
end

local function check_worktree(worktree)
  if worktree == "" or #worktree > 200 then
    fail(string.format("worktree %q is not a valid worktree name", worktree))
  end
  local parts = {}
  for part in (worktree .. "/"):gmatch("(.-)/") do
    if part == "" or part == "." or part == ".."
        or not part:match("^[%w._@+-]+$") then
      fail(string.format("worktree %q is not a valid worktree name", worktree))
    end
    table.insert(parts, part)
  end
  return parts
end

-- Hosts --------------------------------------------------------------------

local Host = {}
Host.__index = Host

-- Every host connected during this run, so the worker can clean up probes.
local HOSTS = {}
local FORCE_PROBE = false

local function connect(ctx, label)
  local servers = rex.servers()
  local server
  if label == LOCAL then
    if contains(servers, LOCAL) then
      fail(string.format("a host in `rex hosts` is labelled %q, so it is ambiguous with this machine", LOCAL))
    end
    -- With ctx.server set, plain rex.call goes to the host the app is
    -- viewing, not this machine. The worker always runs without it.
    if ctx.server ~= nil then
      fail("host=local needs a run whose server is this machine (no -S or REX_SERVER naming another host)")
    end
    server = { call = function(method, a) return rex.call(method, a) end }
  else
    if not contains(servers, label) then
      fail(string.format("%q is not a host in `rex hosts` or %q (known: %s)",
        label, LOCAL, table.concat(servers, ", ")))
    end
    server = rex.server(label)
  end
  local status, err = server.call("server.status", {})
  if status == nil then
    fail(string.format("cannot reach %s: %s", label, tostring(err)))
  end
  local host_id = status.host_id
  -- With ctx.server set, plain rex.call goes to the host the app is
  -- viewing, so this machine's identity is only known without it.
  local local_id
  if label == LOCAL then
    local_id = host_id
  elseif ctx.server == nil then
    local here = rex.call("server.status", {})
    local_id = here and here.host_id
    if local_id ~= nil and local_id == host_id then
      fail(string.format("%s answered as this machine (host %s); refusing", label, host_id))
    end
  end
  local host = setmetatable({
    label = label, server = server, host_id = host_id,
    local_id = local_id, attached = {}, probe = nil, leftovers = {}, skipped = {},
  }, Host)
  table.insert(HOSTS, host)
  return host
end

function Host:call(method, args)
  local r, err = self.server.call(method, args)
  if r == nil then
    fail(string.format("%s on %s failed: %s", method, self.label, tostring(err)))
  end
  return r
end

function Host:attach(session_id)
  if not self.attached[session_id] then
    local r = self:call("session.attach", { session_id = session_id })
    self.attached[session_id] = r.view or {}
  end
  return self.attached[session_id]
end

function Host:view(session_id)
  self.attached[session_id] = nil
  return self:attach(session_id)
end

local function terminal_blocks(view)
  local out = {}
  for _, w in ipairs(view.windows or {}) do
    for _, layer in ipairs(w.layers or {}) do
      for _, b in ipairs(layer.blocks or {}) do
        if b.creator_name == TERMINAL then
          table.insert(out, { block_id = b.block_id, window_id = w.window_id })
        end
      end
    end
  end
  return out
end

function Host:sessions()
  return self:call("session.list", {}).sessions or {}
end

-- Removes dead probes: sessions labelled PROBE_LABEL with no windows and no
-- blocks. A live probe always has its block, so these are probes whose
-- program exited without removing its session, as when rex wasn't on its
-- PATH. Failures here are ignored; the sweep only tidies.
function Host:sweep_probes(sessions)
  if FORCE_PROBE then sessions = self:sessions() end
  for _, s in ipairs(sessions) do
    if s.label == PROBE_LABEL then
      -- Session methods need an attached connection; attach's reply is the view.
      local att = self.server.call("session.attach", { session_id = s.session_id })
      local list = att and self.server.call("session.list_blocks", { session_id = s.session_id })
      if att and list and #((att.view or {}).windows or {}) == 0 and #(list.blocks or {}) == 0 then
        self.attached[s.session_id] = att.view or {}
        self:destroy(s.session_id)
      end
    end
  end
end

-- A terminal block to list directories through. Prefer a session this
-- action keeps, then any session, then a probe session made for the listing.
-- list_dir only reads; nothing is typed into a borrowed block. Another run's
-- probe is never borrowed, since it removes itself on its own schedule.
function Host:lister()
  if self.list_block then return self.list_block end
  -- probe=true (worker only) skips borrowing, to test the probe path.
  local sessions = FORCE_PROBE and {} or self:sessions()
  table.sort(sessions, function(a, b)
    local ao = (a.label or ""):find(":", 1, true) ~= nil
    local bo = (b.label or ""):find(":", 1, true) ~= nil
    return ao and not bo
  end)
  for _, s in ipairs(sessions) do
    local blocks = s.label ~= PROBE_LABEL and terminal_blocks(self:attach(s.session_id)) or {}
    if blocks[1] then
      self.list_block = { session_id = s.session_id, block_id = blocks[1].block_id }
      return self.list_block
    end
  end
  self:sweep_probes(sessions)
  local created = self:call("session.create", {
    label = PROBE_LABEL,
    initial_windows = { { layout = { block = {
      flavor = SHELL_FLAVOR,
      options = { shell = "none", command = PROBE_COMMAND },
    } } } },
  })
  self.probe = created.session_id
  self:attach(created.session_id)
  self.list_block = {
    session_id = created.session_id,
    block_id = created.initial_windows[1].block_ids[1],
  }
  return self.list_block
end

local function not_found(err)
  return tostring(err):find("session_not_found", 1, true) ~= nil
end

-- Destroys a session, treating one that is already gone, such as a probe
-- that removed itself, as destroyed. Never raises, so cleanup always runs.
function Host:destroy(session_id)
  if not self.attached[session_id] then
    local _, aerr = self.server.call("session.attach", { session_id = session_id })
    if aerr ~= nil and not not_found(aerr) then return aerr end
  end
  local _, err = self.server.call("session.destroy", { session_id = session_id })
  if err ~= nil and not not_found(err) then return err end
  self.attached[session_id] = nil
  return nil
end

function Host:cleanup()
  if self.probe then
    local err = self:destroy(self.probe)
    if err ~= nil then
      table.insert(self.leftovers, string.format("probe session %s on %s: %s",
        self.probe, self.label, err))
    end
    self.probe = nil
    self.list_block = nil
  end
end

-- prefix narrows the listing to names that start with it, ignoring case.
function Host:list_dir(path, files, allow_truncated, prefix)
  local b = self:lister()
  local r = self:call(TERMINAL .. ".list_dir", {
    session_id = b.session_id, block_id = b.block_id,
    args = { path = path, files = files or false, prefix = prefix },
  })
  r.entries = r.entries or {}
  if r.truncated and not allow_truncated then
    fail(string.format("listing %s on %s was truncated", r.path or path, self.label))
  end
  return r
end

function Host:root()
  if not self.root_path then
    local r = self:list_dir("~")
    if r.status ~= "ok" or (r.home or "") == "" then
      fail(string.format("cannot find the home directory on %s", self.label))
    end
    self.root_path = r.home .. "/" .. ROOT
  end
  return self.root_path
end

local function find_entry(listing, name)
  for _, e in ipairs(listing.entries or {}) do
    if e.name == name then return e end
  end
  return nil
end

-- Worktrees ----------------------------------------------------------------

-- The .git entry of dir, read through a listing narrowed to names starting
-- with .git, so the directory's size doesn't matter. Returns nil and why
-- when there is none: "truncated" if the narrowed listing still didn't fit.
function Host:git_entry(dir)
  local r = self:list_dir(dir, true, true, ".git")
  if r.status ~= "ok" or r.path ~= dir then return nil, tostring(r.status) end
  local e = find_entry(r, ".git")
  if e then return e end
  return nil, r.truncated and "truncated" or "missing"
end

-- Lists the worktrees of one project as names relative to <project>.git.
-- It looks as deep as names the action can open, and only at names it
-- accepts. Directories too big to list, or left unread when time ran out,
-- are recorded in skipped, and the worktrees found so far are kept.
function Host:worktrees(project)
  local base = self:root() .. "/" .. project .. ".git"
  local found = {}
  local function walk(rel, depth)
    local dir = rel == "" and base or (base .. "/" .. rel)
    if deadline and os.time() >= deadline - 1 then
      table.insert(self.skipped, dir .. " (out of time)")
      return
    end
    local r = self:list_dir(dir, true, true)
    if r.status ~= "ok" then return end
    if rel ~= "" then
      local git = find_entry(r, ".git")
      if not git and r.truncated then git = self:git_entry(dir) end
      if git and git.file and not git.symlink then
        table.insert(found, rel)
        return
      end
    end
    if r.truncated then
      table.insert(self.skipped, dir)
      return
    end
    for _, e in ipairs(r.entries) do
      local child = rel == "" and e.name or (rel .. "/" .. e.name)
      if not e.file and not e.symlink and e.name:sub(1, 1) ~= "."
          and e.name:match("^[%w._@+-]+$")
          and #project + 1 + #child <= MAX_LABEL
          and not (depth == 0 and GIT_INTERNAL[e.name]) then
        walk(child, depth + 1)
      end
    end
  end
  walk("", 0)
  table.sort(found)
  return found
end

function Host:projects()
  local r = self:list_dir(self:root())
  if r.status ~= "ok" then
    fail(string.format("%s has no project root at %s (%s)", self.label, r.path, r.status))
  end
  local out = {}
  for _, e in ipairs(r.entries) do
    if not e.file and not e.symlink and e.name:match("^[%w][%w._-]*%.git$") then
      table.insert(out, (e.name:gsub("%.git$", "")))
    end
  end
  table.sort(out)
  return out
end

-- Confirms that <project>.git/<worktree> is a real worktree directory with
-- no symlink on the way, and returns its absolute path.
function Host:resolve(project, parts)
  local dir = self:root()
  local names = { project .. ".git" }
  for _, p in ipairs(parts) do table.insert(names, p) end
  for _, name in ipairs(names) do
    local r = self:list_dir(dir, true, true, name)
    local e = r.status == "ok" and find_entry(r, name)
    if not e and r.truncated then
      fail(string.format("listing %s on %s for %s was truncated", dir, self.label, name))
    end
    if not e or e.file then
      fail(string.format("%s/%s does not exist on %s", dir, name, self.label))
    end
    if e.symlink then
      fail(string.format("%s/%s on %s is a symlink; refusing", dir, name, self.label))
    end
    dir = dir .. "/" .. name
  end
  local git, why = self:git_entry(dir)
  if why == "truncated" then
    fail(string.format("listing %s on %s for .git was truncated", dir, self.label))
  elseif not git and why ~= "missing" then
    fail(string.format("%s is not readable on %s (%s)", dir, self.label, why))
  end
  if not git or not git.file or git.symlink then
    fail(string.format("%s on %s is not a worktree (no .git file)", dir, self.label))
  end
  return dir
end

-- Sessions -----------------------------------------------------------------

local function pwd_path(reply)
  local url = reply and reply.pwd
  if type(url) ~= "string" or url == "" then return nil end
  return url:match("^file://[^/]*(/.*)$") or url
end

function Host:block_state(session_id, block_id)
  local args = { session_id = session_id, block_id = block_id, args = {} }
  local pwd = pwd_path(self.server.call(TERMINAL .. ".pwd", args))
  local proc = self.server.call(TERMINAL .. ".process", args)
  local cwd = proc and proc.foreground and proc.foreground.cwd
  return pwd, cwd
end

function Host:find_session(label)
  for _, s in ipairs(self:sessions()) do
    if s.label == label then return s.session_id end
  end
  return nil
end

-- Reuses the session's terminal that reported the worktree as its pwd, or
-- failing that, one whose shell is in the worktree now.
function Host:reuse(session_id, label, path)
  local by_cwd
  for _, b in ipairs(terminal_blocks(self:view(session_id))) do
    local pwd, cwd = self:block_state(session_id, b.block_id)
    local found = {
      session_id = session_id, window_id = b.window_id, block_id = b.block_id,
      pwd = pwd, process_cwd = cwd, reused = true,
      drift = cwd ~= nil and cwd ~= path or nil,
    }
    if pwd == path then return found end
    if cwd == path and not by_cwd then by_cwd = found end
  end
  if by_cwd then return by_cwd end
  fail(string.format("session %q (%s) on %s has no terminal in %s; close that session "
    .. "and run the action again to get a fresh one", label, session_id, self.label, path))
end

function Host:create(label, path, worktree)
  local created = self:call("session.create", {
    label = label,
    initial_windows = { {
      window_label = worktree,
      layout = { block = {
        flavor = SHELL_FLAVOR,
        options = { cwd = path, shell = "none", command = { "/bin/sh", "-c", WRAPPER } },
      } },
    } },
  })
  local session_id = created.session_id
  local win = created.initial_windows[1]
  local block_id = win.block_ids[1]
  self:attach(session_id)
  -- The terminal reports pwd and the shell's cwd separately; wait for both.
  local pwd, cwd
  local give_up = os.time() + PWD_WAIT
  while true do
    pwd, cwd = self:block_state(session_id, block_id)
    if (pwd == path and cwd == path) or os.time() >= give_up then break end
    sleep(0.2)
  end
  if pwd ~= path or cwd ~= path then
    local err = self:destroy(session_id)
    local left = err and string.format("; could not remove session %s: %s", session_id, err) or ""
    local seen = (pwd == nil or cwd == nil) and "after waiting " .. PWD_WAIT .. "s, reported" or "started in"
    fail(string.format("new terminal on %s %s pwd=%s cwd=%s, not %s; removed it%s",
      self.label, seen, tostring(pwd), tostring(cwd), path, left))
  end
  return {
    session_id = session_id, window_id = win.window_id, block_id = block_id,
    pwd = pwd, process_cwd = cwd, reused = false,
  }
end

-- Switching ----------------------------------------------------------------

-- The app keeps one connection per host, and its Go to Session only finds
-- sessions on the server the request arrives from. So the request goes to
-- the app's connection on the host, through client.perform. The app takes
-- such requests only while its Remote Control setting is on.
function Host:select(result, app_label)
  local list, lerr = self.server.call("client.list", {})
  if list == nil then
    return string.format("failed: client.list: %s; go to %q on %s by hand",
      tostring(lerr), result.session_label, self.label)
  end
  local apps = {}
  for _, c in ipairs(list.clients or list) do
    if c.info and c.info.kind == "app" and (app_label == nil or c.info.label == app_label) then
      table.insert(apps, c)
    end
  end
  if #apps ~= 1 then
    return string.format("failed: found %d Rex apps%s connected to %s; go to %q there by hand",
      #apps, app_label and (" labelled " .. app_label) or "", self.label, result.session_label)
  end
  local _, err = self.server.call("client.perform", {
    client_id = apps[1].client_id,
    action = "session.select",
    args = { session_id = result.session_id, window_id = result.window_id },
    timeout_ms = 4000,
  })
  if err ~= nil then
    return string.format("failed: %s; go to %q on %s by hand", tostring(err), result.session_label, self.label)
  end
  return string.format("selected by app %s on %s", apps[1].info.label or apps[1].client_id, self.label)
end

-- Delegation ---------------------------------------------------------------

-- rex.server only reaches hosts that the calling client passes along, and
-- `rex do NAME` passes none. So the action, run by the server, always hands
-- remote work to a worker: this same file run as `rex do FILE --action`,
-- where the rex CLI connects to the hosts itself. Arguments go to it as argv,
-- never through a shell. The worker never prompts and never delegates.
local IN_SCRIPT = rex.args ~= nil
local THIS_FILE = (debug.getinfo(1, "S").source or ""):gsub("^@", "")

local function rex_binary(ctx)
  local home = os.getenv("HOME") or ""
  local candidate = home
    .. "/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex"
  local f = io.open(candidate, "r")
  if f then f:close() return candidate end
  if ctx.server == nil then
    local st = rex.call("server.status", {})
    local ps = st and rex.exec({ "/bin/ps", "-o", "comm=", "-p", tostring(st.pid) }, { timeout = 5 })
    local bin = ps and ps.ok and (ps.stdout:gsub("%s+$", ""))
    if bin and bin ~= "" then return bin end
  end
  fail("cannot find the rex executable needed to reach hosts")
end

-- Runs rex with argv and returns its decoded JSON output. The worker finds
-- the home server itself, so REX_SERVER isn't passed on.
local function run_rex(ctx, argv, what, cap)
  local timeout = math.min(cap, (deadline or (os.time() + BUDGET)) - os.time())
  if timeout < 3 then fail("ran out of time before " .. what .. "; nothing more was done") end
  table.insert(argv, 1, rex_binary(ctx))
  local r, err = rex.exec(argv, { timeout = timeout, env = { REX_SERVER = false } })
  if r == nil then fail("could not run rex: " .. tostring(err)) end
  if r.timed_out then fail(what .. " timed out; check `rex ls` (this machine) or `rex -S HOST ls` for a half-made session") end
  if not r.ok then
    local msg = (r.stderr ~= "" and r.stderr or r.stdout):gsub("^Error: ", ""):gsub("%s+$", "")
    error(msg, 0)
  end
  local out, derr = rex.json.decode(r.stdout)
  if out == nil then fail(what .. " printed unreadable output: " .. tostring(derr)) end
  return out
end

local function delegate(ctx, args)
  local cap = args.op == "list" and CAP.list or CAP.open
  local argv = { "do", THIS_FILE, "--action", "host_worktree", "--json", "delegated=true" }
  for _, k in ipairs({ "op", "host", "project", "worktree", "app" }) do
    if args[k] ~= nil then table.insert(argv, k .. "=" .. args[k]) end
  end
  table.insert(argv, "switch=" .. tostring(args.switch == true))
  -- The worker stops on its own before run_rex's timeout kills it.
  local left = math.min(cap, (deadline or (os.time() + BUDGET)) - os.time())
  table.insert(argv, "budget=" .. tostring(math.max(left - 2, 1)))
  return run_rex(ctx, argv, "the worker on " .. tostring(args.host), cap)
end

local function host_labels(ctx)
  local data = run_rex(ctx, { "hosts", "--json" }, "`rex hosts`", CAP.hosts)
  local labels = {}
  for _, h in ipairs(data.hosts or {}) do
    if h.host and h.host.label then table.insert(labels, h.host.label) end
  end
  return labels
end

-- Prompts ------------------------------------------------------------------

local function ask(spec)
  local asked = os.time()
  local answer, why, detail = rex.ui.pick(spec)
  if deadline then deadline = deadline + (os.time() - asked) end
  if answer ~= nil then return answer end
  if why == "cancelled" then return nil end
  fail(string.format("could not ask %q: %s%s", spec.title, tostring(why),
    detail and (" (" .. detail .. ")") or ""))
end

local function pick_host(ctx)
  local labels = host_labels(ctx)
  local items = {}
  if not contains(labels, LOCAL) then
    local name = rex.exec({ "/bin/hostname", "-s" }, { timeout = 2 })
    name = name and name.ok and (name.stdout:gsub("%s+$", "")) or ""
    table.insert(items, {
      id = LOCAL, title = "This machine",
      subtitle = name ~= "" and name or nil, icon = "server",
    })
  end
  for _, label in ipairs(labels) do
    table.insert(items, { id = label, title = label, icon = "server" })
  end
  if #items == 0 then fail("`rex hosts` lists no hosts") end
  return ask{ title = "Open worktree on host", placeholder = "Filter hosts", items = items }
end

-- The picker rows for every worktree on a host, or for one project's.
local function worktree_items(host, only_project)
  local projects = only_project and { only_project } or host:projects()
  local open = {}
  for _, s in ipairs(host:sessions()) do
    if s.label then open[s.label] = true end
  end
  local items = {}
  for _, project in ipairs(projects) do
    for _, wt in ipairs(host:worktrees(project)) do
      local label = project .. ":" .. wt
      table.insert(items, {
        id = label,
        title = project .. " / " .. wt,
        subtitle = "~/" .. ROOT .. "/" .. project .. ".git/" .. wt,
        icon = "branch",
        detail = open[label] and "open" or nil,
      })
    end
  end
  host:cleanup()
  return items
end

local function pick_worktree(label, items, only_project, skipped)
  if #items == 0 then
    fail(string.format("no worktrees found on %s%s%s", label,
      only_project and (" for " .. only_project) or "",
      skipped and ("; not searched: " .. table.concat(skipped, ", ")) or ""))
  end
  local id = ask{
    title = "Worktree on " .. (label == LOCAL and "this machine" or label),
    placeholder = "Filter by project or branch",
    items = items,
  }
  if id == nil then return nil end
  return id:match("^([^:]+):(.+)$")
end

-- Worker -------------------------------------------------------------------

local function open_worktree(ctx, label, project, worktree)
  local host = connect(ctx, label)
  local started = os.time()
  local path = host:resolve(project, check_worktree(worktree))
  local session_label = project .. ":" .. worktree
  if #session_label > 128 then
    fail(string.format("session label %q is longer than 128 characters", session_label))
  end
  local existing = host:find_session(session_label)
  host:cleanup()
  local result
  if existing then
    result = host:reuse(existing, session_label, path)
  else
    if os.time() - started > CREATE_DEADLINE then
      fail("ran out of time before creating the session; nothing was created")
    end
    result = host:create(session_label, path, worktree)
  end
  return {
    host = host.label,
    host_id = host.host_id,
    local_host_id = host.local_id,
    session_label = session_label,
    session_id = result.session_id,
    window_id = result.window_id,
    block_id = result.block_id,
    path = path,
    pwd_at_start = result.pwd,
    process_cwd = result.process_cwd,
    cwd_drifted = result.drift,
    reused = result.reused,
    leftovers = #host.leftovers > 0 and host.leftovers or nil,
  }
end

local function work(ctx, args, project)
  if not IN_SCRIPT then fail("delegated=true only works in the rex do worker") end
  if not args.host then fail("the worker needs host=") end
  FORCE_PROBE = args.probe == true
  if args.op == "list" then
    local host = connect(ctx, args.host)
    return {
      items = worktree_items(host, project),
      leftovers = #host.leftovers > 0 and host.leftovers or nil,
      too_big_to_list = #host.skipped > 0 and host.skipped or nil,
    }
  elseif args.op ~= nil then
    fail(string.format("unknown op %q", args.op))
  end
  if not project or not args.worktree then fail("the worker needs project= and worktree=") end
  local result = open_worktree(ctx, args.host, project, args.worktree)
  result.switch = "not requested"
  if args.switch then
    result.switch = HOSTS[#HOSTS]:select(result, args.app)
  end
  return result
end

-- The worker never prompts, so it can run under pcall and remove its probe
-- sessions however it ends.
local function work_safely(ctx, args, project)
  local ok, result = pcall(work, ctx, args, project)
  local left = {}
  for _, host in ipairs(HOSTS) do
    host:cleanup()
    for _, l in ipairs(host.leftovers) do table.insert(left, l) end
  end
  if not ok then
    if #left > 0 then result = tostring(result) .. "; left behind: " .. table.concat(left, "; ") end
    error(result, 0)
  end
  if #left > 0 then result.leftovers = left end
  return result
end

-- Action -------------------------------------------------------------------

rex.action{
  name = "host_worktree",
  title = "Open Worktree on Host…",
  description = "Pick a host and one of its project worktrees, and go to its session there.",
  category = "Hosts",
  keywords = "local this machine remote host server project worktree branch repository open r210",
  args = {
    host = "string?", project = "string?", worktree = "string?",
    switch = "boolean?", op = "string?", delegated = "boolean?", app = "string?", probe = "boolean?",
    budget = "string?",
  },
  run = function(ctx, args)
    local budget = args.delegated and tonumber(args.budget or "") or nil
    deadline = os.time() + (budget and math.min(budget, BUDGET) or BUDGET)
    local project = args.project and check_project(args.project)
    if args.delegated then return work_safely(ctx, args, project) end
    if args.op ~= nil then fail("op= is internal to the worker") end

    -- `rex do FILE --action host_worktree` runs here directly, with the CLI
    -- connected to the hosts; the server-run action delegates instead.
    local function remote(a)
      if IN_SCRIPT then
        a.delegated = true
        return work_safely(ctx, a, a.project)
      end
      return delegate(ctx, a)
    end

    local label = args.host or pick_host(ctx)
    if label == nil then return nil end

    local worktree = args.worktree
    if worktree == nil then
      local listed = remote({ op = "list", host = label, project = project })
      project, worktree = pick_worktree(label, listed.items or {}, project, listed.too_big_to_list)
      if worktree == nil then return nil end
    elseif project == nil then
      fail("worktree= needs project=")
    end
    check_worktree(worktree)

    -- The app that asked, so the host-side request reaches the same one.
    local app
    if ctx.client_id and ctx.server == nil then
      local c = rex.call("client.inspect", { client_id = ctx.client_id })
      local info = c and (c.client and c.client.info or c.info)
      if info and info.kind == "app" then app = info.label end
    end

    local result = remote({
      host = label, project = project, worktree = worktree,
      switch = args.switch ~= false, app = app,
    })
    if type(result.switch) == "string" and result.switch:match("^failed") then
      fail(string.format("opened %q (%s) on %s, but could not show it: %s",
        result.session_label, result.session_id, result.host, result.switch:gsub("^failed: ", "")))
    end
    return result
  end,
}

