---
paths:
  - "**/{package.json,package-lock.json,npm-shrinkwrap.json,pnpm-lock.yaml,yarn.lock,bun.lockb,.npmignore}"
  - "**/{Cargo.toml,Cargo.lock,go.mod,go.sum,Gemfile,Gemfile.lock,pyproject.toml,uv.lock,poetry.lock,Podfile,Podfile.lock,Package.swift,Package.resolved}"
  - "**/requirements*.txt"
  - "**/*.{gradle,gradle.kts}"
  - "**/{webpack,vite,rollup,esbuild,babel,tsup,karma,playwright}.config.*"
  - "**/{.releaserc*,release.config.*,.goreleaser.*,.gitlab-ci.yml,mise.toml,.tool-versions}"
---
# Migrations, ports, and upgrades

- **Migrating, porting, or upgrading existing code, a build or publish config, or a dependency (a rewrite, a lint-driven refactor, a new bundler or release step, a lockfile regeneration, a version bump):** list what the old version did that users rely on: items it skipped or protected, flags it passed, files it shipped, resolved dependency versions, error names, output, and how it handled null, undefined, or inherited input. Read the old code or config; for a bump, read the changelog and `rg` each name it renames or removes. Diff old and new output, built artifacts, package file list, and resolved versions, and report each difference. Call the change behavior-neutral only when that diff shows it. Skip the artifact diff for a patch bump of a dev-only dependency that changes no output.
