#!/usr/bin/env node

const fs = require('node:fs');

const scenarioPath = process.env.AGENT_WATCH_FAKE_SCENARIO;
const statePath = process.env.AGENT_WATCH_FAKE_STATE;
if (!scenarioPath || !statePath) {
  process.stderr.write('fake gh needs scenario and state paths\n');
  process.exit(70);
}

const scenario = JSON.parse(fs.readFileSync(scenarioPath, 'utf8'));
let index = 0;
try {
  index = Number(fs.readFileSync(statePath, 'utf8'));
} catch (error) {
  if (error.code !== 'ENOENT') throw error;
}

const response = scenario[index];
if (!response) {
  process.stderr.write(`unexpected call ${index}: ${process.argv.slice(2).join(' ')}\n`);
  process.exit(70);
}
const invocation = process.argv.slice(2).join(' ');
if (response.includes && !invocation.includes(response.includes)) {
  process.stderr.write(`call ${index} expected ${response.includes}; got ${invocation}\n`);
  process.exit(70);
}

fs.writeFileSync(statePath, String(index + 1));
if (response.delayMs) {
  Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, response.delayMs);
}
if (response.stdout !== undefined) process.stdout.write(response.stdout);
if (response.stderr !== undefined) process.stderr.write(response.stderr);
process.exit(response.code ?? 0);
