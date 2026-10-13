# Release a hive package

Read when asked to release a hive package (npm) through Jenkins.

- Job: `hive-jwp-releaser`, at `/job/hive-jwp-releaser` or
  `/view/hive-gitlab/job/hive-jwp-releaser`. Ignore the similar
  `jenkins-hive-jwp-releaser`.
- Parameters, sent with `buildWithParameters 'K=v&K2=v2'`:
  - `JWP_RELEASER_NPM_VERSION`: the version to publish, for example `1.6.11-jwp.1`.
  - `JWP_RELEASER_DIRECTORY`: the package path, for example `packages/hlsjs-jwp`.
  - `JWP_RELEASER_DRY_RUN`: `true` for a dry run.
  - `JWP_RELEASER_CUSTOM_PARAMS`: optional, for example `PLAYER_VERSION:8.51.11`.
- Read the current parameter list first:
  `GET /job/hive-jwp-releaser/api/json?tree=property[parameterDefinitions[name,defaultParameterValue[value]]]`.
- Order:
  1. Confirm the MR is merged and the version is not already published.
  2. Start a dry run (`JWP_RELEASER_DRY_RUN=true`) and read its console log.
  3. Start the real build with the same parameters, minus the dry-run flag.
  4. Confirm the build number from `lastBuild` parameters, then wait for `building:false`.
  5. Check `npm view <pkg> dist-tags --prefer-online` on both registries
     (`https://npm-registry.longtailvideo.com/` and the GitLab package registry).
     Registry metadata can lag; recheck after about 30 s.
- Each start needs approval unless the user asked for that release.
- Follow-up tickets and fix versions: [mr-ticket](../../mr-ticket/SKILL.md).
