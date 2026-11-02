// FEJKAD SERVER. Spelet pratar med Supabase; har fangas varje sadant anrop i webblasaren
// och besvaras med sma filer ur tests/fixtures/. Ingenting gar ut pa natet och inga nycklar behovs.
//
//   fixtures/tables/<tabell>.json   svar pa GET /rest/v1/<tabell>      (saknas filen: tom lista [])
//   fixtures/rpc/<funktion>.json    svar pa POST /rest/v1/rpc/<funktion> (saknas filen: null)
//   En .mjs-fil i stallet for .json far exportera en funktion (anrop) => svar, for data som raknas fram.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const FIX = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', 'fixtures');
const SUPA = /^https:\/\/[a-z0-9]+\.supabase\.co\//;

export const CHAR_ID = '00000000-0000-4000-8000-0000000000c1';
export const USER = { id: '00000000-0000-4000-8000-0000000000a1', email: 'testrunner@example.test', aud: 'authenticated', role: 'authenticated' };

const cache = new Map();
async function loadFixture(kind, name) {
  const key = kind + '/' + name;
  if (cache.has(key)) return cache.get(key);
  let val = undefined;
  const json = path.join(FIX, kind, name + '.json');
  const mjs = path.join(FIX, kind, name + '.mjs');
  if (fs.existsSync(mjs)) val = (await import(pathToFileURL(mjs).href)).default;
  else if (fs.existsSync(json)) val = JSON.parse(fs.readFileSync(json, 'utf8'));
  cache.set(key, val);
  return val;
}

/**
 * Kopplar in den fejkade servern i en webblasarkontext.
 * Returnerar en logg: vilka anrop som gjordes, och felrapporter spelet sjalv forsokte skicka.
 */
export async function installFakeServer(context) {
  const log = { calls: [], unknown: new Set(), errorReports: [], external: new Set() };

  // 1) En sparad inloggning, sa spelet gar rakt in pa testkaraktaren utan inloggningsrutan.
  await context.addInitScript(({ user, charId }) => {
    if (location.protocol !== 'http:') return;
    try {
      localStorage.setItem('genesis.session', JSON.stringify({
        token: 'test-token', refresh: 'test-refresh', expires: Date.now() + 864e5,
        user, charId, charName: 'Testrunner'
      }));
      // Integritetsraden langst ned ar redan godkand (annars ligger den over knapparna).
      localStorage.setItem('genesis.privacy', '99');
      localStorage.setItem('genesis.terms', '99');
    } catch (e) {}
  }, { user: USER, charId: CHAR_ID });

  // 2) Allt som inte ar var egen testserver eller Supabase stoppas (t.ex. Google Fonts).
  await context.route(url => !/^http:\/\/127\.0\.0\.1[:/]/.test(url.href) && !SUPA.test(url.href) && /^https?:/.test(url.href), route => {
    const u = new URL(route.request().url());
    log.external.add(u.host);
    if (/fonts\.googleapis\.com$/.test(u.host)) return route.fulfill({ status: 200, contentType: 'text/css', body: '' });
    return route.abort();
  });

  // 3) Supabase: REST, RPC, inloggning, funktioner.
  await context.route(SUPA, async route => {
    const req = route.request();
    const u = new URL(req.url());
    const p = u.pathname;
    let body = null;
    try { body = req.postDataJSON(); } catch (e) {}
    const call = { method: req.method(), path: p, query: u.search, body };
    log.calls.push(call);
    const svara = (data, status = 200) => route.fulfill({
      status, contentType: 'application/json',
      headers: { 'access-control-allow-origin': '*', date: new Date().toUTCString() },
      body: JSON.stringify(data),
    });
    if (req.method() === 'OPTIONS') return route.fulfill({ status: 204, headers: {
      'access-control-allow-origin': '*', 'access-control-allow-headers': '*', 'access-control-allow-methods': '*' } });

    if (p.startsWith('/auth/v1/token')) return svara({ access_token: 'test-token', refresh_token: 'test-refresh', expires_in: 86400, token_type: 'bearer', user: USER });
    if (p === '/auth/v1/user') return svara(USER);
    if (p.startsWith('/auth/v1/')) return svara({});
    if (p.startsWith('/functions/v1/')) return svara({});

    let m = /^\/rest\/v1\/rpc\/([\w]+)$/.exec(p);
    if (m) {
      const fn = m[1];
      if (fn === 'client_error_report') { log.errorReports.push(body); return svara(null); }
      const fx = await loadFixture('rpc', fn);
      if (fx === undefined) { log.unknown.add('rpc/' + fn); return svara(null); }
      return svara(typeof fx === 'function' ? await fx(call) : fx);
    }
    m = /^\/rest\/v1\/([\w]+)$/.exec(p);
    if (m) {
      const fx = await loadFixture('tables', m[1]);
      if (req.method() !== 'GET') return svara(null);
      if (fx === undefined) { log.unknown.add('tables/' + m[1]); return svara([]); }
      return svara(typeof fx === 'function' ? await fx(call) : fx);
    }
    log.unknown.add(req.method() + ' ' + p);
    return svara(null, 404);
  });

  // 4) Chattens realtidsuppkoppling (websocket): tas emot har och far ett "ok" tillbaka, men ingenting mer.
  await context.routeWebSocket(/^wss:\/\/[a-z0-9]+\.supabase\.co\//, ws => {
    ws.onMessage(msg => {
      try {
        const d = JSON.parse(String(msg));
        if (d && d.ref) ws.send(JSON.stringify({ topic: d.topic, event: 'phx_reply', ref: d.ref, payload: { status: 'ok', response: {} } }));
      } catch (e) {}
    });
  });

  return log;
}
