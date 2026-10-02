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
  assert.match(gallery.body, /node\.title=option\.label/);
  assert.match(gallery.body, /New options are available/);
  assert.match(gallery.body, /View larger/);
  assert.match(gallery.body, /<dialog id="viewer" aria-labelledby="viewer-title">/);
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
    return parsed.questions[0].options.some(option => option.id === 'choice-b') ? parsed : null;
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

test('questions validate answers per question and record them', async () => {
  const questionsConfig = path.join(root, 'questions.json');
  const questionsState = path.join(root, 'questions-state');
  fs.writeFileSync(asset, '<!doctype html><p>restored</p>');
  fs.writeFileSync(questionsConfig, JSON.stringify({
    title: 'Two questions',
    questions: [
      { id: 'size', title: 'Size', select: 'one', options: [
        { id: 'small', label: 'Small', kind: 'html', path: secondAsset },
        { id: 'large', label: 'Large', kind: 'html', path: replacement },
      ] },
      { id: 'layout', title: 'Layout', select: 'many', options: [{ id: 'rows', label: 'Rows', kind: 'html', path: secondAsset }] },
    ],
  }));
  const questionPort = await availablePort();
  const server = spawn(process.execPath, [helper, 'serve', '--config', questionsConfig, '--state-dir', questionsState, '--port', String(questionPort)], { stdio: ['ignore', 'pipe', 'pipe'] });
  try {
    const started = await new Promise(resolve => server.stdout.once('data', chunk => resolve(JSON.parse(chunk.toString()))));
    assert.match(started.url, new RegExp(`:${questionPort}/\\?token=${started.token}$`));
    const post = body => fetch(`http://127.0.0.1:${questionPort}/submit`, {
      method: 'POST', headers: { 'content-type': 'application/json', 'x-preview-token': started.token }, body: JSON.stringify(body),
    });
    const config = await (await fetch(`http://127.0.0.1:${questionPort}/config?token=${started.token}`)).json();
    assert.deepEqual(config.questions.map(question => [question.id, question.select]), [['size', 'one'], ['layout', 'many']]);
    assert.equal((await post({ action: 'select', ids: ['small', 'large'], notes: '', answers: { size: { ids: ['small', 'large'], notes: '' } } })).status, 400);
    assert.equal((await post({ action: 'select', ids: ['rows'], notes: '', answers: { size: { ids: ['rows'], notes: '' } } })).status, 400);
    assert.equal((await post({ action: 'select', ids: ['small', 'rows'], notes: 'all', answers: { size: { ids: ['small'], notes: 'tight' }, layout: { ids: ['rows'], notes: '' } } })).status, 200);
    const state = JSON.parse(fs.readFileSync(path.join(questionsState, 'state.json')));
    assert.deepEqual(state.events.at(-1).answers.size, { ids: ['small'], notes: 'tight' });
  } finally {
    server.kill('SIGTERM');
    await new Promise(resolve => server.once('exit', resolve));
  }
});

test('a detached server keeps its token across restarts and stops on request', async () => {
  const detachedState = path.join(root, 'detached-state');
  const detachedPort = await availablePort();
  const start = () => run(['serve', '--config', config, '--state-dir', detachedState, '--port', String(detachedPort), '--detach', 'true']);
  fs.writeFileSync(config, JSON.stringify({ title: 'Detached', options: [{ id: 'choice-b', label: 'Choice B', kind: 'html', path: secondAsset }] }));
  const first = JSON.parse(start().stdout);
  assert.equal((await fetch(`http://127.0.0.1:${detachedPort}/?token=${first.token}`)).status, 200);
  assert.match(run(['stop', '--state-dir', detachedState]).stdout, /stopped/);
  await waitFor(() => !fs.existsSync(path.join(detachedState, 'server.json')));
  const second = JSON.parse(start().stdout);
  assert.equal(second.token, first.token);
  assert.match(run(['stop', '--state-dir', detachedState]).stdout, /stopped/);
});

