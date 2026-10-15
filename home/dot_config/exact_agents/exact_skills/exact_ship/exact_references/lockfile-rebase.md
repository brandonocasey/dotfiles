# Lockfile conflicts in a long rebase

1. `git rebase --abort`.
2. Merge `origin/<base>` into the branch, or squash the branch to one commit
   first, so the lockfile conflict happens once.
3. Resolve it with the base's lockfile, then run `npm install --package-lock-only`
   once (use the repo's package manager equivalent) and commit the result.
4. Push per `ship` step 2: a squashed branch needs its
   `--force-with-lease --force-if-includes` push.

Do not re-apply each commit's lockfile delta by hand.
