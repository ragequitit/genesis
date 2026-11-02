// WINDFALL: testkontot ser den oslappta regionen (regions_visible). Spelet startas med fejkad server med Pinguus lage i Windfall.
// Sa provas regionen i spelet utan att nagot ligger pa riktiga servern.
import { test, expect } from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { installFakeServer } from '../helpers/fake-server.mjs';

const FIX = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', 'fixtures', 'tables');
const ALLA = ['voxholm', 'drakemark', 'cutlassbay', 'novacommand', 'quarantine', 'windfall'];
const json = (route, data) => route.fulfill({ status: 200, contentType: 'application/json', headers: { 'access-control-allow-origin': '*' }, body: JSON.stringify(data) });

async function startaIWindfall(page, context, syns = true) {
  const log = await installFakeServer(context);
  await context.route('**/rest/v1/rpc/regions_visible', r => json(r, syns ? ALLA : ALLA.slice(0, 5)));
  if (syns) {
    await context.route('**/rest/v1/characters?*', r => {
      const rad = JSON.parse(fs.readFileSync(path.join(FIX, 'characters.json'), 'utf8'))[0];
      json(r, [{ ...rad, region: 'windfall', zone: 'Dawnmeadow', xp: 3e8 }]);
    });
    await context.route('**/rest/v1/character_regions?*', r => json(r, ALLA.map(region => ({ character_id: rad_id, region, known_at: new Date(0).toISOString(), visited_at: new Date(0).toISOString(), rep_secs: 0 }))));
  }
  const fel = [];
  page.on('pageerror', e => fel.push('JS-fel: ' + (e.stack || e.message).split('\n').slice(0, 3).join(' | ')));
  page.on('console', m => { if (m.type() === 'error') fel.push('console.error: ' + m.text().slice(0, 300)); });
  page.on('response', r => { if (r.status() >= 400 && /^http:\/\/127\.0\.0\.1[:/]/.test(r.url())) fel.push(`HTTP ${r.status()}: ${r.url().replace(/^http:\/\/127\.0\.0\.1:\d+/, '')}`); });
  await page.goto('/index.html');
  await expect(page.locator('#gate')).toHaveClass(/\bdone\b/, { timeout: 30_000 });
  await page.waitForFunction(() => { const f = document.getElementById('map-frame'); return f && f.contentDocument && f.contentDocument.readyState === 'complete'; }, null, { timeout: 30_000 });
  await page.waitForTimeout(2000);
  return { log, fel: () => [...fel, ...log.errorReports.map(r => 'spelets felrapport: ' + JSON.stringify(r).slice(0, 300))] };
}
const rad_id = '00000000-0000-4000-8000-0000000000c1';

test('Windfall: testkontot star i regionen utan fel, och kartans zoner och tavlan syns', async ({ page, context }, info) => {
  const spel = await startaIWindfall(page, context);
  const karta = page.frames().find(f => /genesis-map\.html/.test(f.url()));
  expect(karta, 'kartan ar laddad').toBeTruthy();
  const text = () => karta.evaluate(() => document.body.innerText);
  await expect.poll(text, { timeout: 15_000 }).toMatch(/WINDFALL/i);
  await expect.poll(text, { timeout: 15_000 }).toMatch(/DAWNMEADOW/i);
  // Rosa noden Missions finns pa The Landing (kartans farg #f472b6), precis som i de andra regionerna.
  const rosa = await karta.evaluate(() => [...document.querySelectorAll('rect, circle, ellipse, polygon, path')].filter(e => (e.getAttribute('fill') || '').toLowerCase() === '#f472b6').length);
  expect(rosa, 'markoren for uppdragstavlan').toBeGreaterThan(0);
  const sw = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
  expect(sw, 'horisontellt overflow').toBeLessThanOrEqual(1);
  await page.screenshot({ path: info.outputPath('windfall.png') });
  fs.mkdirSync(path.resolve(FIX, '..', '..', 'test-results'), { recursive: true });
  await page.screenshot({ path: path.resolve(FIX, '..', '..', 'test-results', `windfall-${page.viewportSize().width}.png`) });
  expect(spel.fel()).toEqual([]);
});

test('Windfall: vanlig spelare ser den inte', async ({ page, context }) => {
  const spel = await startaIWindfall(page, context, false);
  const karta = page.frames().find(f => /genesis-map\.html/.test(f.url()));
  // Kartan far inte fa regionen i sitt lage (den visas last/gra) och spelet har inte kvar den.
  const zoner = await karta.evaluate(() => document.body.innerText);
  expect(zoner).not.toMatch(/DAWNMEADOW/i);
  expect(spel.fel()).toEqual([]);
});
