'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { execFileSync, spawnSync } = require('node:child_process');
const test = require('node:test');

const cli = path.resolve(__dirname, '../../../../..', 'private_dot_local/bin/executable_agent-task');

function fixture() {
  const scratch = path.join(os.homedir(), '.cache', 'agents', 'scratch');
  fs.mkdirSync(scratch, { recursive: true });
  const root = fs.mkdtempSync(path.join(scratch, 'agent-efficiency-state-'));
  return { root, env: { ...process.env, XDG_STATE_HOME: root } };
}

function run(args, env) {
  return JSON.parse(execFileSync(process.execPath, [cli, ...args], { env, encoding: 'utf8' }));
}

test('creates, checks, updates, and lists a private task', () => {
  const { root, env } = fixture();
  const created = run(['create', '--id', 'demo', '--objective', 'Finish work', '--authorization', 'user request', '--scope', 'local edits'], env);
  assert.equal(created.revision, 1);
  assert.equal(fs.statSync(path.join(root, 'agents', 'tasks')).mode & 0o777, 0o700);
  assert.equal(fs.statSync(path.join(root, 'agents', 'tasks', 'demo.json')).mode & 0o777, 0o600);
  const checked = run(['check', 'demo', '--revision', '1', '--name', 'unit', '--result', 'pass', '--inputs', 'fixture'], env);
  assert.equal(checked.revision, 2);
  assert.equal(checked.checks[0].inputs, 'fixture');
  const updated = run(['update', 'demo', '--revision', '2', '--correction', 'Use B', '--next-step', 'Ship', '--status', 'paused'], env);
  assert.equal(updated.revision, 3);
  assert.equal(updated.corrections[0].text, 'Use B');
  assert.equal(run(['list'], env)[0].id, 'demo');
  fs.rmSync(root, { recursive: true });
});

test('rejects traversal and stale revisions', () => {
  const { root, env } = fixture();
  run(['create', '--id', 'demo', '--objective', 'Finish work'], env);
  const stale = spawnSync(process.execPath, [cli, 'update', 'demo', '--revision', '2', '--next-step', 'No'], { env, encoding: 'utf8' });
  assert.notEqual(stale.status, 0);
  assert.match(stale.stderr, /stale revision/);
  const retried = run(['update', 'demo', '--revision', '1', '--next-step', 'Yes'], env);
  assert.equal(retried.revision, 2);
  const duplicate = spawnSync(process.execPath, [cli, 'create', '--id', 'demo', '--objective', 'Again'], { env, encoding: 'utf8' });
  assert.notEqual(duplicate.status, 0);
  assert.match(duplicate.stderr, /already exists/);
  const afterDuplicate = run(['update', 'demo', '--revision', '2', '--next-step', 'Still works'], env);
  assert.equal(afterDuplicate.revision, 3);
  const traversal = spawnSync(process.execPath, [cli, 'show', '../demo'], { env, encoding: 'utf8' });
  assert.notEqual(traversal.status, 0);
  assert.match(traversal.stderr, /id must match/);
  fs.rmSync(root, { recursive: true });
});

test('search extracts user and assistant text from real transcript schemas', () => {
  const { root, env } = fixture();
  const source = path.join(root, 'history.jsonl');
  const entries = [
    { type: 'response_item', payload: { type: 'message', role: 'developer', content: [{ type: 'input_text', text: 'needle injected AGENTS' }] } },
    { type: 'response_item', payload: { type: 'function_call_output', output: 'needle tool output' } },
    { type: 'response_item', payload: { type: 'message', role: 'assistant', content: [{ type: 'output_text', text: 'needle codex reply' }] } },
    { type: 'user', isMeta: true, sessionId: 'ignored', message: { role: 'user', content: 'needle injected skill' } },
    { type: 'user', sessionId: 'claude-user', message: { role: 'user', content: [{ type: 'text', text: 'needle claude request' }] } },
    { type: 'assistant', sessionId: 'claude-assistant', message: { role: 'assistant', content: [{ type: 'text', text: 'needle claude reply' }, { type: 'tool_use', name: 'ignored' }] } },
  ];
  fs.writeFileSync(source, `${entries.map(JSON.stringify).join('\n')}\n`);
  const results = run(['search', '--query', 'needle', '--file', source, '--limit', '3'], env);
  assert.equal(results.length, 3);
  assert.deepEqual(results.map((result) => result.text), ['needle claude reply', 'needle claude request', 'needle codex reply']);
  assert.deepEqual(results.map((result) => result.role), ['assistant', 'user', 'assistant']);
  const excessive = spawnSync(process.execPath, [cli, 'search', '--query', 'needle', '--file', source, '--limit', '101'], { env, encoding: 'utf8' });
  assert.notEqual(excessive.status, 0);
  assert.match(excessive.stderr, /between 1 and 100/);
  fs.rmSync(root, { recursive: true });
});

test('refuses symbolic-link task records', () => {
  const { root, env } = fixture();
  const tasks = path.join(root, 'agents', 'tasks');
  fs.mkdirSync(tasks, { recursive: true });
  const target = path.join(root, 'target.json');
  fs.writeFileSync(target, JSON.stringify({ id: 'linked', revision: 1 }));
  fs.symlinkSync(target, path.join(tasks, 'linked.json'));
  const shown = spawnSync(process.execPath, [cli, 'show', 'linked'], { env, encoding: 'utf8' });
  assert.notEqual(shown.status, 0);
  assert.match(shown.stderr, /must not be a symbolic link/);
  fs.rmSync(root, { recursive: true });
});

test('rejects oversized persisted fields without changing or locking the task', () => {
  const { root, env } = fixture();
  const oversized = 'x'.repeat(16_385);
  const create = spawnSync(process.execPath, [cli, 'create', '--id', 'large-create', '--objective', 'Work', '--next-step', oversized], { env, encoding: 'utf8' });
  assert.notEqual(create.status, 0);
  assert.match(create.stderr, /next-step exceeds/);
  assert.equal(fs.existsSync(path.join(root, 'agents', 'tasks', 'large-create.json')), false);
  assert.equal(fs.existsSync(path.join(root, 'agents', 'tasks', '.large-create.lock')), false);

  run(['create', '--id', 'large-check', '--objective', 'Work'], env);
  for (const field of ['code-revision', 'inputs', 'environment']) {
    const checked = spawnSync(process.execPath, [cli, 'check', 'large-check', '--revision', '1', '--name', 'check', '--result', 'pass', `--${field}`, oversized], { env, encoding: 'utf8' });
    assert.notEqual(checked.status, 0);
    assert.match(checked.stderr, new RegExp(`${field} exceeds`));
    const unchanged = run(['show', 'large-check'], env);
    assert.equal(unchanged.revision, 1);
    assert.deepEqual(unchanged.checks, []);
    assert.equal(fs.existsSync(path.join(root, 'agents', 'tasks', '.large-check.lock')), false);
  }
  fs.rmSync(root, { recursive: true });
});
