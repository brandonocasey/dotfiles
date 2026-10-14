#!/bin/sh
# SessionStart hook (resume|fork): warns before the first prompt when the
# prompt cache has expired, so a large context can be compacted or dropped
# before it is re-cached at full write price. Contexts under 100k tokens stay
# quiet; their rewrite is cheap.
jq -c 'select(.prompt_cache_likely_expired == true and (.context_tokens // 0) >= 100000)
  | {systemMessage: ("Cold cache: idle \((.seconds_since_last_response // 0) / 3600 * 10 | floor / 10)h, "
      + "\((.context_tokens // 0) / 1000 | floor)k tokens, first prompt re-caches for ~$"
      + "\((.estimated_cache_write_usd // 0) * 100 | round / 100). Consider /compact or a fresh session.")}' 2>/dev/null
exit 0
