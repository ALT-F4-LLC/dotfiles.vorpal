#!/usr/bin/env python3
"""Fixture-driven checks for singleton_wait.sh -- the lock-guarded
background-wait helper (TOCTOU-safe atomic-mkdir claim, atomic pid
publication, and atomic mv-based reclaim-ownership handoff).

Standalone (no pytest): ``python3 src/user/claude-code/scripts/test/test_singleton_wait.py``.
Exit 0 = all asserts pass. Drives the real CLI via subprocess against an
isolated SINGLETON_WAIT_LOCK_ROOT temp dir per test (never the real
/tmp/claude/wait-locks) so tests cannot collide with each other or with a
live session. Every test that spawns a poller cleans it up (terminate/kill)
in a finally block, even on assertion failure, so a failing test run does
not itself leak processes -- the exact leak class this script exists to
guard against.
"""
import os
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCRIPT = HERE.parent / "singleton_wait.sh"


def make_lock_root():
    return tempfile.mkdtemp(prefix="singleton_wait_test_")


def spawn(key, interval, *condition_cmd, lock_root):
    env = {**os.environ, "SINGLETON_WAIT_LOCK_ROOT": lock_root}
    return subprocess.Popen(
        ["bash", str(SCRIPT), key, str(interval), *condition_cmd],
        cwd=str(HERE), env=env,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
    )


def run(key, interval, *condition_cmd, lock_root):
    proc = spawn(key, interval, *condition_cmd, lock_root=lock_root)
    out, err = proc.communicate(timeout=15)
    return proc.returncode, out, err


def kill(proc):
    if proc.poll() is None:
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            # A well-behaved poller now exits promptly on SIGTERM (see the
            # split EXIT/INT/TERM traps in singleton_wait.sh), so needing
            # this fallback here is itself a signal-handling regression --
            # surface it loudly instead of silently masking it.
            print(f"WARNING: pid {proc.pid} did not exit within 5s of SIGTERM "
                  f"(fell back to SIGKILL) -- possible signal-handling regression",
                  file=sys.stderr)
            proc.kill()
            proc.wait(timeout=5)


def wait_for(predicate, timeout=10, interval=0.05):
    deadline = time.time() + timeout
    while time.time() < deadline:
        if predicate():
            return True
        time.sleep(interval)
    return predicate()


def test_arm_creates_lock_dir_and_pid_file():
    lock_root = make_lock_root()
    try:
        flag = Path(lock_root) / "FLAG"
        p = spawn("arm-key", 1, "test", "-f", str(flag), lock_root=lock_root)
        try:
            lock_dir = Path(lock_root) / "arm-key"
            assert wait_for(lambda: (lock_dir / "pid").exists()), "lock dir/pid file never appeared"
            pid_text = (lock_dir / "pid").read_text().strip()
            assert pid_text == str(p.pid), f"pid file contains {pid_text!r}, expected {p.pid}"
        finally:
            kill(p)
    finally:
        shutil.rmtree(lock_root, ignore_errors=True)


def test_second_invocation_same_key_exits_already_armed():
    lock_root = make_lock_root()
    try:
        flag = Path(lock_root) / "FLAG"
        p1 = spawn("dup-key", 1, "test", "-f", str(flag), lock_root=lock_root)
        try:
            lock_dir = Path(lock_root) / "dup-key"
            assert wait_for(lambda: (lock_dir / "pid").exists()), "instance 1 never armed"

            start = time.time()
            code, out, err = run("dup-key", 1, "test", "-f", str(flag), lock_root=lock_root)
            elapsed = time.time() - start

            assert code == 3, f"exit {code}: {out}{err}"
            assert f"already-armed key=dup-key pid={p1.pid}" in out, out
            assert elapsed < 10, f"instance 2 took {elapsed:.1f}s (expected <10s band)"
            assert p1.poll() is None, "instance 1 (the sole poller) must still be running"
        finally:
            kill(p1)
    finally:
        shutil.rmtree(lock_root, ignore_errors=True)


