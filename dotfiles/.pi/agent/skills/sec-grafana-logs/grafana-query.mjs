#!/usr/bin/env node
import { execFileSync, spawn } from 'node:child_process';
import { copyFileSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync } from 'node:fs';
import { homedir, tmpdir } from 'node:os';
import { join } from 'node:path';
import assert from 'node:assert/strict';

const environments = {
  global: {
    host: 'grafana.apps.os-global.finods.com',
    app: 'application-logs-dals',
    payload: 'payload-infrastructure-logs-pils',
  },
  restricted: {
    host: 'grafana.apps.os-restricted.finods.com',
    app: 'application-logs-dals',
    payload: 'payload-infrastructure-logs-pils',
  },
  dc1: {
    host: 'grafana.apps.dc1-os-prod.finods.com',
    app: 'application-logs-dals-dc1',
    payload: 'payload-infrastructure-logs-pils-dc1',
  },
  dc2: {
    host: 'grafana.apps.dc2-os-prod.finods.com',
    app: 'application-logs-dals-dc2',
    payload: 'payload-infrastructure-logs-pils-dc2',
  },
};

function findEdgeBinary() {
  const candidates = [
    process.env.EDGE_BINARY,
    'microsoft-edge-stable',
    'microsoft-edge',
    'msedge',
    '/opt/microsoft/msedge/msedge',
  ].filter(Boolean);
  for (const candidate of candidates) {
    if (candidate.includes('/') && existsSync(candidate)) return candidate;
    if (!candidate.includes('/')) {
      try {
        return execFileSync('which', [candidate], { encoding: 'utf8' }).trim();
      } catch {}
    }
  }
  throw new Error('Microsoft Edge was not found. Set EDGE_BINARY to its executable path.');
}

function findProfileRoot() {
  if (process.env.EDGE_PROFILE_ROOT) return process.env.EDGE_PROFILE_ROOT;
  const candidates = [
    join(homedir(), '.config', 'microsoft-edge'),
    join(homedir(), '.config', 'microsoft-edge-beta'),
    join(homedir(), '.config', 'microsoft-edge-dev'),
  ];
  const found = candidates.find(path => existsSync(join(path, 'Local State')));
  if (!found) throw new Error('Microsoft Edge profile was not found. Set EDGE_PROFILE_ROOT.');
  return found;
}

function windowsBetween(start, end, hours) {
  const first = BigInt(start);
  const last = BigInt(end);
  const width = BigInt(hours) * 60n * 60n * 1_000_000_000n;
  if (first >= last) throw new Error('Start must be before end.');
  const count = (last - first + width - 1n) / width;
  if (count > 31n) throw new Error('Count mode is limited to 31 windows. Narrow the range or increase --window-hours.');
  const windows = [];
  for (let cursor = first; cursor < last; cursor += width) {
    const next = cursor + width < last ? cursor + width : last;
    windows.push([cursor.toString(), (next < last ? next - 1n : next).toString()]);
  }
  return windows;
}

function extractCounts(payload, pattern) {
  if (payload?.status !== 'success') throw new Error(`Loki query failed: ${payload?.error || 'unknown error'}`);
  const regex = new RegExp(pattern);
  const matches = [];
  for (const stream of payload?.data?.result || []) {
    for (const [timestamp, line] of stream.values || []) {
      const match = String(line).match(regex);
      if (!match?.[1]) continue;
      const count = Number(match[1]);
      if (Number.isSafeInteger(count)) matches.push({ timestamp, count });
    }
  }
  return matches;
}

function datasourceKindForScope(scope) {
  return { app: 'app', 'sec-app': 'app', payload: 'payload', 'sec-payload': 'payload' }[scope];
}

function summarizeCounts(matches) {
  const values = matches.map(match => match.count).sort((a, b) => a - b);
  if (!values.length) return { n: 0, min: null, median: null, mean: null, max: null };
  const middle = Math.floor(values.length / 2);
  const median = values.length % 2 ? values[middle] : (values[middle - 1] + values[middle]) / 2;
  return {
    n: values.length,
    min: values[0],
    median,
    mean: values.reduce((sum, value) => sum + value, 0) / values.length,
    max: values.at(-1),
  };
}

