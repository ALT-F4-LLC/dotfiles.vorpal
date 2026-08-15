activate:
    "$(vorpal build --path 'user')/bin/vorpal-activate"

build:
    cargo build --locked --offline --all-targets

tests:
    cargo test --locked --offline

self-hygiene:
    cargo fmt --all -- --check
    cargo clippy --locked --offline --all-targets -- -D warnings

secret-scan:
    .docket/bin/secret-scan

ac-commands:
    .docket/bin/ac-commands