def test_condition_met_exits_zero_and_removes_lock():
    lock_root = make_lock_root()
    try:
        flag = Path(lock_root) / "FLAG"
        p = spawn("met-key", 1, "test", "-f", str(flag), lock_root=lock_root)
        try:
            lock_dir = Path(lock_root) / "met-key"
            assert wait_for(lambda: (lock_dir / "pid").exists()), "instance never armed"
            flag.touch()
            out, err = p.communicate(timeout=10)
            assert p.returncode == 0, f"exit {p.returncode}: {out}{err}"
            assert "condition-met key=met-key" in out, out
            assert not lock_dir.exists(), "lock dir must be removed on condition-met"
        finally:
            kill(p)
    finally:
        shutil.rmtree(lock_root, ignore_errors=True)


def test_dead_pid_lock_is_reclaimed():
    lock_root = make_lock_root()
    try:
        # Produce a genuinely-exited (reaped) pid to seed a stale lock with.
        dead = subprocess.Popen(["bash", "-c", "exit 0"])
        dead.wait(timeout=5)
        dead_pid = dead.pid

        lock_dir = Path(lock_root) / "dead-key"
        lock_dir.mkdir()
        (lock_dir / "pid").write_text(f"{dead_pid}\n")

        code, out, err = run("dead-key", 1, "true", lock_root=lock_root)
        assert code == 0, f"exit {code}: {out}{err}"
        assert "condition-met key=dead-key" in out, out
    finally:
        shutil.rmtree(lock_root, ignore_errors=True)


def test_prepublish_window_never_deletes_pidless_lock():
    # Pins the mkdir-to-publish window itself (deterministically, not left
    # to the probabilistic N-way race test below): a lock dir that never
    # gets a pid file (simulating a claim frozen mid-publish, or the window
    # itself) must never be reclaimed -- only a *read* dead pid may trigger
    # reclaim. The invocation must exhaust its backoff budget, report the
    # lock as (conservatively) armed, and leave the lock dir intact.
    lock_root = make_lock_root()
    try:
        lock_dir = Path(lock_root) / "prepublish-key"
        lock_dir.mkdir()  # no pid file, ever, for the duration of this test

        start = time.time()
        code, out, err = run("prepublish-key", 1, "true", lock_root=lock_root)
        elapsed = time.time() - start

        assert code == 3, f"exit {code}: {out}{err}"
        assert "already-armed key=prepublish-key pid=unknown" in out, out
        assert elapsed >= 1.5, f"expected the ~2s backoff budget to be exhausted, took {elapsed:.2f}s"
        assert elapsed < 10, f"backoff should not exceed the band, took {elapsed:.2f}s"
        assert lock_dir.exists(), "a pid-less lock must never be deleted (TOCTOU guard)"
    finally:
        shutil.rmtree(lock_root, ignore_errors=True)


def test_unwritable_lock_root_exits_two_no_process_left_behind():
    lock_root = make_lock_root()
    try:
        os.chmod(lock_root, 0o500)
        code, out, err = run("unwritable-key", 1, "true", lock_root=lock_root)
        assert code == 2, f"exit {code}: {out}{err}"
        assert "SINGLETON_WAIT_LOCK_ROOT" in err, err
        assert not any(Path(lock_root).iterdir()), "no lock dir should have been created"
    finally:
        os.chmod(lock_root, 0o700)
        shutil.rmtree(lock_root, ignore_errors=True)


def test_key_sanitization_collides_equivalent_keys():
    lock_root = make_lock_root()
    try:
        flag = Path(lock_root) / "FLAG"
        p1 = spawn("a/b:c", 1, "test", "-f", str(flag), lock_root=lock_root)
        try:
            lock_dir = Path(lock_root) / "a_b_c"
            assert wait_for(lambda: (lock_dir / "pid").exists()), "instance 1 never armed"

            code, out, err = run("a b c", 1, "test", "-f", str(flag), lock_root=lock_root)
            assert code == 3, f"exit {code}: {out}{err}"
            assert "already-armed key=a b c" in out, out
        finally:
            kill(p1)
    finally:
        shutil.rmtree(lock_root, ignore_errors=True)


