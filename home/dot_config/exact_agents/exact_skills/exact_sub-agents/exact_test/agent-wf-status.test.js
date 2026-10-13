'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawn, spawnSync } = require('node:child_process');
const test = require('node:test');

const scratch = path.join(process.env.XDG_CACHE_HOME || path.join(os.homedir(), '.cache'), 'agents', 'scratch', 'agent-wf-status-tests');
test.after(() => fs.rmSync(scratch, { recursive: true, force: true }));

const cli = path.resolve(__dirname, '../../../../..', 'private_dot_local/bin/executable_agent-wf-status');

function workflowDir(events) {
  fs.mkdirSync(scratch, { recursive: true });
  const dir = fs.mkdtempSync(path.join(scratch, 'wf-'));
  fs.writeFileSync(path.join(dir, 'journal.jsonl'), events.map((e) => JSON.stringify(e)).join('\n') + '\n');
  return dir;
}

function run(args, timeout) {
  return spawnSync(process.execPath, [cli, ...args], { encoding: 'utf8', timeout });
}

const events = [
  { type: 'launched' },
  { type: 'started', key: 'a', agentId: 'x1', label: 'review:a', phase: 'Review' },
  { type: 'started', key: 'b', agentId: 'x2', label: 'review:b', phase: 'Review' },
  { type: 'result', key: 'a', agentId: 'x1', result: { big: 'x'.repeat(50000) } },
  { type: 'started', key: 'c', agentId: 'x3', label: 'verify:c', phase: 'Verify' },
  { type: 'started', key: 'd', agentId: 'x4', label: 'verify:d', phase: 'Verify' },
  { type: 'started', key: 'e', agentId: 'x5', label: 'verify:e', phase: 'Verify' },
];

test('prints a bounded snapshot without agent results', () => {
  const dir = workflowDir(events);
  const out = run([dir]);
  assert.equal(out.status, 0, out.stderr);
  const lines = out.stdout.trim().split('\n');
  assert.equal(lines.length, 2);
  assert.match(lines[0], /^running · phase Verify · 1\/5 agents done · last event under 1m ago$/);
  assert.equal(lines[1], 'active: review:b, verify:c, verify:d, +1 more');
  assert.ok(out.stdout.length < 300);
});

test('accepts the journal path and reports idle agents', () => {
  const dir = workflowDir([
    { type: 'started', key: 'a', label: 'one', phase: 'Only' },
    { type: 'result', key: 'a', result: {} },
  ]);
  fs.appendFileSync(path.join(dir, 'journal.jsonl'), '{"type":"started","key":"tru');
  const out = run([path.join(dir, 'journal.jsonl')]);
  assert.equal(out.status, 0, out.stderr);
  assert.equal(out.stdout.trim().split('\n').length, 1);
  assert.match(out.stdout, /^agents idle · phase Only · 1\/1 agents done/);
});

test('follow mode prints the current state first', () => {
  const dir = workflowDir(events);
  const out = run([dir, '--follow', '--every', '5'], 1500);
  assert.match(out.stdout, /^running · phase Verify · 1\/5 agents done/);
});

test('follow mode prints each new phase once', async () => {
  const dir = workflowDir([{ type: 'launched' }]);
  const journal = path.join(dir, 'journal.jsonl');
  const child = spawn(process.execPath, [cli, dir, '--follow'], { stdio: ['ignore', 'pipe', 'pipe'] });
  let out = '';
  const firstLine = new Promise((resolve) => child.stdout.once('data', resolve));
  child.stdout.on('data', (chunk) => { out += chunk; });
  await firstLine;
  const add = (events) => fs.appendFileSync(journal, events.map((e) => JSON.stringify(e)).join('\n') + '\n');
  add([{ type: 'started', key: 'a', phase: 'Review' }, { type: 'started', key: 'b', phase: 'Verify' }, { type: 'started', key: 'c', phase: 'Review' }]);
  await new Promise((resolve) => setTimeout(resolve, 6000));
  add([{ type: 'started', key: 'd', phase: 'Verify' }]);
  await new Promise((resolve) => setTimeout(resolve, 5500));
  const exited = child.exitCode;
  child.kill();
  assert.equal(exited, null);
  const lines = out.trim().split('\n');
  assert.match(lines[0], /^agents idle · no phase yet · 0\/0 agents done/);
  assert.deepEqual(lines.slice(1), ['phase Review started · 0/3 agents done', 'phase Verify started · 0/3 agents done']);
});

test('rejects bad arguments', () => {
  const dir = workflowDir(events);
  assert.equal(run([]).status, 2);
  assert.equal(run([path.join(dir, 'missing')]).status, 2);
  assert.equal(run([dir, '--every', '5']).status, 2);
  assert.equal(run([dir, '--follow', '--every', '0']).status, 2);
});
