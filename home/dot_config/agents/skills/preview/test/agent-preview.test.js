'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const http = require('node:http');
const os = require('node:os');
const path = require('node:path');
const { spawn, spawnSync } = require('node:child_process');
const { after, before, test } = require('node:test');

const helper = path.resolve(__dirname, '../../../../../private_dot_local/bin/executable_agent-preview');
const root = path.join(os.homedir(), '.cache', 'agents', 'scratch', 'agent-preview-tests', `${process.pid}`);
const stateDir = path.join(root, 'state');
const asset = path.join(root, 'choice.html');
const secondAsset = path.join(root, 'choice-b.html');
const replacement = path.join(root, 'replacement.html');
const config = path.join(root, 'config.json');
let child;
let port;
let token;
let serverErrors = '';

function run(args) {
  return spawnSync(process.execPath, [helper, ...args], { encoding: 'utf8' });
}

function availablePort() {
  return new Promise((resolve, reject) => {
    const server = http.createServer();
    server.once('error', reject);
    server.listen(0, '127.0.0.1', () => {
      const selected = server.address().port;
      server.close(error => error ? reject(error) : resolve(selected));
    });
  });
}

function startServer() {
  child = spawn(process.execPath, [helper, 'serve', '--config', config, '--state-dir', stateDir, '--port', String(port)], {
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  return new Promise((resolve, reject) => {
    let output = '';
    child.stderr.on('data', chunk => { output += chunk; serverErrors += chunk; });
    child.once('exit', code => reject(new Error(`server exited ${code}: ${output}`)));
    child.stdout.once('data', chunk => {
      const started = JSON.parse(chunk.toString());
      token = started.token;
      resolve();
    });
  });
}

async function request(urlPath, options = {}) {
  const headers = { ...(options.headers || {}) };
  const response = await fetch(`http://127.0.0.1:${port}${urlPath}`, { ...options, headers });
  return { status: response.status, body: await response.text() };
}

async function waitFor(check) {
  for (let attempt = 0; attempt < 50; attempt += 1) {
    const value = await check();
    if (value) return value;
    await new Promise(resolve => setTimeout(resolve, 20));
  }
  throw new Error('condition did not become true');
}

before(async () => {
  fs.mkdirSync(stateDir, { recursive: true, mode: 0o700 });
  fs.writeFileSync(asset, '<!doctype html><p>original</p>');
  fs.writeFileSync(secondAsset, '<!doctype html><p>second</p>');
  fs.writeFileSync(replacement, '<!doctype html><p>replacement</p>');
  fs.writeFileSync(config, JSON.stringify({
    title: 'Choose safely',
    options: [{ id: 'choice-a', label: 'Choice A', kind: 'html', path: asset }],
  }));
  port = await availablePort();
  await startServer();
});

after(async () => {
  if (child?.exitCode === null) {
    child.kill('SIGTERM');
    await new Promise(resolve => child.once('exit', resolve));
    assert.equal(fs.existsSync(path.join(stateDir, 'server.json')), false);
  }
  fs.rmSync(root, { recursive: true, force: true });
});

test('--help exits successfully', () => {
  const result = run(['--help']);
  assert.equal(result.status, 0);
  assert.match(result.stdout, /agent-preview serve/);
});

test('gallery requires its token and labels the iframe', async () => {
  assert.equal((await request('/')).status, 403);
  const gallery = await request(`/?token=${token}`);
  assert.equal(gallery.status, 200);
  assert.match(gallery.body, /media\.title=option\.label/);
  assert.match(gallery.body, /New options available/);
  assert.match(gallery.body, /Open full size/);
  assert.match(gallery.body, /new EventSource/);
});

test('one state directory rejects a second active server', () => {
  const result = run(['serve', '--config', config, '--state-dir', stateDir, '--port', String(port)]);
  assert.equal(result.status, 1);
  assert.match(result.stderr, /state directory is in use/);
});

test('latest select or reject removes the ID from the opposite set', async () => {
  const submit = action => request('/submit', {
    method: 'POST',
    headers: { 'content-type': 'application/json', 'x-preview-token': token },
    body: JSON.stringify({ action, ids: ['choice-a'], notes: '' }),
  });
  assert.equal((await submit('reject')).status, 200);
  assert.equal((await submit('select')).status, 200);
  const state = JSON.parse(fs.readFileSync(path.join(stateDir, 'state.json')));
  assert.deepEqual(state.selected, ['choice-a']);
  assert.deepEqual(state.rejected, []);
  assert.deepEqual(state.events.map(event => event.action), ['reject', 'select']);
});

test('wait returns persisted feedback after its cursor', () => {
  const result = run(['wait', '--state-dir', stateDir, '--after', '1', '--timeout-seconds', '1']);
  assert.equal(result.status, 0);
  const resultState = JSON.parse(result.stdout);
  assert.equal(resultState.cursor, 2);
  assert.equal(resultState.events[0].action, 'select');
});

test('valid config edits refresh at the same token while invalid edits retain the last good config', async () => {
  fs.writeFileSync(config, JSON.stringify({
    title: 'More choices',
    options: [
      { id: 'choice-a', label: 'Choice A', kind: 'html', path: asset },
      { id: 'choice-b', label: 'Choice B', kind: 'html', path: secondAsset },
    ],
  }));
  const refreshed = await waitFor(async () => {
    const result = await request(`/config?token=${token}`);
    if (result.status !== 200) return null;
    const parsed = JSON.parse(result.body);
    return parsed.options.some(option => option.id === 'choice-b') ? parsed : null;
  });
  assert.equal(refreshed.title, 'More choices');
  assert.equal((await request(`/asset/choice-b?token=${token}`)).status, 200);
  const submission = await request('/submit', {
    method: 'POST',
    headers: { 'content-type': 'application/json', 'x-preview-token': token },
    body: JSON.stringify({ action: 'select', ids: ['choice-b'], notes: 'new option' }),
  });
  assert.equal(submission.status, 200);

  fs.writeFileSync(config, '{ invalid json');
  await waitFor(() => serverErrors.includes('ignored invalid config update'));
  const retained = await request(`/config?token=${token}`);
  assert.equal(retained.status, 200);
  assert.deepEqual(JSON.parse(retained.body), refreshed);
  assert.equal((await request(`/?token=${token}`)).status, 200);
});

test('removed and replaced assets return 404 without stopping the server', async () => {
  fs.unlinkSync(asset);
  assert.equal((await request(`/asset/choice-a?token=${token}`)).status, 404);
  fs.symlinkSync(replacement, asset);
  assert.equal((await request(`/asset/choice-a?token=${token}`)).status, 404);
  assert.equal((await request(`/?token=${token}`)).status, 200);
});

test('symbolic-link state directories and files are rejected', () => {
  const linkedDirectory = path.join(root, 'linked-state');
  fs.symlinkSync(stateDir, linkedDirectory);
  const directoryResult = run(['wait', '--state-dir', linkedDirectory, '--after', '0', '--timeout-seconds', '0']);
  assert.equal(directoryResult.status, 1);
  assert.match(directoryResult.stderr, /must be a real directory/);

  const fileState = path.join(root, 'file-state');
  fs.mkdirSync(fileState, { mode: 0o700 });
  fs.symlinkSync(config, path.join(fileState, 'state.json'));
  const fileResult = run(['wait', '--state-dir', fileState, '--after', '0', '--timeout-seconds', '0']);
  assert.equal(fileResult.status, 1);
  assert.match(fileResult.stderr, /refusing symbolic link/);
});

test('wait receives later feedback when native watcher resources are exhausted', async t => {
  const preload = path.join(root, 'no-native-watch.cjs');
  const fallbackState = path.join(root, 'fallback-state');
  fs.mkdirSync(fallbackState, { mode: 0o700 });
  fs.writeFileSync(preload, "const fs=require('node:fs'); fs.watch = () => { throw Object.assign(new Error('watch quota exhausted'), {code:'EMFILE'}); }; const watchFile=fs.watchFile; fs.watchFile=(...args)=>{ const watcher=watchFile(...args); setImmediate(()=>process.send?.('watch armed')); return watcher; };\n");
  const waiting = spawn(process.execPath, ['--require', preload, helper, 'wait',
    '--state-dir', fallbackState, '--after', '0', '--timeout-seconds', '3'],
  { stdio: ['ignore', 'pipe', 'pipe', 'ipc'] });
  t.after(() => { if (waiting.exitCode === null) waiting.kill('SIGTERM'); });
  let output = '';
  let errors = '';
  waiting.stdout.on('data', chunk => { output += chunk; });
  waiting.stderr.on('data', chunk => { errors += chunk; });
  const finished = new Promise(resolve => waiting.once('exit', resolve));
  await new Promise((resolve, reject) => {
    waiting.once('message', resolve);
    waiting.once('error', reject);
    waiting.once('exit', code => reject(new Error(`wait exited before watching: ${code}`)));
  });
  fs.writeFileSync(path.join(fallbackState, 'state.json'), JSON.stringify({ seq: 1,
    selected: ['choice-b'], rejected: [], events: [{ seq: 1, action: 'select', ids: ['choice-b'], notes: 'fallback response' }] }));
  assert.equal(await finished, 0);
  assert.deepEqual(JSON.parse(output).selected, ['choice-b']);
  assert.match(errors, /using file-stat checks/);
});
