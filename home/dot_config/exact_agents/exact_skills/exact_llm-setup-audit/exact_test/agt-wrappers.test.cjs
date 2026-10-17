'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const test = require('node:test');

// Use the chezmoi source wrappers; fall back to the installed ones outside the source tree.
const sourceBin = path.resolve(__dirname, '../../../../../private_dot_local/bin');
const wrapper = (name) => {
  const source = path.join(sourceBin, `executable_${name}`);
  return fs.existsSync(source) ? source : path.join(os.homedir(), '.local/bin', name);
};

function sandbox({ agtSubcommands }) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'agt-wrappers-'));
  const bin = path.join(root, 'bin');
  const legacy = path.join(root, 'legacy');
  fs.mkdirSync(bin);
  fs.mkdirSync(legacy);
  if (agtSubcommands) {
    // Fake agt: `<sub> --help` succeeds only for known subcommands; otherwise print argv, one per line.
    fs.writeFileSync(path.join(bin, 'agt'), [
      '#!/bin/sh',
      `case " ${agtSubcommands.join(' ')} " in *" $1 "*) ;; *) exit 2;; esac`,
      '[ "$2" = --help ] && exit 0',
      'for a in "$@"; do printf "agt:%s\\n" "$a"; done',
      '',
    ].join('\n'), { mode: 0o755 });
  }
  for (const name of ['agent-watch', 'gl-ci', 'agent-task']) {
    fs.writeFileSync(path.join(legacy, `${name}.legacy`),
      '#!/bin/sh\nfor a in "$@"; do printf "legacy:%s\\n" "$a"; done\n', { mode: 0o755 });
  }
  const env = { PATH: `${bin}:/usr/bin:/bin`, HOME: root, AGT_LEGACY_DIR: legacy };
  return { root, env };
}

const run = (name, args, env) => spawnSync('/bin/sh', [wrapper(name), ...args], { env, encoding: 'utf8' });

test('agent-review prepends review and keeps arguments with spaces intact', () => {
  const { env } = sandbox({ agtSubcommands: ['review'] });
  const result = run('agent-review', ['publish', '--reply', 'two words', ''], env);
  assert.equal(result.status, 0);
  assert.equal(result.stdout, 'agt:review\nagt:publish\nagt:--reply\nagt:two words\nagt:\n');
  assert.equal(result.stderr, '');
});

test('agent-review --version and -V ask agt for its version', () => {
  const { env } = sandbox({ agtSubcommands: ['review', '--version'] });
  for (const flag of ['--version', '-V']) {
    const result = run('agent-review', [flag], env);
    assert.equal(result.status, 0);
    assert.equal(result.stdout, 'agt:--version\n');
  }
});

test('agent-review exits 127 with an install hint when agt is missing', () => {
  const { env } = sandbox({ agtSubcommands: null });
  const result = run('agent-review', ['status'], env);
  assert.equal(result.status, 127);
  assert.equal(result.stderr, 'agent-review: agt not found; run: mise install github:brandonocasey/agt\n');
  assert.equal(result.stdout, '');
});

for (const [name, sub] of [['agent-watch', 'watch'], ['gl-ci', 'ci'], ['agent-task', 'task']]) {
  test(`${name} uses agt ${sub} when agt has the subcommand`, () => {
    const { env } = sandbox({ agtSubcommands: [sub] });
    const result = run(name, ['one', 'two words'], env);
    assert.equal(result.status, 0);
    assert.equal(result.stdout, `agt:${sub}\nagt:one\nagt:two words\n`);
  });

  test(`${name} falls back to the legacy script when agt lacks ${sub}`, () => {
    const { env } = sandbox({ agtSubcommands: ['review'] });
    const result = run(name, ['one', 'two words'], env);
    assert.equal(result.status, 0);
    assert.equal(result.stdout, 'legacy:one\nlegacy:two words\n');
  });

  test(`${name} falls back to the legacy script when agt is missing`, () => {
    const { env } = sandbox({ agtSubcommands: null });
    const result = run(name, ['--help'], env);
    assert.equal(result.status, 0);
    assert.equal(result.stdout, 'legacy:--help\n');
  });
}
