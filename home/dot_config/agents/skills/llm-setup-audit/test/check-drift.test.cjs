'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { snapshot, compare, brokenReferences } = require('../scripts/check-drift.cjs');

const entry = overrides => ({ sourceHash: 'source', renderedHash: 'content',
  installedHash: 'content', matchesSource: true, missingReferences: [], ...overrides });
const host = files => ({ files });

test('source and installed drift are distinct, and no host failure looks clean', () => {
  const result = compare({
    local: host({ a: entry(), b: entry(), c: entry() }),
    remote: host({ a: entry({ sourceHash: 'old' }), b: entry({ installedHash: 'old', matchesSource: false }) }),
    offline: { error: 'SSH unavailable' },
  });
  assert.deepEqual(new Set(result.mismatches.map(item => item.kind)),
    new Set(['source_drift', 'installed_drift', 'host_drift', 'missing_source', 'host_error']));
});

test('host templates and exact exceptions cannot hide an installation or reference error', () => {
  const snapshots = {
    local: host({ a: entry({ template: true }), b: entry() }),
    remote: host({ a: entry({ template: true, installedHash: 'remote', renderedHash: 'remote' }),
      b: entry({ sourceHash: 'custom', installedHash: 'custom', missingReferences: ['missing.md'] }) }),
  };
  const exceptions = [{ path: 'b', hosts: { local: 'content', remote: 'custom' }, reason: 'Approved host rule' }];
  const result = compare(snapshots, exceptions);
  assert.equal(result.intentionalDifferences.length, 2);
  assert.deepEqual(result.mismatches.map(item => item.kind), ['missing_reference']);
  snapshots.remote.files.b.matchesSource = false;
  const stale = compare(snapshots, exceptions);
  assert.equal(stale.intentionalDifferences.length, 1);
  assert.ok(stale.mismatches.some(item => item.kind === 'installed_drift'));
  snapshots.remote.files.b.installedHash = 'new-unapproved';
  assert.ok(compare(snapshots, exceptions).mismatches.some(item => item.kind === 'source_drift'));
});

test('snapshot renders source, resolves links, and detects missing references', t => {
  const scratch = path.join(process.env.XDG_CACHE_HOME || path.join(os.homedir(), '.cache'), 'agents/scratch');
  fs.mkdirSync(scratch, { recursive: true });
  const root = fs.mkdtempSync(path.join(scratch, 'agent-drift-test-'));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const home = path.join(root, 'home');
  const source = path.join(root, 'source');
  const target = path.join(home, '.config/agents/example.md');
  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.mkdirSync(source);
  const sourceFile = path.join(source, 'example.md.tmpl');
  fs.writeFileSync(sourceFile, '{{ rendered }}');
  fs.writeFileSync(target, '[Missing](absent.md) [External](https://example.org)');
  const alias = path.join(home, '.config/agents/alias.md');
  fs.symlinkSync('example.md', alias);
  const linkSource = path.join(source, 'symlink_alias.md');
  fs.writeFileSync(linkSource, 'example.md');
  const managed = {
    '.config/agents/example.md': { absolute: target, sourceAbsolute: sourceFile },
    '.config/agents/alias.md': { absolute: alias, sourceAbsolute: linkSource },
  };
  const fake = path.join(root, 'chezmoi');
  fs.writeFileSync(fake, `#!${process.execPath}\nconst data=${JSON.stringify(managed)};\n` +
    `const args=process.argv.slice(2);\n` +
    `if(args[0]==='managed') console.log(JSON.stringify(data));\n` +
    `if(args[0]==='source-path') console.log(${JSON.stringify(source)});\n` +
    `if(args[0]==='cat') process.stdout.write(args[1]===${JSON.stringify(alias)}?'example.md\\n':'expected rendered content');\n`, { mode: 0o700 });
  const result = snapshot({ home, chezmoi: fake, paths: ['.config/agents'] });
  assert.equal(result.files['.config/agents/example.md'].matchesSource, false);
  assert.equal(result.files['.config/agents/alias.md'].matchesSource, true);
  assert.equal(result.files['.config/agents/alias.md'].resolved, target);
  assert.deepEqual(result.files['.config/agents/example.md'].missingReferences, ['absent.md']);
  assert.deepEqual(brokenReferences(target, '[Self](#section)'), []);
  fs.rmSync(target);
  assert.match(snapshot({ home, chezmoi: fake }).files['.config/agents/alias.md'].error, /ENOENT/);
});
