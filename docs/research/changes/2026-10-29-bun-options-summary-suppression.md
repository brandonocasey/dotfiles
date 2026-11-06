# Agent summary suppression via BUN_OPTIONS preload

- Status (2026-11-06): current. `home/private_dot_local/share/no-agent-summary.js` exists, `home/dot_config/private_fish/conf.d/1-env.fish` and `home/dot_config/shell/env.sh` add `--preload=$HOME/.local/share/no-agent-summary.js` to `BUN_OPTIONS`.
- Topic: Settings, permissions and security
- Related: [Pin Claude Code 2.1.296](2026-10-27-pin-claude-code-2-1-296.md), [Prompt-cache TTL and permission denies](2026-10-14-cache-ttl-and-permission-denies.md)

## Change
Claude Code sends a per-agent status summary every 30 seconds, and each one resends the background agent's whole transcript. `no-agent-summary.js` (v3, from the flamerix-ai gist, MIT) is a Bun `--preload` that switches off that timer. It only installs inside Claude Code, so other Bun programs load it and skip it.

The shell env files export it through `BUN_OPTIONS`. Guards skip the preload when `$HOME` contains whitespace (Bun splits `BUN_OPTIONS` at whitespace) and fish adds it only once. The env.sh comment says to run `bun init`, `bun info` and `bun upgrade` with `env -u BUN_OPTIONS`, because Bun puts `BUN_OPTIONS` before their arguments.

Rejected alternatives: `CLAUDE_CODE_FORK_SUBAGENT=0` (removes the `fork` agent type and may not stop all summaries, because two other conditions also enable them) and `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1` (turns off background agents, which the setup relies on). The user also chose a global setting over a `claude-two` alias, an abbr or a replacement `~/.local/bin/claude` wrapper (reply: "Keep the current global setting").

## History
- 2026-10-29 — proposal: user asked "can we do this" with the gist URL. The assistant read the script (about 100 lines, no network calls, one timer) and checked 2.1.296 has the same timer, set with plain `setTimeout`. Session 77d6ff05.
- 2026-10-29 — checks: no built-in switch to turn summaries off in 2.1.296. The assistant gave three options (script, `CLAUDE_CODE_FORK_SUBAGENT=0`, `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1`); user chose the script ("use 1, but make it portable"). The user also asked about terms-of-service risk; see Evidence.
- 2026-10-29 — commit `23fc8b60 dx(claude): cut agent summary token use`: adds the script and the fish and sh `BUN_OPTIONS` exports.
- 2026-10-29 — commit `5b93ea28 fix(fish): keep one preload when HOME has spaces`: found by the tester. With a space in `$HOME` fish added the setting twice. Fixed.
- 2026-10-29 — commit `349f0b6e fix(shell): skip preload paths Bun cannot parse`: found by the reviewer. A path with whitespace gives Bun a broken value, so the preload is now skipped. The same commit documents that `bun init`, `bun info` and `bun upgrade` misread their arguments under the preload (checked against Bun source). The assistant had said earlier that other Bun programs just skip it and corrected that.
- 2026-11-06 — status check: files and `BUN_OPTIONS` documentation still present. No later commit changed the preload line.

## Results
No measurement. The gist's claim of 15-20% savings was never verified: "these calls aren't saved in session logs", and only an OpenTelemetry export shows them.

What was checked instead:
- The user ran the test command (`claude --version` with the preload and a log file) on macOS and replied "it works". Output line to look for: `preload active mode=off`.
- Tester and reviewer runs: 92 Python tests, Node tests, 12 shell cases, shellcheck and fish_indent passed. Three small bugs found and fixed (the commits above).
- Bun was not installed on the machine, so the space-in-`$HOME` case with a real Bun was never run. opencode was checked and works normally with a preload set.
- `claude -p` runs do not make these summaries in 2.1.296, so scripts that run `claude -p` do not need the preload.

Known costs from the session: an update can quietly undo it (check the script still matches the timer after a Claude Code update); the status line for each agent in the agents panel stops updating; installing means `claude daemon stop --any`, which stops running background sessions; sessions started before install keep making summaries.

## Sources
- [flamerix-ai gist](https://gist.github.com/flamerix-ai/c3905705cc4205e5de3011fa2e74efce) — the preload script and a claim of 15-20% savings. The savings figure was not verified.
- [Anthropic Consumer Terms](https://www.anthropic.com/legal/consumer-terms) — §3 no reverse engineering or "bypassing any of our systems or protective measures"; the assistant read the script as doing neither.
- [Anthropic Commercial Terms](https://www.anthropic.com/legal/commercial-terms) — D.4 "reverse engineer or duplicate the Services".
- [Claude Code legal and compliance](https://code.claude.com/docs/en/legal-and-compliance) — the rule that the Claude Code binary must not be modified applies to companies embedding it.
- [Bun zig-clap source](https://raw.githubusercontent.com/oven-sh/bun/bun-v1.3.3/src/deps/zig-clap/clap.zig) and [cli.zig](https://raw.githubusercontent.com/oven-sh/bun/bun-v1.3.3/src/cli.zig) — used for the Bun argument-parsing bug (`bun init`, `bun info`, `bun upgrade` misread args under the preload); fixes in 5b93ea28 and 349f0b6e.

## Evidence
Session 77d6ff05 (2026-10-29). The terms were cited in the reply with "This is not legal advice"; ToS risk "low in my reading". The assistant also said the user's employer may have its own rules and it could not check them. The Bun sources were read to confirm the argument-parsing bug before the fixes. The preload was tested on macOS after install; Bun was not installed. The 15-20% figure comes only from the gist.
