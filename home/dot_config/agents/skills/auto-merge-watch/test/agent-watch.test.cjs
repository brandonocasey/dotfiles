const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { spawn, spawnSync } = require('node:child_process');
const test = require('node:test');

const skillDir = path.resolve(__dirname, '..');
const watcher = path.resolve(skillDir, '../../../../private_dot_local/bin/executable_agent-watch');
const fakeGh = path.join(__dirname, 'fixtures/fake-gh.cjs');
const { backoffDelay } = require(watcher);
const scratchRoot = process.env.AGENT_WATCH_TEST_ROOT;

if (!scratchRoot) {
  throw new Error('AGENT_WATCH_TEST_ROOT is required');
}

let sequence = 0;
function runScenario(responses, extraArgs = []) {
  sequence += 1;
  const directory = path.join(scratchRoot, `case-${process.pid}-${sequence}`);
  fs.mkdirSync(directory, { recursive: true });
  const scenario = path.join(directory, 'scenario.json');
  const state = path.join(directory, 'state');
  fs.writeFileSync(scenario, JSON.stringify(responses));
  const result = spawnSync(process.execPath, [
    watcher,
    '--target', 'owner/repo#42@abc123',
    '--interval-ms', '1',
    '--max-interval-ms', '2',
    '--deadline-seconds', '2',
    ...extraArgs,
  ], {
    encoding: 'utf8',
    env: {
      ...process.env,
      AGENT_WATCH_GH_BIN: fakeGh,
      AGENT_WATCH_FAKE_SCENARIO: scenario,
      AGENT_WATCH_FAKE_STATE: state,
    },
  });
  const events = result.stdout.trim().split('\n').filter(Boolean).map(JSON.parse);
  return { ...result, events };
}

const openView = JSON.stringify({
  number: 42,
  url: 'https://github.com/owner/repo/pull/42',
  state: 'OPEN',
  mergedAt: null,
  closed: false,
  headRefOid: 'abc123',
});
const pendingChecks = JSON.stringify([{
  name: 'test', state: 'IN_PROGRESS', bucket: 'pending', description: '',
  link: 'https://github.com/owner/repo/actions/runs/1', workflow: 'CI', event: 'pull_request',
}]);
const passingChecks = JSON.stringify([{
  name: 'test', state: 'SUCCESS', bucket: 'pass', description: '',
  link: 'https://github.com/owner/repo/actions/runs/1', workflow: 'CI', event: 'pull_request',
}]);

test('emits initial, changed, and final events once', () => {
  const result = runScenario([
    { includes: 'pr view 42', stdout: openView },
    { includes: 'pr checks 42', stdout: pendingChecks, code: 8 },
    { includes: 'pr view 42', stdout: openView },
    { includes: 'pr checks 42', stdout: passingChecks },
    { includes: 'pr view 42', stdout: openView },
  ]);
  assert.equal(result.status, 0, result.stderr);
  assert.deepEqual(result.events.map((event) => event.event), ['initial', 'change', 'final']);
  assert.equal(result.events[1].reason, 'required_checks_passed');
  assert.equal(result.events[2].reason, 'checks_complete');
  assert.equal(result.events[2].results[0].reason, 'required_checks_passed');
});

test('reports a head change without querying checks', () => {
  const changedView = JSON.stringify({
    number: 42, url: 'https://github.com/owner/repo/pull/42', state: 'OPEN',
    mergedAt: null, closed: false, headRefOid: 'def456',
  });
  const result = runScenario([{ includes: 'pr view 42', stdout: changedView }]);
  assert.equal(result.status, 2, result.stderr);
  assert.equal(result.events[0].reason, 'head_changed');
  assert.equal(result.events.at(-1).reason, 'action_required');
});