function queryPayload(result) {
  if (result?.status !== 200) {
    // Loki's 400 body explains malformed queries; don't echo auth/proxy HTML.
    const diagnostic = result?.status === 400 && !/^\s*</.test(result.text || '')
      ? String(result.text || '').replace(/[\x00-\x1f\x7f]/g, ' ').slice(0, 1000).trim()
      : '';
    throw new Error(`Grafana query returned HTTP ${result?.status ?? 'unknown'}.${diagnostic ? ` ${diagnostic}` : ''}`);
  }
  const payload = JSON.parse(result.text);
  if (payload?.status !== 'success') throw new Error(`Loki query failed: ${String(payload?.error || 'unknown error').slice(0, 1000)}`);
  return payload;
}

function selfTest() {
  assert.deepEqual(windowsBetween('0', '7200000000000', 1), [
    ['0', '3599999999999'],
    ['3600000000000', '7200000000000'],
  ]);
  const matches = extractCounts({
    status: 'success',
    data: { result: [{ values: [['1', 'Deleted 5 files'], ['2', 'ignored'], ['3', 'Deleted 9 files']] }] },
  }, 'Deleted ([0-9]+) files');
  assert.deepEqual(summarizeCounts(matches), { n: 2, min: 5, median: 7, mean: 7, max: 9 });
  assert.equal(datasourceKindForScope('app'), 'app');
  assert.equal(datasourceKindForScope('sec-app'), 'app');
  assert.equal(datasourceKindForScope('payload'), 'payload');
  assert.equal(datasourceKindForScope('sec-payload'), 'payload');
  assert.deepEqual(queryPayload({ status: 200, text: '{"status":"success","data":{"result":[]}}' }),
    { status: 'success', data: { result: [] } });
  assert.throws(() => queryPayload({ status: 400, text: 'parse error: queries require a non-empty matcher' }),
    /HTTP 400.*non-empty matcher/);
  assert.throws(() => queryPayload({ status: 400, text: '<html>private proxy response</html>' }),
    { message: 'Grafana query returned HTTP 400.' });
  assert.throws(() => queryPayload({ status: 401, text: 'private authentication response' }),
    { message: 'Grafana query returned HTTP 401.' });
  assert.throws(() => queryPayload({ status: 200, text: '{"status":"error","error":"bad query"}' }), /bad query/);
  assert.throws(() => queryPayload({ status: 400, text: 'x'.repeat(2000) }),
    error => error.message.length < 1100);
  assert.throws(() => queryPayload({ status: 200, text: 'not JSON' }), SyntaxError);
  assert.throws(() => queryPayload(undefined), /HTTP unknown/);
  console.log('grafana-query self-test: OK');
}

const args = process.argv.slice(2);
if (args[0] === 'self-test') {
  selfTest();
  process.exit(0);
}

const environmentName = args.shift();
const environment = environments[environmentName];
const checkSessionOnly = args[0] === 'check-session';
if (checkSessionOnly) args.shift();

let scope;
let start;
let end;
let limit;
let query;
let windowHours;
let countRegex;
if (!checkSessionOnly) {
  [scope, start, end] = args.splice(0, 3);
  limit = /^\d+$/.test(args[0] || '') ? args.shift() : '20';
  while (args.length && args[0].startsWith('--')) {
    const option = args.shift();
    if (option === '--window-hours') windowHours = args.shift();
    else if (option === '--count-regex') countRegex = args.shift();
    else {
      console.error(`Unknown option: ${option}`);
      process.exit(2);
    }
  }
  query = args.join(' ');
}

const datasourceKind = checkSessionOnly ? undefined : datasourceKindForScope(scope);
if (!environment || (!checkSessionOnly && (!datasourceKind || !start || !end || !query))) {
  console.error('Usage:\n  grafana-query.mjs <environment> check-session\n  grafana-query.mjs <environment> <app|payload> <start-ns> <end-ns> [limit] [--window-hours N --count-regex REGEX] <LogQL>');
  process.exit(2);
}
if (!checkSessionOnly && (!/^\d+$/.test(start) || !/^\d+$/.test(end) || !/^\d+$/.test(limit))) {
  console.error('Start, end, and limit must be integers.');
  process.exit(2);
}
if ((windowHours || countRegex) && (!/^\d+$/.test(windowHours || '') || Number(windowHours) < 1 || !countRegex)) {
  console.error('--window-hours and --count-regex must be provided together; hours must be a positive integer.');
  process.exit(2);
}
try {
  if (countRegex) new RegExp(countRegex);
} catch (error) {
  console.error(`Invalid count regex: ${error.message}`);
  process.exit(2);
}

