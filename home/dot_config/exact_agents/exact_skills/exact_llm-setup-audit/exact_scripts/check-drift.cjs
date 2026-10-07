#!/usr/bin/env node
'use strict';

const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const crypto = require('node:crypto');
const { execFileSync } = require('node:child_process');

const roots = ['.config/agents', '.codex/agents'];
const helpers = ['agent-task', 'agent-watch', 'agent-preflight', 'agent-preview'];
const hash = data => crypto.createHash('sha256').update(data).digest('hex');
const permitted = name => roots.some(root => name === root || name.startsWith(`${root}/`)) ||
  helpers.some(helper => name === `.local/bin/${helper}`);
const run = (command, args, options = {}) => execFileSync(command, args, {
  encoding: 'utf8', maxBuffer: 32 * 1024 * 1024, timeout: 120000, ...options,
});

function findTool(name) {
  const dirs = [...(process.env.PATH || '').split(path.delimiter),
    path.join(os.homedir(), '.local/bin'), '/usr/local/bin',
    '/opt/homebrew/bin', '/home/linuxbrew/.linuxbrew/bin'];
  for (const dir of dirs.filter(Boolean)) {
    const candidate = path.join(dir, name);
    try { fs.accessSync(candidate, fs.constants.X_OK); return candidate; } catch {}
  }
  throw new Error(`${name} is unavailable; run host-preflight on this host`);
}

