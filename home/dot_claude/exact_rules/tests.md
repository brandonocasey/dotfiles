---
paths:
  - "**/*.test.*"
  - "**/*.spec.*"
  - "**/*_test.*"
  - "**/test_*.py"
  - "**/test/**"
  - "**/tests/**"
  - "**/__tests__/**"
  - "**/e2e/**"
---
# Tests that pass where CI runs them

- Tests must be deterministic: no real network or CDN (serve a local fixture), no fixed date compared with real file or process times (inject the clock), and wait for the event, not a fixed interval. Give each test its own temp directory name.
- Before handing off a new or changed test, spec, or harness, run it with the runner, parallelism, browser, and config CI uses (for example `cargo test`, not only nextest), and in each browser or platform a variant targets (headless, per `browser`). Confirm each new test appears in the output by name. Run a new test that depends on timing, locks, or concurrency 20 times that way. If you cannot run it where CI does, report which runner, browser, or platform it did not run in.
- When you fix a flaky test, `rg` for tests with the same pattern and fix them in the same change.
- Before using a runtime API, language feature, or test-library feature in new code or tests, check it against the oldest target the repo supports (browserslist, engines or language minimum, pinned dependency versions, CI test matrix). Guard or polyfill what that target lacks; a polyfill never calls the API it replaces. If that target runs only in CI, check support data or the dependency's changelog before pushing.
