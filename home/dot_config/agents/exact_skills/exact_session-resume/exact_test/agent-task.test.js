'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { execFileSync, spawnSync } = require('node:child_process');
const test = require('node:test');

const cli = path.resolve(__dirname, '../../../../..', 'private_dot_local/bin/executable_agent-task');

function fixture() {
  const scratch = path.join(process.env.XDG_CACHE_HOME || path.join(os.homedir(), '.cache'), 'agents', 'scratch', 'agent-task-tests');
  fs.mkdirSync(scratch, { recursive: true, mode: 0o700 });
  fs.chmodSync(scratch, 0o700);
  const root = fs.mkdtempSync(path.join(scratch, 'state-'));
  fs.chmodSync(root, 0o700);
  const home = path.join(root, 'home');
  fs.mkdirSync(home, { recursive: true });
  return { root, home, env: { ...process.env, HOME: home, XDG_STATE_HOME: root } };
}

function run(args, env) {
  return JSON.parse(execFileSync(process.execPath, [cli, ...args], { env, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }));
}

test('creates, checks, updates, and lists a private task', () => {
  const { root, env } = fixture();
  const created = run(['create', '--id', 'demo', '--objective', 'Finish work', '--authorization', 'user request', '--scope', 'local edits', '--parent-pr', '42', '--target-branch', 'main', '--task-boundary', 'session lookup'], env);
  assert.equal(created.revision, 1);
  assert.equal(created.parentPr, '42');
  assert.equal(created.targetBranch, 'main');
  assert.equal(created.taskBoundary, 'session lookup');
  assert.equal(fs.statSync(path.join(root, 'agents', 'tasks')).mode & 0o777, 0o700);
  assert.equal(fs.statSync(path.join(root, 'agents', 'tasks', 'demo.json')).mode & 0o777, 0o600);
  const checked = run(['check', 'demo', '--revision', '1', '--name', 'unit', '--result', 'pass', '--inputs', 'fixture'], env);
  assert.equal(checked.revision, 2);
  assert.equal(checked.checks[0].inputs, 'fixture');
  const updated = run(['update', 'demo', '--revision', '2', '--correction', 'Use B', '--next-step', 'Ship', '--status', 'paused', '--parent-pr', '43', '--target-branch', 'release', '--task-boundary', 'follow-up'], env);
  assert.equal(updated.revision, 3);
  assert.equal(updated.corrections[0].text, 'Use B');
  assert.equal(updated.parentPr, '43');
  assert.equal(updated.targetBranch, 'release');
  assert.equal(updated.taskBoundary, 'follow-up');
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

test('indexes metadata IDs and searches human turns with bounded context', () => {
  const { root, env } = fixture();
  const source = path.join(root, 'history.jsonl');
  const entries = [
    { type: 'session_meta', payload: { id: 'codex-session' } },
    { type: 'response_item', payload: { type: 'message', role: 'developer', content: [{ type: 'input_text', text: 'needle injected AGENTS' }] } },
    { type: 'response_item', payload: { type: 'function_call_output', output: 'needle tool output' } },
    { type: 'response_item', payload: { type: 'message', role: 'user', content: [{ type: 'input_text', text: '# AGENTS.md instructions\nneedle injected' }] } },
    { type: 'response_item', payload: { type: 'message', role: 'user', content: [{ type: 'input_text', text: 'needle codex request' }] } },
    { type: 'response_item', payload: { type: 'message', role: 'assistant', content: [{ type: 'output_text', text: 'codex reply' }] } },
    { type: 'user', isMeta: true, sessionId: 'ignored', message: { role: 'user', content: 'needle injected skill' } },
    { type: 'user', sessionId: 'claude-user', message: { role: 'user', content: [{ type: 'text', text: 'needle claude request' }] } },
    { type: 'assistant', sessionId: 'claude-user', message: { role: 'assistant', content: [{ type: 'text', text: 'claude reply' }, { type: 'tool_use', name: 'ignored' }] } },
  ];
  fs.writeFileSync(source, `${entries.map(JSON.stringify).join('\n')}\n`);
  const results = run(['search', '--query', 'needle', '--file', source, '--limit', '3'], env);
  assert.equal(results.length, 2);
  assert.deepEqual(results.map((result) => result.text), ['needle claude request', 'needle codex request']);
  assert.equal(results[1].sessionId, 'codex-session');
  assert.deepEqual(results[1].context.map((turn) => turn.role), ['user', 'assistant']);
  assert.equal(run(['resolve', '--session', 'codex-session', '--file', source], env).sources[0], source);
  const excessive = spawnSync(process.execPath, [cli, 'search', '--query', 'needle', '--file', source, '--limit', '101'], { env, encoding: 'utf8' });
  assert.notEqual(excessive.status, 0);
  assert.match(excessive.stderr, /between 1 and 100/);
  fs.rmSync(root, { recursive: true });
});

test('discovers old Claude history, archive, and alternate profiles', () => {
  const { root, home, env } = fixture();
  const files = [
    path.join(home, '.claude', 'history.jsonl'),
    path.join(home, '.claude', 'archives', 'old.jsonl'),
    path.join(home, '.claude-work', 'projects', 'team', 'session.jsonl'),
  ];
  for (const [index, file] of files.entries()) {
    fs.mkdirSync(path.dirname(file), { recursive: true });
    const entry = index === 0
      ? { display: `archive needle ${index}`, sessionId: `claude-${index}` }
      : { type: 'user', sessionId: `claude-${index}`, message: { role: 'user', content: `archive needle ${index}` } };
    fs.writeFileSync(file, `${JSON.stringify(entry)}\n`);
  }
  const results = run(['search', '--query', 'archive needle'], env);
  assert.deepEqual(new Set(results.map((result) => result.sessionId)), new Set(['claude-0', 'claude-1', 'claude-2']));
  fs.rmSync(root, { recursive: true });
});

test('filters injected and inherited duplicate events from index counts', () => {
  const { root, env } = fixture();
  const first = path.join(root, 'first.jsonl');
  const second = path.join(root, 'second.jsonl');
  const duplicate = { type: 'user', sessionId: 'shared', timestamp: 1_767_225_600, message: { role: 'user', content: 'human needle' } };
  const transcriptDuplicate = { ...duplicate, timestamp: '2026-01-01T00:00:00.000Z' };
  fs.writeFileSync(first, `${JSON.stringify(duplicate)}\n${JSON.stringify({ type: 'user', isMeta: true, sessionId: 'shared', message: { role: 'user', content: 'meta needle' } })}\n`);
  fs.writeFileSync(second, `${JSON.stringify(transcriptDuplicate)}\n`);
  run(['index', '--file', first], env);
  const stats = run(['index', '--file', second], env);
  assert.equal(stats.humanTurns, 1);
  const results = run(['search', '--query', 'needle', '--file', second], env);
  assert.equal(results.length, 1);
  assert.deepEqual(new Set(results[0].sources), new Set([first, second]));
  fs.rmSync(root, { recursive: true });
});

test('incrementally handles append, truncation, malformed lines, and private modes', () => {
  const { root, env } = fixture();
  const source = path.join(root, 'changing.jsonl');
  fs.writeFileSync(source, `${JSON.stringify({ type: 'user', sessionId: 'one', message: { role: 'user', content: 'first needle' } })}\n{bad}\n`);
  let stats = run(['index', '--file', source], env);
  assert.equal(stats.malformedLines, 1);
  fs.appendFileSync(source, `${JSON.stringify({ type: 'user', sessionId: 'one', message: { role: 'user', content: 'second needle' } })}\n`);
  assert.equal(run(['search', '--query', 'needle', '--file', source], env).length, 2);
  fs.writeFileSync(source, `${JSON.stringify({ type: 'user', sessionId: 'two', message: { role: 'user', content: `replacement needle ${'x'.repeat(300)}` } })}\n`);
  const replaced = run(['search', '--query', 'needle', '--file', source], env);
  assert.deepEqual(replaced.map((result) => result.sessionId), ['two']);
  const indexFile = path.join(root, 'agents', 'tasks', 'session-index', 'index.json');
  assert.equal(fs.statSync(path.dirname(indexFile)).mode & 0o777, 0o700);
  assert.equal(fs.statSync(indexFile).mode & 0o777, 0o600);
  stats = run(['index', '--file', source], env);
  assert.equal(stats.indexedTurns, 1);
  fs.rmSync(root, { recursive: true });
});

test('removes deleted and rotated source contributions without stale provenance', () => {
  const { root, home, env } = fixture();
  const directory = path.join(home, '.codex', 'sessions');
  fs.mkdirSync(directory, { recursive: true });
  const first = path.join(directory, 'first.jsonl');
  const second = path.join(directory, 'second.jsonl');
  const entry = { type: 'user', sessionId: 'shared', timestamp: 1_700_000_000, message: { role: 'user', content: 'shared needle' } };
  fs.writeFileSync(first, `${JSON.stringify(entry)}\n`);
  fs.writeFileSync(second, `${JSON.stringify(entry)}\n`);
  let result = run(['search', '--query', 'shared needle'], env)[0];
  assert.deepEqual(new Set(result.sources), new Set([first, second]));
  fs.rmSync(second);
  fs.renameSync(first, second);
  fs.writeFileSync(first, `${JSON.stringify({ ...entry, message: { role: 'user', content: 'replacement text' } })}\n`);
  result = run(['search', '--query', 'shared needle'], env)[0];
  assert.deepEqual(result.sources, [second]);
  fs.rmSync(root, { recursive: true });
});

test('detects same-size rewrites outside the prefix', () => {
  const { root, env } = fixture();
  const source = path.join(root, 'same-size.jsonl');
  const makeEntry = (word) => ({ type: 'user', sessionId: 'rewrite', message: { role: 'user', content: `${'p'.repeat(5_000)} ${word}` } });
  fs.writeFileSync(source, `${JSON.stringify(makeEntry('alpha'))}\n`);
  assert.equal(run(['search', '--query', 'alpha', '--file', source], env).length, 1);
  fs.writeFileSync(source, `${JSON.stringify(makeEntry('bravo'))}\n`);
  const future = new Date(Date.now() + 2_000);
  fs.utimesSync(source, future, future);
  assert.equal(run(['search', '--query', 'alpha', '--file', source], env).length, 0);
  assert.equal(run(['search', '--query', 'bravo', '--file', source], env).length, 1);
  fs.rmSync(root, { recursive: true });
});

test('prioritizes an exact session filename beyond a discovery cap', () => {
  const { root, home, env } = fixture();
  const directory = path.join(home, '.codex', 'sessions');
  fs.mkdirSync(directory, { recursive: true });
  for (let index = 0; index < 4; index += 1) {
    fs.writeFileSync(path.join(directory, `a-${index}.jsonl`), `${JSON.stringify({ type: 'user', sessionId: `other-${index}`, message: { role: 'user', content: 'other' } })}\n`);
  }
  const sessionId = 'target-session';
  const target = path.join(directory, 'z-hidden.jsonl');
  fs.writeFileSync(target, `${JSON.stringify({ type: 'session_meta', payload: { id: sessionId } })}\n${JSON.stringify({ type: 'response_item', payload: { type: 'message', role: 'user', content: [{ type: 'input_text', text: 'target request' }] } })}\n`);
  const resolved = run(['resolve', '--session', sessionId, '--max-files', '1'], env);
  assert.deepEqual(resolved.sources, [target]);
  assert.equal(resolved.coverage.scanLimitReached, true);
  fs.rmSync(root, { recursive: true });
});

test('reports coverage for zero search results', () => {
  const { root, env } = fixture();
  const result = spawnSync(process.execPath, [cli, 'search', '--query', 'absent'], { env, encoding: 'utf8' });
  assert.equal(result.status, 0);
  assert.deepEqual(JSON.parse(result.stdout), []);
  assert.equal(typeof JSON.parse(result.stderr).coverage.discovered, 'number');
  fs.rmSync(root, { recursive: true });
});

test('excludes inherited fork turns from human effort but resolves them', () => {
  const { root, env } = fixture();
  const source = path.join(root, 'fork.jsonl');
  fs.writeFileSync(source, `${JSON.stringify({ type: 'session_meta', payload: { id: 'fork-id', forked_from_id: 'parent-id', subagent_history_start_ordinal: 2 } })}\n${JSON.stringify({ ordinal: 1, type: 'response_item', payload: { type: 'message', role: 'user', content: [{ type: 'input_text', text: 'inherited request' }] } })}\n${JSON.stringify({ ordinal: 2, type: 'response_item', payload: { type: 'message', role: 'user', content: [{ type: 'input_text', text: 'new fork request' }] } })}\n`);
  const stats = run(['index', '--file', source], env);
  assert.equal(stats.humanTurns, 1);
  assert.equal(stats.inheritedTurns, 1);
  assert.equal(run(['resolve', '--session', 'fork-id', '--file', source], env).turns, 2);
  assert.equal(run(['search', '--query', 'inherited', '--file', source], env).length, 0);
  const explicit = run(['search', '--query', 'inherited', '--session', 'fork-id'], env);
  assert.equal(explicit.length, 1);
  assert.equal(explicit[0].inherited, true);
  fs.rmSync(root, { recursive: true });
});

test('advances through an oversized line under an explicit byte budget', () => {
  const { root, env } = fixture();
  const source = path.join(root, 'oversized.jsonl');
  fs.writeFileSync(source, `${JSON.stringify({ type: 'user', sessionId: 'large', message: { role: 'user', content: 'x'.repeat(1_100_000) } })}\n${JSON.stringify({ type: 'user', sessionId: 'after', message: { role: 'user', content: 'after needle' } })}\n`);
  let stats = run(['index', '--file', source, '--byte-limit', '600000'], env);
  assert.equal(stats.byteLimitReached, true);
  stats = run(['index', '--file', source, '--byte-limit', '600000'], env);
  assert.equal(stats.oversizedLines, 1);
  assert.equal(run(['search', '--query', 'after needle', '--file', source], env).length, 1);
  fs.rmSync(root, { recursive: true });
});

test('--help works', () => {
  const { root, env } = fixture();
  const result = spawnSync(process.execPath, [cli, '--help'], { env, encoding: 'utf8' });
  assert.equal(result.status, 0);
  assert.match(result.stdout, /resolve/);
  fs.rmSync(root, { recursive: true });
});

test('refuses a symbolic-link session index directory', () => {
  const { root, env } = fixture();
  const tasks = path.join(root, 'agents', 'tasks');
  const target = path.join(root, 'index-target');
  fs.mkdirSync(tasks, { recursive: true });
  fs.mkdirSync(target);
  fs.symlinkSync(target, path.join(tasks, 'session-index'));
  const result = spawnSync(process.execPath, [cli, 'index'], { env, encoding: 'utf8' });
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /must not be a symbolic link/);
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

test('valid EOF records remain visible and partial UTF-8 appends do not duplicate them', t => {
  const { root, env } = fixture();
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const source = path.join(root, 'eof.jsonl');
  const record = text => JSON.stringify({ type: 'user', sessionId: 'eof', message: { role: 'user', content: text } });
  fs.writeFileSync(source, record('needle café'));
  assert.equal(run(['search', '--query', 'needle', '--file', source], env).length, 1);
  assert.equal(run(['index', '--file', source], env).scannedBytes, 0);
  fs.appendFileSync(source, '\n' + record('needle second').slice(0, -2));
  assert.equal(run(['search', '--query', 'needle', '--file', source], env).length, 1);
  fs.appendFileSync(source, '}}');
  assert.equal(run(['search', '--query', 'needle', '--file', source], env).length, 2);
  fs.writeFileSync(source, record('needle café') + '\n' + record('needle second'));
  const complete = run(['search', '--query', 'needle', '--file', source], env);
  assert.equal(complete.length, 2);
  assert.equal(complete[0].offset, Buffer.byteLength(record('needle café') + '\n'));
  fs.appendFileSync(source, '\n');
  assert.equal(run(['search', '--query', 'needle', '--file', source], env).length, 2);
});

test('deleting one duplicate removes only its provenance', t => {
  const { root, home, env } = fixture();
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const directory = path.join(home, '.claude/projects/test');
  fs.mkdirSync(directory, { recursive: true });
  const a = path.join(directory, 'a.jsonl');
  const b = path.join(directory, 'b.jsonl');
  const row = JSON.stringify({ uuid: 'shared', type: 'user', sessionId: 'dedup', message: { role: 'user', content: 'needle duplicate' } }) + '\n';
  fs.writeFileSync(a, row); fs.writeFileSync(b, row);
  assert.equal(run(['search', '--query', 'needle'], env)[0].sources.length, 2);
  fs.unlinkSync(b);
  assert.deepEqual(run(['search', '--query', 'needle'], env)[0].sources, [a]);
});

test('a growing rewrite near the old tail rebuilds the source', t => {
  const { root, env } = fixture();
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const source = path.join(root, 'rewrite.jsonl');
  const prelude = JSON.stringify({ type: 'meta', padding: 'x'.repeat(5000) }) + '\n';
  const row = text => JSON.stringify({ type: 'user', sessionId: 'rewrite', message: { role: 'user', content: text } }) + '\n';
  fs.writeFileSync(source, prelude + row('old needle'));
  run(['index', '--file', source], env);
  fs.writeFileSync(source, prelude + row('replacement needle that is longer'));
  assert.deepEqual(run(['search', '--query', 'needle', '--file', source], env).map(item => item.text), ['replacement needle that is longer']);
  assert.equal(run(['index', '--rebuild', '--file', source], env).humanTurns, 1);
});

test('history duplicates use ordered transcript context and show the matched text', t => {
  const { root, home, env } = fixture();
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const directory = path.join(home, '.claude/projects/test');
  fs.mkdirSync(directory, { recursive: true });
  const text = 'x'.repeat(700) + 'needle prototype';
  fs.writeFileSync(path.join(home, '.claude/history.jsonl'), JSON.stringify({ display: text, sessionId: 'context', timestamp: 1000 }) + '\n');
  const transcript = path.join(directory, 'context.jsonl');
  fs.writeFileSync(transcript, [
    { type: 'assistant', sessionId: 'context', timestamp: 999, message: { role: 'assistant', content: 'before response' } },
    { type: 'user', sessionId: 'context', timestamp: 1000, message: { role: 'user', content: text } },
    { type: 'assistant', sessionId: 'context', timestamp: 1001, message: { role: 'assistant', content: 'after response' } },
  ].map(JSON.stringify).join('\n') + '\n');
  const result = run(['search', '--query', 'needle'], env)[0];
  assert.equal(result.source, transcript);
  assert.match(result.text, /needle prototype/);
  assert.deepEqual(result.context.map(item => item.role), ['assistant', 'user', 'assistant']);
});