function brokenReferences(file, content) {
  const missing = [];
  for (const match of content.matchAll(/\[[^\]\n]*\]\(([^\s)]+)(?:\s+"[^"]*")?\)/g)) {
    const link = match[1].replace(/^<|>$/g, '');
    if (/^(?:[a-z][a-z\d+.-]*:|#|\/|~)/i.test(link)) continue;
    let target;
    try { target = decodeURIComponent(link.split('#')[0]); } catch { target = link; }
    if (target && !fs.existsSync(path.resolve(path.dirname(file), target))) missing.push(link);
  }
  return [...new Set(missing)];
}

function snapshot(options = {}) {
  const home = options.home || os.homedir();
  const chezmoi = options.chezmoi || findTool('chezmoi');
  const selected = options.paths?.length ? options.paths :
    [...roots, ...helpers.map(name => `.local/bin/${name}`)];
  const managed = JSON.parse(run(chezmoi, ['managed', '--format', 'json',
    '--path-style', 'all', '--include', 'files,symlinks',
    ...selected.map(name => path.join(home, name))]));
  const files = {};
  for (const [name, entry] of Object.entries(managed)) {
    if (!permitted(name) || name.includes('/skills/synced/')) continue;
    const record = { source: entry.sourceAbsolute, installed: entry.absolute };
    try {
      const source = fs.readFileSync(entry.sourceAbsolute);
      record.sourceHash = hash(source);
      record.template = entry.sourceAbsolute.endsWith('.tmpl');
      const expected = run(chezmoi, ['cat', entry.absolute], { encoding: 'buffer' });
      const sourceName = path.basename(entry.sourceAbsolute);
      const symlink = /^(?:(?:private|readonly)_)*symlink_/.test(sourceName);
      record.kind = symlink ? 'symlink' : 'file';
      record.renderedHash = hash(expected);
      record.resolved = fs.realpathSync(entry.absolute);
      const installed = fs.readFileSync(record.resolved);
      record.installedHash = hash(installed);
      record.matchesSource = symlink
        ? fs.lstatSync(entry.absolute).isSymbolicLink() &&
          fs.readlinkSync(entry.absolute) === expected.toString().trimEnd()
        : hash(installed) === record.renderedHash;
      record.missingReferences = name.endsWith('.md')
        ? brokenReferences(record.resolved, installed.toString()) : [];
    } catch (error) { record.error = error.message; }
    files[name] = record;
  }
  for (const name of selected) {
    if (!Object.keys(files).some(file =>
      file === name || file.startsWith(`${name}/`))) {
      files[name] = { error: 'Selected path is not managed on this host' };
    }
  }
  return { host: os.hostname(), sourceRoot: run(chezmoi, ['source-path']).trim(), files };
}

function compare(snapshots, exceptions = []) {
  const mismatches = [];
  const intentionalDifferences = [];
  const entries = Object.entries(snapshots);
  const names = new Set(entries.flatMap(([, result]) => Object.keys(result.files || {})));
  for (const [host, result] of entries) {
    if (result.error) mismatches.push({ host, kind: 'host_error', detail: result.error });
    for (const [file, record] of Object.entries(result.files || {})) {
      if (record.error) mismatches.push({ host, file, kind: 'file_error', detail: record.error });
      else if (!record.matchesSource) mismatches.push({ host, file, kind: 'installed_drift' });
      for (const reference of record.missingReferences || []) {
        mismatches.push({ host, file, kind: 'missing_reference', reference });
      }
    }
  }
  for (const file of names) {
    const rows = entries.filter(([, result]) => !result.error)
      .map(([host, result]) => [host, result.files[file]]);
    if (rows.length < 2) continue;
    for (const [host, record] of rows) {
      if (!record) mismatches.push({ host, file, kind: 'missing_source' });
    }
    if (rows.some(([, record]) => !record || record.error)) continue;
    const sources = new Set(rows.map(([, record]) => record.sourceHash));
    const installed = new Set(rows.map(([, record]) => record.installedHash));
    if (sources.size === 1 && installed.size === 1) continue;
    const allowance = exceptions.find(item => item.path === file && item.reason &&
      rows.every(([host, record]) => item.hosts?.[host] === record.installedHash) &&
      rows.every(([, record]) => record.matchesSource));
    const rendered = sources.size === 1 && rows.every(([, record]) =>
      record.template && record.matchesSource);
    if (allowance || rendered) {
      intentionalDifferences.push({ file, reason: allowance?.reason || 'Identical template rendered separately on each host' });
    } else {
      mismatches.push({ file, kind: sources.size > 1 ? 'source_drift' : 'host_drift',
        hosts: Object.fromEntries(rows.map(([host, record]) => [host, {
          sourceHash: record.sourceHash, installedHash: record.installedHash,
        }])) });
    }
  }
  return { mismatches, intentionalDifferences };
}

function main(args) {
  if (args.includes('--help')) {
    process.stdout.write('Usage: node check-drift.cjs [--remote USER@HOST] [--path HOME_RELATIVE_PATH]\n' +
      '       [--exceptions FILE] [--details]\n' +
      'Read-only. Repeat --remote or --path. JSON output; exit 1 means drift or incomplete coverage.\n' +
      'Exceptions: [{"path":"...","hosts":{"local":"SHA256","user@host":"SHA256"},"reason":"..."}]\n');
    return;
  }
  if (args[0] === '--snapshot') {
    const options = JSON.parse(Buffer.from(args[1], 'base64').toString());
    process.stdout.write(JSON.stringify(snapshot(options)));
    return;
  }
  const options = { paths: [] };
  const remotes = [];
  let exceptions = [];
  let details = false;
  for (let i = 0; i < args.length; i++) {
    const option = args[i];
    if (option === '--details') { details = true; continue; }
    const value = args[++i];
    if (!value) throw new Error(`Missing value for ${option}`);
    if (option === '--remote') {
      if (!/^[a-z\d_][a-z\d_.@:-]*$/i.test(value)) throw new Error('Invalid SSH host');
      remotes.push(value);
    } else if (option === '--path') {
      if (path.normalize(value) !== value || !permitted(value)) throw new Error('Path must be within the shared agent scope');
      options.paths.push(value);
    } else if (option === '--exceptions') {
      exceptions = JSON.parse(fs.readFileSync(value, 'utf8'));
      if (!Array.isArray(exceptions)) throw new Error('Exceptions must be an array');
    } else throw new Error(`Unknown option: ${option}`);
  }
  const snapshots = {};
  try { snapshots.local = snapshot(options); } catch (error) { snapshots.local = { error: error.message }; }
  const encoded = Buffer.from(JSON.stringify(options)).toString('base64');
  for (const remote of new Set(remotes)) {
    try {
      const command = 'if command -v node >/dev/null 2>&1; then exec node - --snapshot ' + encoded +
        '; elif [ -x /usr/local/bin/node ]; then exec /usr/local/bin/node - --snapshot ' + encoded +
        '; else echo "Node is unavailable" >&2; exit 127; fi';
      snapshots[remote] = JSON.parse(run('ssh', ['-T', '-o', 'BatchMode=yes', '-o',
        'ConnectTimeout=10', '-o', 'RemoteCommand=none', '-o', 'ForwardAgent=no',
        remote, command], { input: fs.readFileSync(__filename) }));
    } catch (error) { snapshots[remote] = { error: error.message }; }
  }
  const result = compare(snapshots, exceptions);
  const coverage = Object.fromEntries(Object.entries(snapshots).map(([host, value]) =>
    [host, { host: value.host, sourceRoot: value.sourceRoot,
      files: Object.keys(value.files || {}).length, error: value.error }]));
  process.stdout.write(JSON.stringify({ coverage, ...result, ...(details ? { snapshots } : {}) }, null, 2) + '\n');
  process.exitCode = result.mismatches.length ? 1 : 0;
}

if (require.main === module || process.argv[1] === '-') {
  try { main(process.argv.slice(2)); } catch (error) {
    process.stderr.write(`check-drift: ${error.message}\n`); process.exitCode = 2;
  }
}
module.exports = { snapshot, compare, brokenReferences };