const startedAt = performance.now();
let queryMs = 0;
let queryCount = 0;
let failedQueries = 0;
const profileName = process.env.EDGE_PROFILE_NAME || 'Default';
const workDir = mkdtempSync(join(tmpdir(), 'sec-grafana-edge-'));
const copiedProfile = join(workDir, profileName);
let edge;
let cleanupPromise;

const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));

function groupExists(pid) {
  try {
    process.kill(-pid, 0);
    return true;
  } catch {
    return false;
  }
}

async function waitForEdge(milliseconds) {
  if (!edge || edge.exitCode !== null) return;
  await Promise.race([
    new Promise(resolve => edge.once('exit', resolve)),
    sleep(milliseconds),
  ]);
}

async function cleanup() {
  if (cleanupPromise) return cleanupPromise;
  cleanupPromise = (async () => {
    if (edge?.pid && groupExists(edge.pid)) {
      try {
        process.kill(-edge.pid, 'SIGTERM');
      } catch {}
      await waitForEdge(1_000);
      if (groupExists(edge.pid)) {
        try {
          process.kill(-edge.pid, 'SIGKILL');
        } catch {}
        await waitForEdge(1_000);
      }
    }
    let removalError;
    for (let attempt = 0; attempt < 5; attempt++) {
      try {
        rmSync(workDir, { recursive: true, force: true });
        return;
      } catch (error) {
        removalError = error;
        await sleep(200);
      }
    }
    throw new Error(`Could not remove temporary Edge profile ${workDir}: ${removalError?.message || 'unknown error'}`);
  })();
  return cleanupPromise;
}

for (const [signal, code] of [['SIGINT', 130], ['SIGTERM', 143]]) {
  process.once(signal, () => {
    cleanup().catch(error => console.error(error.message)).finally(() => process.exit(code));
  });
}

async function evaluate(webSocketUrl, expression) {
  const socket = new WebSocket(webSocketUrl);
  await new Promise((resolve, reject) => {
    const timeout = setTimeout(() => {
      socket.close();
      reject(new Error('Timed out connecting to Edge DevTools.'));
    }, 10_000);
    socket.onopen = () => {
      clearTimeout(timeout);
      resolve();
    };
    socket.onerror = error => {
      clearTimeout(timeout);
      socket.close();
      reject(error);
    };
  });
  const response = await new Promise((resolve, reject) => {
    const timeout = setTimeout(() => reject(new Error('Timed out waiting for the Grafana browser request.')), 35_000);
    socket.onmessage = event => {
      const message = JSON.parse(event.data);
      if (message.id === 1) {
        clearTimeout(timeout);
        resolve(message);
      }
    };
    socket.onerror = error => {
      clearTimeout(timeout);
      reject(error);
    };
    socket.send(JSON.stringify({
      id: 1,
      method: 'Runtime.evaluate',
      params: { expression, awaitPromise: true, returnByValue: true },
    }));
  }).finally(() => socket.close());
  if (response.result?.exceptionDetails) {
    throw new Error(response.result.exceptionDetails.exception?.description || 'Grafana browser request failed.');
  }
  return response.result?.result?.value;
}

async function runQuery(webSocketUrl, queryStart, queryEnd) {
  const datasource = environment[datasourceKind];
  const parameters = new URLSearchParams({ query, start: queryStart, end: queryEnd, limit, direction: 'backward' });
  const path = `https://${environment.host}/api/datasources/proxy/uid/${datasource}/loki/api/v1/query_range?${parameters}`;
  const queryStartedAt = performance.now();
  queryCount++;
  try {
    const result = await evaluate(
      webSocketUrl,
      `fetch(${JSON.stringify(path)}, {signal: AbortSignal.timeout(30000)}).then(async response => ({status: response.status, text: await response.text()}))`,
    );
    return queryPayload(result);
  } catch (error) {
    failedQueries++;
    throw error;
  } finally {
    queryMs += performance.now() - queryStartedAt;
  }
}

