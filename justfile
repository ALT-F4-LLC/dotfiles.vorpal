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

doc-validate:
    .docket/bin/doc-validate

citation-check:
    .docket/bin/citation-check

tdd-preflight:
    .docket/bin/tdd-preflight

reserved-name-check:
    .docket/bin/reserved-name-check

ac-commands:
    .docket/bin/ac-commands

frozen-drift-check:
    .docket/bin/frozen-drift-check