test('accepts failed-check JSON from gh exit status 1', () => {
  const failedChecks = JSON.stringify([{
    name: 'test', state: 'FAILURE', bucket: 'fail', description: 'failed',
    link: 'https://github.com/owner/repo/actions/runs/1', workflow: 'CI', event: 'pull_request',
  }]);
  const result = runScenario([
    { includes: 'pr view 42', stdout: openView },
    { includes: 'pr checks 42', stdout: failedChecks, code: 1 },
  ]);
  assert.equal(result.status, 2, result.stderr);
  assert.equal(result.events[0].reason, 'check_failed');
  assert.equal(result.events[0].checks[0].description, 'failed');
});

test('rechecks the head before reporting completed checks', () => {
  const changedView = JSON.stringify({
    number: 42, url: 'https://github.com/owner/repo/pull/42', state: 'OPEN',
    mergedAt: null, closed: false, headRefOid: 'def456',
  });
  const result = runScenario([
    { includes: 'pr view 42', stdout: openView },
    { includes: 'pr checks 42', stdout: passingChecks },
    { includes: 'pr view 42', stdout: changedView },
  ]);
  assert.equal(result.status, 2, result.stderr);
  assert.equal(result.events[0].reason, 'head_changed');
  assert.equal(result.events[0].expectedHead, 'abc123');
  assert.equal(result.events[0].observedHead, 'def456');
});

test('reports merged and closed pull requests without querying checks', async (context) => {
  for (const [name, fields, status, reason] of [
    ['merged', { state: 'MERGED', mergedAt: '2026-10-02T12:00:00Z', closed: true }, 0, 'merged'],
    ['closed', { state: 'CLOSED', mergedAt: null, closed: true }, 2, 'closed'],
  ]) {
    await context.test(name, () => {
      const view = JSON.stringify({
        number: 42,
        url: 'https://github.com/owner/repo/pull/42',
        headRefOid: 'abc123',
        ...fields,
      });
      const result = runScenario([{ includes: 'pr view 42', stdout: view }]);
      assert.equal(result.status, status, result.stderr);
      assert.equal(result.events[0].reason, reason);
    });
  }
});

test('reports no checks, unknown checks, failures, and cancellation', async (context) => {
  for (const [name, checks, reason] of [
    ['no checks', [], 'no_required_checks'],
    ['unknown check', [{ name: 'test', state: 'UNKNOWN', bucket: 'unknown' }], 'unknown_check_state'],
    ['failed check', [{ name: 'test', state: 'FAILURE', bucket: 'fail' }], 'check_failed'],
    ['cancelled check', [{ name: 'test', state: 'CANCELLED', bucket: 'cancel' }], 'check_cancelled'],
  ]) {
    await context.test(name, () => {
      const result = runScenario([
        { includes: 'pr view 42', stdout: openView },
        { includes: 'pr checks 42', stdout: JSON.stringify(checks) },
      ]);
      assert.equal(result.status, 2, result.stderr);
      assert.equal(result.events[0].reason, reason);
    });
  }
});

