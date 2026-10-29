#!/usr/bin/env node
/* [TILLAGT v5.1353.0] MATNING AV 3D-KARTAN I SPELET (VARLDEN).
   Startar en lokal webbserver pa repot, oppnar index.html i Playwright utan server (Supabase blockeras),
   lyfter spelet forbi inloggningen med ett pahittat lage (drakemark / Gnome Square, ett mote, ett uppdrag),
   valjer 3D-kartan, matar in laddsasspelare, en pratbubbla och trycker pa ett mote - och tar skarmbilder pa
   sex bredder. Skriver JS-fel (bada dokumenten) och eventuellt vagratt spill.
   Kor:  node .claude/tools/measure-varld.js            (bilder i docs-world/live-*.jpg) */
const {chromium} = require('playwright');
const http = require('http'), fs = require('fs'), path = require('path');
const ROOT = path.resolve(__dirname, '..', '..');
const MIME = {html: 'text/html', js: 'text/javascript', mjs: 'text/javascript', json: 'application/json', webp: 'image/webp', png: 'image/png', jpg: 'image/jpeg',
  glb: 'model/gltf-binary', css: 'text/css', woff2: 'font/woff2', svg: 'image/svg+xml', txt: 'text/plain'};
const srv = http.createServer((req, res) => {
  const p = path.join(ROOT, decodeURIComponent(req.url.split('?')[0]).replace(/^\/+/, '') || 'index.html');
  if (!p.startsWith(ROOT) || !fs.existsSync(p) || fs.statSync(p).isDirectory()){ res.writeHead(404); res.end(); return; }
  res.writeHead(200, {'Content-Type': MIME[path.extname(p).slice(1)] || 'application/octet-stream'});
  /* Spelet ligger i en sluten funktion ('use strict'). BARA HAR, i matningen, far sidan en liten lucka (window.__eval)
     sa provkorningen kan satta laget innanfor. Filen i repot rors inte. */
  if (p.endsWith('index.html')){ res.end(fs.readFileSync(p, 'utf8').replace("'use strict';", "'use strict'; window.__eval = (s) => eval(s);")); return; }
  fs.createReadStream(p).pipe(res);
});
const SIZES = [[1920, 1080], [1440, 900], [1280, 800], [820, 1180], [390, 844], [360, 740]];
const OUT = path.join(ROOT, 'docs-world');
const SETUP = String(() => {
  S.world.current = 'drakemark'; S.world.zone = 'Gnome Square';
  ['known', 'visited'].forEach(k => { if (!S.world[k].includes('drakemark')) S.world[k].push('drakemark'); });
  ['Gnome Square', 'Troll Mire', 'Sand Valley', 'The Black Keep'].forEach(z => { const k = 'drakemark|' + z; if (!S.world.zonesSeen.includes(k)) S.world.zonesSeen.push(k); });
  S.classId = 'warden'; S.xp = 2600; SRV.charName = 'Whippen';
  NET.on = true; NET.worldSynced = true;
  document.getElementById('gate').classList.add('done'); document.documentElement.classList.remove('gate-resuming');
  PVE.encs = [{id: 'e1', region: 'drakemark', zone: 'Gnome Square', key: 'dra_gadget_chief', name: 'Gadget Chief', type_name: 'Construct', ptype: 'construct', level: 12, rating: 'normal', elite: false, shape: '', blurb: 'A gnome boss with too many gadgets.', enemy_hp: 900, enemy_atk: 40},
    {id: 'e2', region: 'drakemark', zone: 'Troll Mire', key: 'dra_fuse_bomber', name: 'Fuse Bomber', type_name: 'Humanoid', level: 13, rating: 'hard', elite: true, shape: 'glass cannon', blurb: 'Boom.', enemy_hp: 700, enemy_atk: 60}];
  QUESTS.state = {offers: [{quest_id: 101, status: 'offered', region: 'drakemark', zone: 'Gnome Square', name: 'Catch a Runaway Invention', giver: 'Mara', giver_role: 'Tinker', template: 'dm_mara_01', kind: 'pve_wins', qty: 3, progress: 0, flavor: 'It went that way!', reward: {xp: 200, gold: 150, rep: 10, frags: 2}},
      {quest_id: 102, status: 'offered', region: 'drakemark', zone: 'Troll Mire', name: 'Pay the Crossing Toll', giver: 'Nilo', giver_role: 'Toll keeper', template: 'dm_nilo_01', kind: 'pve_wins', qty: 2, progress: 0, flavor: 'Coin first.', reward: {xp: 150, gold: 90, rep: 5, frags: 1}}],
    active: [{quest_id: 103, status: 'active', region: 'drakemark', zone: 'Sand Valley', name: 'Bones in the Dunes', giver: 'Rian', giver_role: 'Scout', template: 'dm_rian_01', kind: 'pve_wins', qty: 3, progress: 3, done: true, flavor: 'Bring them back.', reward: {xp: 300, gold: 120, rep: 8, frags: 2}},
      {quest_id: 104, status: 'active', region: 'drakemark', zone: 'The Black Keep', name: 'Siege Supplies', giver: 'Tass', giver_role: 'Quartermaster', template: 'dm_tass_01', kind: 'pve_wins', qty: 5, progress: 1, done: false, flavor: 'Hurry.', reward: {xp: 300, gold: 120, rep: 8, frags: 2}}],
    max_active: 3, gear_chance: .25};
  VEIN.st = {profs: ['mining'], spots: [{prof: 'mining', slot: 1, region: 'drakemark', zone: 'Gnome Square', ore: 'iron', qty: 3, until: new Date(Date.now() + 3600000).toISOString(), busy: false},
    {prof: 'mining', slot: 2, region: 'drakemark', zone: 'Gnome Square', ore: 'copper', qty: 2, until: new Date(Date.now() + 3600000).toISOString(), busy: false}], daily: {}, cap: 20};
  try { localStorage.setItem('genesis.map3d', '1'); } catch (e){}
  gmLoad(); redrawAll(); setTimeout(() => { try { veinPush(); } catch (e){} }, 2500);
}).replace(/^\(\) => \{/, '').replace(/\}$/, '');
const LIVE = () => [{id: 'p1', name: 'Zylnock', x: 0, y: 0, face: 1, zone: 'Gnome Square', klass: 'breaker', niva: 14, helper: {key: 'bit', namn: 'Bit'}, mv: true},
  {id: 'p2', name: 'Morla', x: 0, y: 0, face: 2, zone: 'Gnome Square', klass: 'fabricator', niva: 12, helper: null, mv: false},
  {id: 'p3', name: 'Kesra', x: 0, y: 0, face: 3, zone: 'Troll Mire', klass: 'runner', niva: 17, helper: null, mv: true}];