test('artifact feedback preserves comments, pins, requirements, and combinations without selecting a winner', async () => {
  const image = path.join(root, 'fallback.svg');
  fs.writeFileSync(image, '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100"/>');
  fs.writeFileSync(config, JSON.stringify({ title: 'Artifact review', questions: [
    { id: 'page', title: 'Page', select: 'one', options: [
      { id: 'first', label: 'First', kind: 'html', path: secondAsset, scripts: true },
      { id: 'second', label: 'Second', kind: 'html', path: replacement },
    ] },
    { id: 'art', title: 'Art', select: 'many', options: [{ id: 'image', label: 'Image', kind: 'image', path: image }] },
  ] }));
  const current = await waitFor(async () => {
    const value = JSON.parse((await request(`/config?token=${token}`)).body);
    return value.title === 'Artifact review' ? value : null;
  });
  const post = body => request('/submit', { method: 'POST', headers: {
    'content-type': 'application/json', 'x-preview-token': token,
  }, body: JSON.stringify(body) });
  const review = status => ({ status, comment: '', annotations: [] });
  const feedback = { action: 'review', revision: current.revision, ids: [], notes: 'Keep these ideas',
    requirements: 'Must work at 320 px', submissionId: 'mobile-review-1',
    answers: { page: { ids: [], notes: 'Both need changes' }, art: { ids: [], notes: '' } },
    reviews: {
      first: { status: 'rejected', comment: 'Too dense', annotations: [{ anchor: {
        kind: 'element', selector: 'h1', matchIndex: 1, text: 'Hello',
      }, comment: 'Shorter heading' }] },
      second: review('rejected'),
      image: { status: 'unreviewed', comment: '', annotations: [{ anchor: {
        kind: 'point', x: 0.3, y: 0.7,
      }, comment: 'Use this color' }] },
    }, combinations: [{ ids: ['first', 'second'], notes: 'First spacing, second colors' }],
  };
  const sent = await post(feedback);
  assert.equal(sent.status, 200, sent.body);
  const seq = JSON.parse(sent.body).seq;
  const state = JSON.parse(fs.readFileSync(path.join(stateDir, 'state.json')));
  const event = state.events.at(-1);
  assert.deepEqual(event.reviews, feedback.reviews);
  assert.deepEqual(event.combinations, feedback.combinations);
  assert.equal(event.requirements, feedback.requirements);
  assert.deepEqual(state.rejected.filter(id => ['first', 'second'].includes(id)), ['first', 'second']);
  assert.equal((await post(feedback)).body, sent.body);
  assert.equal(JSON.parse(fs.readFileSync(path.join(stateDir, 'state.json'))).seq, seq);
  const waited = JSON.parse(run(['wait', '--state-dir', stateDir, '--after', String(seq - 1), '--timeout-seconds', '0']).stdout);
  assert.equal(waited.events[0].submissionId, 'mobile-review-1');

  const invalid = structuredClone(feedback);
  delete invalid.submissionId;
  invalid.reviews.image.annotations[0].anchor.x = 1.1;
  assert.equal((await post(invalid)).status, 400);
  invalid.reviews.image.annotations[0].anchor.x = 0.3;
  invalid.reviews.first.annotations[0].anchor.matchIndex = -1;
  assert.equal((await post(invalid)).status, 400);
  invalid.reviews = { first: review('approved'), second: review('approved') };
  invalid.ids = ['first', 'second'];
  assert.equal((await post(invalid)).status, 400);
  invalid.reviews = { first: review('approved') };
  invalid.ids = [];
  assert.equal((await post(invalid)).status, 400);
  invalid.reviews = feedback.reviews;
  invalid.combinations = [{ ids: ['first', 'missing'], notes: '' }];
  assert.equal((await post(invalid)).status, 400);
  invalid.combinations = [];
  invalid.revision = current.revision - 1;
  assert.equal((await post(invalid)).status, 409);

  const replacementFeedback = { ...feedback, submissionId: 'mobile-review-2', ids: ['second'],
    reviews: { first: review('unreviewed'), second: review('approved'), image: review('unreviewed') },
    answers: { page: { ids: ['second'], notes: '' }, art: { ids: [], notes: '' } },
  };
  assert.equal((await post(replacementFeedback)).status, 200);
  const replacementState = JSON.parse(fs.readFileSync(path.join(stateDir, 'state.json')));
  assert.ok(replacementState.selected.includes('second'));
  assert.ok(!replacementState.rejected.includes('first'));
  assert.ok(!replacementState.rejected.includes('second'));
});

test('raw HTML retains its doctype and isolates scripts while allowing the annotation bridge', async () => {
  const staticPage = await fetch(`http://127.0.0.1:${port}/asset/second?token=${token}`);
  assert.match(staticPage.headers.get('content-security-policy'), /sandbox allow-scripts/);
  assert.match(staticPage.headers.get('content-security-policy'), /script-src 'nonce-[^']+'/);
  assert.match(staticPage.headers.get('content-security-policy'), /default-src 'none'/);
  assert.equal(staticPage.headers.get('referrer-policy'), 'no-referrer');
  const html = await staticPage.text();
  assert.match(html, /^<!doctype html>/i);
  assert.match(html, /preview:annotation/);
  const interactive = await fetch(`http://127.0.0.1:${port}/asset/first?token=${token}`);
  assert.match(interactive.headers.get('content-security-policy'), /script-src 'unsafe-inline'/);
  const denied = await request('/submit', { method: 'POST', headers: {
    'content-type': 'application/json', 'x-preview-token': token, origin: 'null',
  }, body: JSON.stringify({ action: 'more', ids: [], notes: '' }) });
  assert.equal(denied.status, 403);
});

test('an active wait wakes as soon as feedback is saved', async t => {
  const cursor = JSON.parse(fs.readFileSync(path.join(stateDir, 'state.json'))).seq;
  const waiting = spawn(process.execPath, [helper, 'wait', '--state-dir', stateDir,
    '--after', String(cursor), '--timeout-seconds', '3'], { stdio: ['ignore', 'pipe', 'pipe'] });
  t.after(() => { if (waiting.exitCode === null) waiting.kill('SIGTERM'); });
  let output = '';
  waiting.stdout.on('data', chunk => { output += chunk; });
  const finished = new Promise(resolve => waiting.once('exit', resolve));
  const response = await request('/submit', { method: 'POST', headers: {
    'content-type': 'application/json', 'x-preview-token': token,
  }, body: JSON.stringify({ action: 'more', ids: [], notes: 'Please add an option' }) });
  assert.equal(response.status, 200);
  assert.equal(await finished, 0);
  assert.equal(JSON.parse(output).events[0].notes, 'Please add an option');
});