test('preserves authentication, permission, and invalid response output', async (context) => {
  for (const [name, detail, reason, stdout = ''] of [
    ['authentication', 'authentication required: run gh auth login', 'authentication_error'],
    ['permission', 'HTTP 403: Resource not accessible', 'permission_error'],
    ['invalid response', 'warning from proxy', 'invalid_response', '{broken'],
  ]) {
    await context.test(name, () => {
      const result = runScenario([{
        includes: 'pr view 42', stderr: detail, stdout, code: stdout ? 0 : 1,
      }]);
      assert.equal(result.status, 2, result.stderr);
      assert.equal(result.events[0].reason, reason);
      assert.match(result.events[0].detail, new RegExp(detail.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')));
    });
  }
  await context.test('check permission', () => {
    const detail = 'HTTP 403: Resource not accessible';
    const result = runScenario([
      { includes: 'pr view 42', stdout: openView },
      { includes: 'pr checks 42', stderr: detail, code: 1 },
    ]);
    assert.equal(result.status, 2, result.stderr);
    assert.equal(result.events[0].reason, 'permission_error');
    assert.equal(result.events[0].detail, detail);
  });
});

test('reports missing pull request and check data', async (context) => {
  await context.test('missing pull request data', () => {
    const result = runScenario([{
      includes: 'pr view 42',
      stdout: JSON.stringify({ state: 'OPEN', url: 'https://github.com/owner/repo/pull/42' }),
    }]);
    assert.equal(result.status, 2, result.stderr);
    assert.equal(result.events[0].reason, 'missing_pull_request_data');
  });
  await context.test('missing check data', () => {
    const result = runScenario([
      { includes: 'pr view 42', stdout: openView },
      { includes: 'pr checks 42', stdout: JSON.stringify([{ name: 'test', state: 'SUCCESS' }]) },
    ]);
    assert.equal(result.status, 2, result.stderr);
    assert.equal(result.events[0].reason, 'missing_check_data');
  });
});

test('uses bounded exponential backoff', () => {
  assert.deepEqual(
    [0, 1, 2, 3, 20].map((attempt) => backoffDelay(attempt, 10, 35)),
    [10, 20, 35, 35, 35],
  );
});

test('stops at a finite deadline', () => {
  const result = runScenario([
    { includes: 'pr view 42', stdout: openView },
    { includes: 'pr checks 42', stdout: pendingChecks, code: 8 },
  ], ['--interval-ms', '2000', '--max-interval-ms', '2000', '--deadline-seconds', '1']);
  assert.equal(result.status, 124, result.stderr);
  assert.deepEqual(result.events.map((event) => event.event), ['initial', 'final']);
  assert.equal(result.events.at(-1).reason, 'deadline_exceeded');
});

test('recomputes the deadline before each gh invocation', () => {
  const startedAt = Date.now();
  const result = runScenario([
    { includes: 'pr view 42', stdout: openView, delayMs: 700 },
    { includes: 'pr checks 42', stdout: pendingChecks, code: 8, delayMs: 700 },
  ], ['--interval-ms', '2000', '--max-interval-ms', '2000', '--deadline-seconds', '1']);
  const elapsedMs = Date.now() - startedAt;
  assert.equal(result.status, 124, result.stderr);
  assert.equal(result.events.at(-1).reason, 'deadline_exceeded');
  assert.ok(elapsedMs < 1300, `watcher exceeded deadline by ${elapsedMs - 1000}ms`);
});

test('emits one final event when terminated', async () => {
  sequence += 1;
  const directory = path.join(scratchRoot, `case-${process.pid}-${sequence}`);
  fs.mkdirSync(directory, { recursive: true });
  const scenario = path.join(directory, 'scenario.json');
  const state = path.join(directory, 'state');
  fs.writeFileSync(scenario, JSON.stringify([
    { includes: 'pr view 42', stdout: openView },
    { includes: 'pr checks 42', stdout: pendingChecks, code: 8 },
  ]));
  const child = spawn(process.execPath, [
    watcher, '--target', 'owner/repo#42@abc123', '--interval-ms', '5000',
    '--max-interval-ms', '5000', '--deadline-seconds', '30',
  ], {
    env: {
      ...process.env,
      AGENT_WATCH_GH_BIN: fakeGh,
      AGENT_WATCH_FAKE_SCENARIO: scenario,
      AGENT_WATCH_FAKE_STATE: state,
    },
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  let stdout = '';
  let stderr = '';
  let sentSignal = false;
  child.stdout.setEncoding('utf8');
  child.stderr.setEncoding('utf8');
  child.stdout.on('data', (data) => {
    stdout += data;
    if (!sentSignal && stdout.includes('"event":"initial"')) {
      sentSignal = true;
      child.kill('SIGTERM');
    }
  });
  child.stderr.on('data', (data) => { stderr += data; });
  const status = await new Promise((resolve) => child.once('exit', resolve));
  assert.equal(status, 143, stderr);
  const events = stdout.trim().split('\n').map(JSON.parse);
  assert.equal(events.filter((event) => event.event === 'final').length, 1);
  assert.equal(events.at(-1).reason, 'cancelled');
});