(async () => {
  await new Promise(r => srv.listen(0, '127.0.0.1', r));
  const port = srv.address().port, base = 'http://127.0.0.1:' + port + '/';
  const browser = await chromium.launch({args: ['--use-gl=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist']});
  const report = [];
  for (const [w, h] of SIZES){
    const mobile = w < 760;
    const ctx = await browser.newContext({viewport: {width: w, height: h}, deviceScaleFactor: 1, hasTouch: mobile, isMobile: mobile, userAgent: mobile ? 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1' : undefined});
    await ctx.route('**/*.supabase.co/**', r => r.abort());
    const page = await ctx.newPage();
    const errs = [];
    page.on('pageerror', e => errs.push('pageerror: ' + e.message));
    page.on('console', m => { if (m.type() === 'error' && !/404/.test(m.text())) errs.push('console: ' + m.text()); });
    page.on('response', r => { if (r.status() === 404) errs.push('404: ' + r.url().replace(base, '')); });
    await page.goto(base + 'index.html', {waitUntil: 'load'});
    await page.evaluate(src => window.__eval(src), SETUP);
    const frame = await (async () => { for (let i = 0; i < 100; i++){ const f = page.frames().find(f => /genesis-3d/.test(f.url())); if (f) return f; await page.waitForTimeout(200); } return null; })();
    if (!frame){ report.push({w, h, err: 'ingen 3D-ram'}); await ctx.close(); continue; }
    await frame.waitForFunction(() => window.__gw && window.__gw.ready && window.__gw.me.R, null, {timeout: 60000}).catch(() => {});
    await page.waitForTimeout(1200);
    const tag = w + 'x' + h;
    const shot = (name) => page.screenshot({path: path.join(OUT, 'live-' + name + '-' + tag + '.jpg'), type: 'jpeg', quality: 80});
    await frame.evaluate(() => window.__gw.API.setMe({namn: 'Whippen', klass: 'warden', niva: 14, helper: {key: 'bit', namn: 'Bit'}}));
    if (mobile){ await page.click('#map-fs-open').catch(() => {}); await page.waitForTimeout(800); }
    /* 1) regionvyn med min figur */
    await shot('1-region');
    /* 2) realtidsspelare: tre figurer i min region, placerade intill mig */
    await frame.evaluate((live) => { const me = window.__gw.me; const o = [[40, 10], [-30, 28], [60, -40]];
      live.forEach((p, i) => { p.x = Math.round(me.x + o[i][0]); p.y = Math.round(me.y + o[i][1]); }); window.__gw.API.setLive(live); }, LIVE());
    await page.waitForTimeout(1500);
    await frame.evaluate((live) => { const me = window.__gw.me; const o = [[52, 22], [-30, 28], [60, -40]];
      live.forEach((p, i) => { p.x = Math.round(me.x + o[i][0]); p.y = Math.round(me.y + o[i][1]); }); window.__gw.API.setLive(live); }, LIVE());
    await page.waitForTimeout(900);
    await shot('2-realtid');
    /* 3) pratbubbla fran zonchatten */
    await frame.evaluate(() => { window.__gw.API.bubble({id: 'p1', name: 'Zylnock', text: 'Anyone up for the Black Keep?'}); window.__gw.API.bubble({me: true, text: 'On my way!'}); });
    await page.waitForTimeout(500);
    await shot('3-bubbla');
    /* 4) uppdragsmarken: zooma ut lite sa flera zoner syns */
    const poiInfo = await frame.evaluate(() => { const g = window.__gw; const q = g.pois.filter(p => p.kind === 'quest'); const z = g.REG_BY.drakemark;
      g.flyTo({tx: (z.bb.x0 + z.bb.x1) / 2 * g.K, tz: (z.bb.y0 + z.bb.y1) / 2 * g.K + 2, dist: 120}, 50);
      return q.map(p => p.label + ' ' + p.mark + (p.grey ? ' grey' : '')); });
    await page.waitForTimeout(900);
    await shot('4-quests');
    /* 5) tryck pa motet: spelets Encounter-ruta direkt + figuren gar */
    await frame.evaluate(() => { const g = window.__gw; g.flyTo({tx: g.me.x * g.K, tz: g.me.y * g.K + 1, dist: 50}, 50); });
    await page.waitForTimeout(700);
    const enc = await frame.evaluate(() => { const g = window.__gw; const p = g.pois.find(p => p.kind === 'encounter' && p.zn === 'Gnome Square'); if (!p) return null; g.onPoi(p); return {label: p.label, walking: g.me.path.length > 0}; });
    await page.waitForTimeout(700);
    const encOpen = await page.evaluate(() => { const o = document.getElementById('node-overlay'); return !!(o && o.classList.contains('open')) && /Hostile sighted/i.test(document.getElementById('node-body').textContent); });
    await shot('5-encounter');
    await page.evaluate(() => window.__eval('try { closeNodeWin(); } catch (e){}'));
    /* 6) vein: trycket startar matarne (utan server: vein_start misslyckas -> say), vi kollar bara att veinClick anropas */
    const vein = await frame.evaluate(() => { const g = window.__gw; const p = g.pois.find(p => p.kind === 'vein'); if (!p) return null; let got = null; const old = g.API.onPick; g.API.onPick = o => { got = o; old(o); }; g.onPoi(p); g.API.onPick = old; return got; });
    await page.waitForTimeout(300);
    await shot('6-vein');
    const spill = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
    const fps = await frame.evaluate(() => Math.round(window.__gw.fps()));
    const ents = await frame.evaluate(() => [...window.__gw.ents.values()].map(e => e.namn + ':' + (e.av ? 'av' : '-') + (e.hlp ? '+hlp' : '') + ':' + Math.round(e.x) + ',' + Math.round(e.y)).join(' | ') + ' me:' + Math.round(window.__gw.me.x) + ',' + Math.round(window.__gw.me.y) + (window.__gw.me.hlp && window.__gw.me.hlp.obj ? ' hlp:' + window.__gw.me.hlp.kind : ' nohlp'));
    report.push({w, h, spill, fps, ents, quests: poiInfo, enc, encOpen, vein: vein && vein.kind + ' ' + vein.id + ' @' + Math.round(vein.clientX) + ',' + Math.round(vein.clientY), errs});
    await ctx.close();
  }
  await browser.close(); srv.close();
  console.log(JSON.stringify(report, null, 1));
})().catch(e => { console.error(e); process.exit(1); });
