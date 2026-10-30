#!/usr/bin/env node
/* [TILLAGT v5.1371.0] NEON-MATNING OCH BILDGALLERI (VARLDEN, ny look). Bygger pa measure-varld.js (samma server och samma pahittade lage).
   Kor:  node .claude/tools/measure-neon.js [prefix]      prefix 'fore' = bilder av nuvarande look (fore), annars 'neon'.
   1) Sex bredder: JS-fel, vagratt spill, 3D laddad, tryck pa mote -> spelets Encounter-ruta, hjalpare synlig, bildfrekvens, bloom pa/av.
   2) Galleri pa 1440x900 (+ mobil 390): oversikt, varje region, natt, hjalpare narbild -> docs-world/<prefix>-*.jpg
   --- nedan: forsta delen kopierad fran measure-varld.js --- */
/* (fran measure-varld.js) MATNING AV 3D-KARTAN I SPELET (VARLDEN).
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

const PFX = process.argv[2] || 'neon';
const HELPERS = ['bloom', 'kage', 'ember', 'morrow', 'prism', 'scuba'];
async function open(browser, base, w, h, glow){
  const mobile = w < 760;
  const ctx = await browser.newContext({viewport: {width: w, height: h}, deviceScaleFactor: 1, hasTouch: mobile, isMobile: mobile, userAgent: mobile ? 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1' : undefined});
  await ctx.route('**/*.supabase.co/**', r => r.abort());
  const page = await ctx.newPage(), errs = [];
  page.on('pageerror', e => errs.push('pageerror: ' + e.message));
  page.on('console', m => { if (m.type() === 'error' && !/404|ERR_FAILED|Failed to load resource/.test(m.text())) errs.push('console: ' + m.text()); });
  page.on('response', r => { if (r.status() === 404) errs.push('404: ' + r.url().replace(base, '')); });
  const glb = []; page.on('request', r => { if (/helpers3d\/.*\.glb|assets\/pets\//.test(r.url())) glb.push(r.url().split('/').pop()); });
  await page.goto(base + 'index.html', {waitUntil: 'load'});
  /* galleriet: glodet tvingas pa (programvaru-WebGL i matningen ar for langsam for auto-laget, som annars stanger av det) */
  await page.evaluate(g => { try { if (g) localStorage.setItem('genesis.map3dGlow', g); else localStorage.removeItem('genesis.map3dGlow'); } catch (e){} }, glow || null);
  await page.evaluate(src => window.__eval(src), SETUP);
  let frame = null; for (let i = 0; i < 100 && !frame; i++){ frame = page.frames().find(f => /genesis-3d/.test(f.url())); if (!frame) await page.waitForTimeout(200); }
  if (frame) await frame.waitForFunction(() => window.__gw && window.__gw.ready && window.__gw.me.R, null, {timeout: 90000}).catch(() => {});
  await page.waitForTimeout(1200);
  if (frame) await frame.evaluate(() => window.__gw.API.setMe({namn: 'Whippen', klass: 'warden', niva: 14, helper: {key: 'bloom', namn: 'Bloom'}}));
  if (mobile){ await page.click('#map-fs-open').catch(() => {}); await page.waitForTimeout(800); }
  return {ctx, page, frame, errs, glb, mobile};
}
const shotP = (page, name) => page.screenshot({path: path.join(OUT, PFX + '-' + name + '.jpg'), type: 'jpeg', quality: 82});
(async () => {
  await new Promise(r => srv.listen(0, '127.0.0.1', r));
  const port = srv.address().port, base = 'http://127.0.0.1:' + port + '/';
  const browser = await chromium.launch({args: ['--use-gl=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist']});
  const report = [];
  /* 1) sex bredder */
  for (const [w, h] of (process.env.GALLERY_ONLY ? [] : SIZES)){
    const {ctx, page, frame, errs, glb} = await open(browser, base, w, h);
    if (!frame){ report.push({w, h, err: 'ingen 3D-ram'}); await ctx.close(); continue; }
    await frame.evaluate(() => { const g = window.__gw; g.flyTo({tx: g.me.x * g.K, tz: g.me.y * g.K + 1, dist: 30}, 50); });
    await page.waitForTimeout(1500);
    await frame.waitForFunction(() => { const H = window.__gw.me.hlp; return H && H.obj && H.obj.visible; }, null, {timeout: 15000}).catch(() => {});
    const hlp = await frame.evaluate(() => { const H = window.__gw.me.hlp; return H && H.obj ? H.kind + (H.obj.visible ? ' synlig' : ' dold') : 'ingen'; });
    const enc = await frame.evaluate(() => { const g = window.__gw; const p = g.pois.find(p => p.kind === 'encounter' && p.zn === 'Gnome Square'); if (!p) return null; g.onPoi(p); return p.label; });
    await page.waitForTimeout(700);
    const encOpen = await page.evaluate(() => { const o = document.getElementById('node-overlay'); return !!(o && o.classList.contains('open')); });
    await page.evaluate(() => window.__eval('try { closeNodeWin(); } catch (e){}'));
    const spill = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
    await page.waitForTimeout(2500);
    const fx = await frame.evaluate(() => ({fps: Math.round(window.__gw.fps()), fx: window.__gw.fx ? window.__gw.fx() : null}));
    report.push({w, h, spill, encounter: enc, encOpen, hjalpare: hlp, hamtat: [...new Set(glb)], ...fx, errs});
    await ctx.close();
  }
  /* 2) galleri */
  if (!process.env.NO_GALLERY){
    const {ctx, page, frame, errs} = await open(browser, base, 1440, 900, PFX === 'fore' ? null : 'on');
    const g = (fn, a) => frame.evaluate(fn, a);
    /* kartan i helskarm aven pa dator (samma knapp som "Open map" pa telefon) sa bilderna visar varlden stort */
    await page.addStyleTag({content: '#panel-network-map{position:fixed!important;inset:0!important;z-index:99999!important;margin:0!important;max-width:none!important;width:100vw!important;height:100vh!important}' +
      '#panel-network-map #map-frame{position:absolute!important;inset:0!important;width:100%!important;height:100%!important}'});
    await page.evaluate(() => window.dispatchEvent(new Event('resize'))); await page.waitForTimeout(800);
    await g(() => window.__gwTid = 13);
    await g(() => { window.__gw.unfollow(); window.__gw.overview(50); }); await page.waitForTimeout(1500); await shotP(page, 'oversikt');
    for (const id of ['voxholm', 'drakemark', 'cutlassbay', 'novacommand', 'quarantine']){
      await g(id => { window.__gw.unfollow(); window.__gw.focusRegion(window.__gw.REG_BY[id], 50); }, id); await page.waitForTimeout(1600); await shotP(page, 'region-' + id); }
    await g(() => { const w = window.__gw; w.flyTo({tx: w.me.x * w.K, tz: w.me.y * w.K + 1, dist: 60}, 50); }); await page.waitForTimeout(1200); await shotP(page, 'dag');
    await g(() => window.__gwTid = 23); await page.waitForTimeout(1200); await shotP(page, 'natt');
    await g(() => { window.__gw.unfollow(); window.__gw.overview(50); }); await page.waitForTimeout(1500); await shotP(page, 'natt-oversikt');
    await g(() => window.__gwTid = 13);
    /* hjalpare narbild: min (bloom) + fem andra spelare med var sin hjalpare, i en ring kring mig */
    await g((H) => { const w = window.__gw, me = w.me; w.API.setLive(H.slice(1).map((k, i) => ({id: 'h' + i, name: ['Zylnock', 'Morla', 'Kesra', 'Toma', 'Ilse'][i], x: Math.round(me.x + Math.cos(i * 1.25 + .4) * 52), y: Math.round(me.y + Math.sin(i * 1.25 + .4) * 30 + 6),
      face: 0, zone: 'Gnome Square', klass: ['breaker', 'fabricator', 'runner', 'warden', 'breaker'][i], niva: 14, helper: {key: k, namn: k[0].toUpperCase() + k.slice(1)}, mv: false}))); }, HELPERS);
    await page.waitForTimeout(3500);
    await g(() => { const w = window.__gw; w.flyTo({tx: w.me.x * w.K, tz: w.me.y * w.K + 1.2, dist: 17}, 50); }); await page.waitForTimeout(2000); await shotP(page, 'hjalpare');
    /* 2D-kartan som jamforelse */
    await page.evaluate(() => window.genesisMapSwitch && window.genesisMapSwitch('2d')); await page.waitForTimeout(3000); if (PFX !== 'fore') await shotP(page, '2d-jamforelse');
    report.push({galleri: '1440', errs});
    await ctx.close();
    const m = await open(browser, base, 390, 844, PFX === 'fore' ? null : 'on');
    if (m.frame){ await m.frame.evaluate(() => window.__gwTid = 13); await m.page.waitForTimeout(1500); await shotP(m.page, 'mobil-390');
      await m.frame.evaluate(() => window.__gwTid = 23); await m.page.waitForTimeout(1200); await shotP(m.page, 'mobil-390-natt'); }
    report.push({galleri: '390', errs: m.errs, fx: m.frame && await m.frame.evaluate(() => window.__gw.fx ? window.__gw.fx() : null)});
    await m.ctx.close();
  }
  await browser.close(); srv.close();
  console.log(JSON.stringify(report, null, 1));
})().catch(e => { console.error(e); process.exit(1); });
