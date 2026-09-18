---
name: benchmark-change
description: >
  Measure ROM Weaver changes to runtime, memory, compressed size, or data packs
  against a baseline. Use for optimization work and performance claims.
---

# Benchmark a ROM Weaver change

Measure the change against a recorded baseline and check that the result still meets the required output contract. Run from the target ROM Weaver checkout; resolve repository paths below against `git rev-parse --show-toplevel`, even when this skill is installed globally.

## Select an existing harness

Read `docs/development/performance.md` for the harness map and measurement method, then inspect only the script relevant to the question. Reuse the repository's command-path, disc-tool, checksum-threading, solid-extraction, or browser WASM benchmarks. Use `run-rom-weaver` for runtime setup and smoke tests when needed. Avoid adding another benchmark framework.

For identify-data changes, locate the index builder in the target revision and inspect the data format it emits. Older revisions may use `scripts/build-identify-index.mjs`; check that it exists before using that path. Use separate output directories and the same source datasets. Compare compressed transfer bytes, build/search time when affected, and record counts, names, aliases, dump tags, and checksum lookup behavior that the change promises to preserve. A smaller raw file may compress worse.

## Make the comparison equivalent

Record the baseline and candidate revisions, executable or WASM artifact, toolchain, input checksums and sizes, operation, codec, level, thread count, and hardware. Use the baseline given by the user or parent task; otherwise state the change's merge-base revision used for comparison.

Use the `worktree` skill for separate revision checkouts. Give each checkout its own Cargo target directory; use the repository's compiler caches for reuse. Do not benchmark concurrent builds or multiple contenders on the same hardware. Check that each command uses the intended revision's artifact.

Match the operation's work, including nested extraction, common-file filtering, and codec settings. Preserve the existing parity contract; compare payload bytes for cross-tool archives where metadata differs, and byte-identical outputs where the repository requires them. Use `scripts/parity-check.mjs` and the affected tests for their supported cases.

Separate warmup from measured runs. Report cold and warm cache results separately when the question depends on caching. Repeat timings enough to expose noise, and report the run count and spread. Remove each run's generated outputs before timing the next one. Require valid, nonempty outputs so an early failure or skipped write cannot look like a speedup.

## Report the result

Start with a representative input set and expand it when the change or observed variation needs more coverage. Record elapsed time, peak memory, throughput, and output size where relevant. Measure correctness and output size outside the timed section when the harness permits it.

Keep commands, raw results, and input metadata under the repository's output convention, or `dist/bench/<task>` for new artifacts. Report absolute values, relative changes, repeat variation, and correctness results. A difference within the measured noise is inconclusive. Restrict conclusions to the tested inputs and machine.

Return the measurements to the requesting task or `review`. Reuse existing results for the same revision, inputs, and settings. This skill does not start another review or change performance gates to accept a regression.