def test_n_simultaneous_invocations_exactly_one_wins():
    lock_root = make_lock_root()
    n = 5
    procs = []
    try:
        flag = Path(lock_root) / "FLAG"  # never created -> winner keeps polling
        # All N launched back-to-back before any is awaited/communicated
        # with -- true concurrency, not a sequenced arm-then-invoke.
        procs = [spawn("race-key", 1, "test", "-f", str(flag), lock_root=lock_root)
                 for _ in range(n)]

        exited = {}
        deadline = time.time() + 10
        while time.time() < deadline and len(exited) < n - 1:
            for p in procs:
                if p not in exited and p.poll() is not None:
                    exited[p] = p
            time.sleep(0.05)

        assert len(exited) == n - 1, f"expected {n - 1} losers to exit, got {len(exited)}"
        still_running = [p for p in procs if p not in exited]
        assert len(still_running) == 1, f"expected exactly 1 still-armed poller, got {len(still_running)}"

        for p in exited.values():
            out, err = p.communicate(timeout=5)
            assert p.returncode == 3, f"loser exit {p.returncode}: {out}{err}"
            assert "already-armed key=race-key" in out, out

        winner = still_running[0]
        lock_dir = Path(lock_root) / "race-key"
        pid_text = (lock_dir / "pid").read_text().strip()
        assert pid_text == str(winner.pid), f"lock pid {pid_text} does not match sole survivor {winner.pid}"
    finally:
        for p in procs:
            kill(p)
        shutil.rmtree(lock_root, ignore_errors=True)


def test_sigterm_exits_promptly_and_removes_lock():
    # Pins the split-trap fix directly: a combined `trap ... EXIT INT TERM`
    # lets bash RESUME after the signal (the Blocker this arm guards
    # against) -- the poller would survive with its lock already deleted.
    # Asserts the exit via a bare terminate()/wait() (NOT the kill() test
    # helper), so a SIGKILL fallback can never mask a regression here.
    lock_root = make_lock_root()
    try:
        flag = Path(lock_root) / "FLAG"  # never created -> poller keeps polling until signaled
        p = spawn("term-key", 1, "test", "-f", str(flag), lock_root=lock_root)
        try:
            lock_dir = Path(lock_root) / "term-key"
            assert wait_for(lambda: (lock_dir / "pid").exists()), "instance never armed"

            p.terminate()  # SIGTERM
            start = time.time()
            try:
                p.wait(timeout=5)
            except subprocess.TimeoutExpired:
                raise AssertionError(
                    "poller did not exit within 5s of SIGTERM -- combined "
                    "EXIT INT TERM trap regression (bash resumed instead of exiting)"
                )
            elapsed = time.time() - start

            assert p.returncode == 143, f"expected exit 143 (SIGTERM trap), got {p.returncode}"
            assert elapsed < 5, f"poller took {elapsed:.1f}s to exit after SIGTERM"
            assert not lock_dir.exists(), "lock dir must be removed after SIGTERM"
        finally:
            kill(p)
    finally:
        shutil.rmtree(lock_root, ignore_errors=True)


def test_bad_arg_count_exits_two_no_lock_created():
    lock_root = make_lock_root()
    try:
        env = {**os.environ, "SINGLETON_WAIT_LOCK_ROOT": lock_root}
        proc = subprocess.run(["bash", str(SCRIPT), "only-key"], cwd=str(HERE), env=env,
                               capture_output=True, text=True, timeout=10)
        assert proc.returncode == 2, f"exit {proc.returncode}: {proc.stdout}{proc.stderr}"
        assert not any(Path(lock_root).iterdir()), "usage error must not create a lock"
    finally:
        shutil.rmtree(lock_root, ignore_errors=True)


def main():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for test in tests:
        test()
        print(f"ok  {test.__name__}")
    print(f"\n{len(tests)} passed")


if __name__ == "__main__":
    main()