try {
  const profileRoot = findProfileRoot();
  const sourceProfile = join(profileRoot, profileName);
  const sourceCookies = join(sourceProfile, 'Cookies');
  if (!existsSync(sourceCookies)) throw new Error(`Edge profile ${profileName} has no Cookies database.`);

  mkdirSync(copiedProfile, { recursive: true, mode: 0o700 });
  copyFileSync(join(profileRoot, 'Local State'), join(workDir, 'Local State'));
  const destinationCookies = join(copiedProfile, 'Cookies');
  execFileSync('sqlite3', [sourceCookies, `.backup '${destinationCookies.replaceAll("'", "''")}'`]);
  const preferences = join(sourceProfile, 'Preferences');
  if (existsSync(preferences)) copyFileSync(preferences, join(copiedProfile, 'Preferences'));
  execFileSync('sqlite3', [
    destinationCookies,
    `DELETE FROM cookies WHERE host_key NOT IN ('${environment.host}', '.${environment.host}');`,
  ]);

  edge = spawn(findEdgeBinary(), [
    '--headless=new',
    '--disable-gpu',
    '--remote-debugging-port=0',
    `--user-data-dir=${workDir}`,
    `--profile-directory=${profileName}`,
    `https://${environment.host}/`,
  ], { stdio: 'ignore', detached: true });
  await new Promise((resolve, reject) => {
    edge.once('spawn', resolve);
    edge.once('error', reject);
  });

  const portFile = join(workDir, 'DevToolsActivePort');
  let port;
  for (let attempt = 0; attempt < 50; attempt++) {
    try {
      [port] = readFileSync(portFile, 'utf8').split('\n');
      break;
    } catch {
      await sleep(100);
    }
  }
  if (!port) throw new Error('Edge did not start.');

  let tab;
  for (let attempt = 0; attempt < 50; attempt++) {
    const tabs = await fetch(`http://127.0.0.1:${port}/json/list`, { signal: AbortSignal.timeout(2_000) })
      .then(response => response.json());
    tab = tabs.find(item => item.url.startsWith(`https://${environment.host}/`));
    if (tab) break;
    await sleep(100);
  }
  if (!tab) throw new Error('Grafana tab did not open.');
  await sleep(1000);

  let user;
  try {
    user = await evaluate(
      tab.webSocketDebuggerUrl,
      `fetch('https://${environment.host}/api/user', {credentials: 'include', signal: AbortSignal.timeout(10000)}).then(async response => ({status: response.status}))`,
    );
  } catch (error) {
    throw new Error(`Grafana session preflight failed for ${environmentName}: ${error.message}`);
  }
  if (user?.status !== 200) {
    throw new Error(`No Edge Grafana session for ${environmentName}. Open https://${environment.host}/ and complete SSO in profile ${profileName}.`);
  }

  if (checkSessionOnly) {
    process.stdout.write(`${JSON.stringify({ status: 'success', environment: environmentName, profile: profileName })}\n`);
  } else if (countRegex) {
    const matches = [];
    const windows = [];
    for (const [windowStart, windowEnd] of windowsBetween(start, end, Number(windowHours))) {
      const payload = await runQuery(tab.webSocketDebuggerUrl, windowStart, windowEnd);
      const returned = (payload?.data?.result || []).reduce((total, stream) => total + (stream.values?.length || 0), 0);
      const found = extractCounts(payload, countRegex);
      matches.push(...found);
      windows.push({ start: windowStart, end: windowEnd, matches: found.length, saturated: returned >= Number(limit) });
    }
    const complete = windows.every(window => !window.saturated);
    process.stdout.write(`${JSON.stringify({
      status: 'success',
      complete,
      environment: environmentName,
      scope,
      windows,
      summary: summarizeCounts(matches),
      matches,
      warning: complete ? undefined : 'At least one window reached the Loki limit; statistics cover only returned records.',
    })}\n`);
  } else {
    process.stdout.write(`${JSON.stringify(await runQuery(tab.webSocketDebuggerUrl, start, end))}\n`);
  }
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
} finally {
  try {
    await cleanup();
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
  console.error(`grafana-query: elapsed_ms=${Math.round(performance.now() - startedAt)} query_ms=${Math.round(queryMs)} queries=${queryCount} failed_queries=${failedQueries} exit_code=${process.exitCode || 0}`);
}
