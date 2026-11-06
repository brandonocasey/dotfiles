# Prompt-cache TTL, credential-read denies, no blanket Bash/Task allows, cold-cache hook

- Status (2026-11-06): current. `"promptCacheTtl": "1h"` is in `home/.chezmoitemplates/claude-settings-modify.sh`; the `Read(~/.netrc)`, `Read(~/.ssh/**)`, `Read(~/.config/glab-cli/**)`, `Read(~/.config/gh/hosts.yml)` and `Read(~/.aws/**)` denies are there; no blanket `"Bash"` or `"Task"` allow; `home/dot_claude/hooks/executable_cold-cache-warn.sh` runs on SessionStart `resume|fork`; the statusline reads `prompt_cache`. The auto-mode environment labels were later condensed to one line (see History).
- Topic: Settings, permissions and security
- Related: [400k auto-compact window](2026-10-14-auto-compact-400k.md), [Setup audit: sandbox and auto mode](2026-10-13-setup-audit-sandbox-auto-mode.md), [Statusline links, ports and agent rows](2026-10-16-statusline-links-ports.md)

## Change
One session turned a list of Claude Code features the user was not using into settings changes:
- `promptCacheTtl: "1h"` to force the 1-hour prompt cache.
- `Read` denies for credential files (~/.netrc, ~/.ssh, glab and gh config, ~/.aws). Reason in the session: Read is never checked by auto mode, so nothing blocked these files.
- Removed the blanket `Bash` and `Task` allows, so auto mode sees those calls.
- More auto-mode environment labels (organization, trusted internal domains, key internal services).
- A SessionStart hook (`resume|fork`) that warns when the cache has expired and context is 100k tokens or more: "Cold cache: idle Nh, Nk tokens, first prompt re-caches for ~$X. Consider /compact or a fresh session."
- Statusline shows prompt-cache expiry and drops the last-message time; it shows a cyan `cold` once the cache has expired.

The user declined items 1 and 2 (`autoCompactWindow` for Opus and a narrow WebFetch allow) with "dont do 1/2. idlecompact in tandem with keepalive. do others".

## History
- 2026-10-14 — session 7e8db009: `/open-ended` "are there any claude code features im not using but should be". 5 rounds, 48 features found (all exist in 2.1.299, none in the user's config). The user asked for a more concise table, then picked the rows above.
- 2026-10-14 — commit `fe42308a dx(claude): force 1h cache, deny credential reads`: `promptCacheTtl`, Read denies, blanket `Bash` and `Task` allows removed, auto-mode environment labels, and the SessionStart cold-cache hook with `executable_cold-cache-warn.sh`. The auto-mode blocked the assistant from removing the dead `Task` rule, so the user ran a script it provided.
- 2026-10-14 — commit `c2ea58e0 dx(statusline): show prompt cache expiry, drop last-message time`.
- 2026-10-14 — commit `5151ac26 dx(commit): inject git snapshot at skill load`: same session, but not part of this change (a commit skill change).
- 2026-10-14 to 10-15 — statusline follow-ups to the cache display: `2e31908d dx(claude): warn relative to auto-compact window`, `fbe4293c dx(statusline): track compaction point and cold cost`, `96253ff9 dx(claude): give cache ttl its own segment`.
- 2026-10-15 — `1cc6cc7d dx(claude): simplify auto-mode rules` merged the four environment labels from fe42308a into one "Organization: JW Player / Connatix. Trusted: ..." line; `2f1ff037 dx(claude): restore dropped auto-mode exceptions` restored four dropped auto-mode rules and the trusted-source wording after the user approved restoring them. Session 34dbf6d2 (2026-10-15, a review-comment session) made both commits.
- 2026-11-05 — commit `dab770cd dx(claude): turn on idle compaction setting`: `"idleCompaction": true` in the settings template. This follows the user's 10-14 answer to run idle compaction together with the keepalive hook.
- 2026-11-06 — status check against `claude-settings-modify.sh`: `promptCacheTtl`, the Read denies and the SessionStart hook are present; blanket `Bash`/`Task` allows are absent.

## Results
No measurement as an A/B test. What the session reported:
- The cache dropped to a 5-minute TTL partway through Oct 13 in that session, which left the keepalive hook doing nothing. After forcing `1h`, the session's latest cache writes were all 1h.
- Idle compaction: the assistant first found the keepalive pings at 45 minutes, so the 54-minute idle compaction would never run, and flagged it as a decision. The final answer was "Idle compaction already works with keepalive. The keepalive pings for up to 2h. Idle compaction then runs ~54 min after the last ping, if the context is over 200k. No change was needed." The setting itself was only added on 2026-11-05 (`dab770cd`).
- Cold-cache cost: a cold cache re-sends the whole context at the cache-write price (2x base input on the 1h TTL). Rough rule given: under about 150k tokens just continue, over about 300k compact or start fresh.
- An independent review of the config changes found 10 problems, all fixed; the main one was that the next `chezmoi apply` would have undone the live edits until the chezmoi sources got the same changes.
- Not tested: whether the cold-cache hook and the statusline `cold` flag fire correctly on a real cold resume. The assistant said "if the statusline shows `cold` while you're actively working, that's a bug in my segment".
No complaint, bug or revert of these settings was found in later sessions searched (searched commit history for `promptCacheTtl`, `Read(~/.netrc)`, `cold-cache-warn`).

## Sources
About 45 Claude Code doc pages fetched by sub-agents (settings, settings-reference, env-vars, prompt-caching, statusline, permission-modes, hooks, sub-agents and others) and the Claude Code CHANGELOG. Per-claim attribution was not kept, so no per-URL list can be given.

## Evidence
Claimed from docs plus binary inspection ("promptCacheTtl 1h ... Verified in binary", "Statusline prompt_cache field ... Verified in binary"); no quotes in the reply. Sub-agents fetched the doc pages and returned summaries. Session 7e8db009 (2026-10-14).
