---
disable-model-invocation: true
name: perf-compare
description: >
  Compare the load performance and bundle size of two page or build variants
  over repeated browser runs. Explicit-only.
---

Arguments: a baseline and a candidate: URLs, builds, branches, or MR/PRs.

Measure each variant yourself. Do not ask the user to export HARs, switch
variants, or click, unless the page needs a real user gesture that automation
cannot give. Keep scripts, traces, HARs, and raw data under
`~/.cache/agents/scratch/<task>/`. Never commit them.

## Set up

1. Load [browser](../browser/SKILL.md). Run headed only when the user wants to watch.
2. Resolve each variant to a URL. Read the build and hosted-build URLs from the repo docs.
   Build locally only when no hosted build exists. Load [worktree](../worktree/SKILL.md) first.
3. To swap build files on one page, use a Playwright script with
   `page.route()`. The Chrome MCPs have no request interception tool.
4. Before you measure, check that the feature under test renders in the
   automated browser.

## Measure

1. Use one network and CPU profile for all variants. Default: Slow 4G and 4x CPU.
   Check that the MCP `emulate` tool sets both. If not, set them with CDP in Playwright.
2. Use a new browser context for each cold run. Report warm runs separately.
3. Run each variant at least 5 times. Interleave the variants to spread drift.
4. Per run, record LCP, load time, long-task time, transfer bytes, and request
   count. Use `performance_start_trace`, `performance_stop_trace`, and
   `list_network_requests` in the MCP, or the Performance API and a HAR in Playwright.
5. Run Lighthouse only when the user asks.

## Bundle size

Use the repo's own size scripts: a package script, a CI size job, or its
report artifact. Find them in the repo docs and the lockfile tool's scripts
(npm, pnpm, yarn, bun, uv, poetry, cargo, go). Build both variants with the
same command. When the repo has no size tooling, use `brotli-size` and
`gzip-size` on each output file.

## Fall back

- The feature does not render in automation: tell the user. Give one console
  script for their browser that prints all metrics as one JSON line.
- Bot protection or login blocks automation: ask for one login step, then continue.

## Report

- One table per metric group: variant, median, min, max, and delta to baseline.
- A delta inside the min-to-max spread is inconclusive.
- State the run count, profile, browser, and machine.
