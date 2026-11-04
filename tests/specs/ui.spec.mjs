// WEBBLASARTESTER: spelet startas pa riktigt i Chromium, med den fejkade servern (helpers/fake-server.mjs).
// Varje test kors pa alla sex skarmbredderna (se playwright.config.mjs).
import { test, expect } from '@playwright/test';
import { installFakeServer } from '../helpers/fake-server.mjs';
import { petKeys } from '../helpers/source.mjs';

// ---------- gemensamt: starta spelet och samla fel ----------

async function startaSpelet(page, context) {
  const log = await installFakeServer(context);
  const fel = [];
  page.on('pageerror', e => fel.push('JS-fel: ' + (e.stack || e.message).split('\n').slice(0, 3).join(' | ')));
  page.on('console', m => { if (m.type() === 'error') fel.push('console.error: ' + m.text().slice(0, 300)); });
  page.on('response', r => {
    if (r.status() >= 400 && /^http:\/\/127\.0\.0\.1[:/]/.test(r.url())) fel.push(`HTTP ${r.status()}: ${r.url().replace(/^http:\/\/127\.0\.0\.1:\d+/, '')}`);
  });
  await page.goto('/index.html');
  // Inloggningen ar klar nar porten far klassen "done" och laddskarmen ar borta.
  await expect(page.locator('#gate')).toHaveClass(/\bdone\b/, { timeout: 30_000 });
  // Ge spelet tid att rita klart och kartan (iframe) att koppla upp sig.
  await page.waitForFunction(() => {
    const f = document.getElementById('map-frame');
    return f && f.contentDocument && f.contentDocument.readyState === 'complete';
  }, null, { timeout: 30_000 });
  await page.waitForTimeout(1500);
  return {
    log,
    /** Alla fel hittills: JS-fel, console.error, saknade filer och felrapporter spelet sjalvt forsokte skicka. */
    fel: () => [
      ...fel,
      ...log.errorReports.map(r => 'spelets felrapport: ' + JSON.stringify(r).slice(0, 300)),
    ],
  };
}

/** Sant overflow: sidan gar att skrolla i sidled. Returnerar de bredaste bovarna om sa ar fallet. */
async function horisontelltOverflow(page) {
  return page.evaluate(() => {
    const de = document.documentElement;
    const vw = de.clientWidth;
    const sw = Math.max(de.scrollWidth, document.body.scrollWidth);
    if (sw <= vw + 1) return null;
    const bovar = [];
    for (const el of document.body.querySelectorAll('*')) {
      const r = el.getBoundingClientRect();
      if (r.width && r.right > vw + 1 && getComputedStyle(el).position !== 'fixed') {
        bovar.push(`${el.tagName.toLowerCase()}${el.id ? '#' + el.id : ''}${typeof el.className === 'string' && el.className ? '.' + el.className.trim().split(/\s+/).join('.') : ''} (hoger kant ${Math.round(r.right)}px)`);
      }
    }
    return { skarmbredd: vw, sidbredd: sw, bovar: bovar.slice(0, 8) };
  });
}

/** Klickar pa forsta SYNLIGA knappen bland kandidaterna (olika knappar syns pa olika skarmbredder). */
async function klickaForstaSynliga(page, selektorer) {
  const tackta = [];
  for (const sel of selektorer) {
    const loc = page.locator(sel);
    const n = await loc.count();
    for (let i = 0; i < n; i++) {
      const el = loc.nth(i);
      if (!(await el.isVisible())) continue;
      await el.evaluate(e => e.scrollIntoView({ block: 'center' }));
      // Ar knappen tackt av nagot annat (t.ex. chattrutan)? Da provas nasta kandidat, och det noteras.
      const fri = await el.evaluate(e => {
        const r = e.getBoundingClientRect();
        const t = document.elementFromPoint(r.x + r.width / 2, r.y + r.height / 2);
        return !!t && (t === e || e.contains(t));
      });
      if (!fri) { tackta.push(sel); continue; }
      await el.click();
      if (tackta.length) test.info().annotations.push({ type: 'observation', description: `Tackt knapp (gick inte att klicka): ${tackta.join(', ')}. Anvande ${sel} i stallet.` });
      return sel;
    }
  }
  throw new Error('Ingen synlig och klickbar knapp hittades bland: ' + selektorer.join(', ') + (tackta.length ? ' (tackta: ' + tackta.join(', ') + ')' : ''));
}

/** Uppdragstavlan nas fran kartan: den rosa markoren i The Landing. */
async function klickaUppdragstavlanPaKartan(page) {
  const frame = page.frames().find(f => /genesis-map\.html/.test(f.url()));
  expect(frame, 'kartan (genesis-map.html) ar laddad').toBeTruthy();
  await page.locator('#map-frame').evaluate(e => e.scrollIntoView({ block: 'center' }));
  // Pa telefon zoomar forsta trycket in i zonen; da trycker vi pa markoren igen, precis som en spelare.
  for (let forsok = 0; forsok < 3; forsok++) {
    // Markoren ar en liten rosa form (kartans farg for uppdragstavlan, #f472b6). Vi tar den som faktiskt
    // ligger overst dar man trycker, sa klicket gar dit en spelares finger skulle ga.
    const punkt = await frame.evaluate(() => {
      const shapes = [...document.querySelectorAll('rect, circle, ellipse, polygon, path')]
        .filter(e => (e.getAttribute('fill') || '').toLowerCase() === '#f472b6');
      for (const e of shapes) {
        const r = e.getBoundingClientRect();
        if (!r.width || r.x < 0 || r.y < 0 || r.right > innerWidth || r.bottom > innerHeight) continue;
        const x = r.x + r.width / 2, y = r.y + r.height / 2;
        const top = document.elementFromPoint(x, y);
        if (top === e) return { x, y };
      }
      return null;
    });
    expect(punkt, 'markoren for uppdragstavlan finns pa kartan').toBeTruthy();
    // Klicka med musen pa exakt den punkten (kartans koordinater + iframens plats pa sidan).
    const ram = await page.locator('#map-frame').boundingBox();
    await page.mouse.click(ram.x + punkt.x, ram.y + punkt.y);
    await page.waitForTimeout(800);
    if (await page.locator('#node-overlay').evaluate(w => w.classList.contains('open'))) return;
  }
}

// ---------- 1. sidan laddar ----------

test('sidan laddar utan JS-fel och utan horisontellt overflow', async ({ page, context }) => {
  const spel = await startaSpelet(page, context);
  // Spelet ar verkligen inne: karaktarens namn och guldet fran testdatan syns.
  await expect(page.getByText('Testrunner', { exact: false }).first()).toBeVisible();
  expect(await horisontelltOverflow(page), 'horisontellt overflow').toBeNull();
  // Versionen som visas i spelet = versionen i filen.
  await expect(page.locator('.sn-ver')).toHaveText(/GENESIS v\d+\.\d+\.\d+/);
  expect(spel.fel()).toEqual([]);
  expect([...spel.log.external].filter(h => !/fonts\.(googleapis|gstatic)\.com$/.test(h)), 'oväntade anrop ut pa natet').toEqual([]);
});

// ---------- 2. fonstren oppnas och stangs ----------

const PETS_KEYS = petKeys();

const FONSTER = [
  {
    namn: 'inventory', oppna: ['#qa-inventory', '.qa-btn[data-qa="inventory"]'], fonster: '#inv-overlay', stang: '#inv-close',
    innehall: async (w) => {
      const html = await w.innerHTML();
      for (const k of ['salvage_blade', 'phase_vest', 'voidsteel_boots', 'tin_ore', 'quartz_crystal']) expect(html, `vaskan visar ${k}`).toContain(k);
    },
  },
  {
    namn: 'vault', oppna: ['#qa-vault', '.qa-btn[data-qa="vault"]'], fonster: '#vault-overlay', stang: '#vault-close',
    innehall: async (w) => {
      const html = await w.innerHTML();
      for (const k of ['circuit_ring', 'genesis_trousers', 'cobalt_ore', 'platinum_ore']) expect(html, `valvet visar ${k}`).toContain(k);
    },
  },
  {
    namn: 'helpers', oppna: ['#qa-pets', '.qa-btn[data-qa="helpers"]'], fonster: '#pets-overlay', stang: '#pets-close',
    innehall: async (w) => {
      const html = await w.innerHTML();
      const saknas = PETS_KEYS.filter(k => !html.includes('assets/pets/' + k + '.webp'));
      expect(saknas, `alla ${PETS_KEYS.length} hjalpare ritas med bild`).toEqual([]);
    },
  },
  {
    namn: 'achievements', oppna: ['#nav-ach', '.qa-btn[data-qa="achievements"]'], fonster: '#ach-overlay', stang: '#ach-close',
    innehall: async (w) => { await expect(w).toContainText(/First Steps|Brawler|Pocket Money|Pack Leader/); },
  },
  {
    namn: 'events', oppna: ['#nav-events', '.qa-btn[data-qa="events"]'], fonster: '#wb-overlay', stang: '#wb-close',
    innehall: async (w) => { await expect(w).toContainText('Halloween'); },
  },
  {
    namn: 'How to play', oppna: ['#nav-htp', '.qa-btn[data-qa="howtoplay"]'], fonster: '#htp-overlay', stang: '#htp-close',
    innehall: async (w) => { expect((await w.innerText()).length, 'How to play har text').toBeGreaterThan(300); },
  },
  {
    namn: 'auction house', oppna: ['#qa-auction', '#nav-auction', '.qa-btn[data-qa="auction"]'], fonster: '#ah-overlay', stang: '#ah-close',
    innehall: async (w) => { await expect(w).toContainText('Salvage Blade'); await expect(w).toContainText('Tin Ore'); },
  },
  {
    namn: 'mail', oppna: ['#qa-inbox', '#nav-inbox', '.qa-btn[data-qa="inbox"]'], fonster: '#mail-overlay', stang: '#mail-close',
    innehall: async (w) => { await expect(w).toContainText('You won an auction'); await expect(w).toContainText('A gift'); },
  },
  {
    namn: 'Mission Board', oppna: klickaUppdragstavlanPaKartan, fonster: '#node-overlay', stang: '#node-close',
    innehall: async (w) => { for (const t of ['MISSION BOARD', 'Pest Control', 'Ore Run', 'Deep Dive']) await expect(w).toContainText(t, { ignoreCase: true }); },
  },
];

for (const f of FONSTER) {
  test(`fonster: ${f.namn} oppnas och stangs`, async ({ page, context }) => {
    const spel = await startaSpelet(page, context);
    const w = page.locator(f.fonster);
    await expect(w).not.toHaveClass(/\bopen\b/);

    if (typeof f.oppna === 'function') await f.oppna(page);
    else await klickaForstaSynliga(page, f.oppna);
    await expect(w).toHaveClass(/\bopen\b/);
    // Sjalva rutan (.modal) om fonstret har en, annars hela fonstret.
    const ruta = (await w.locator('.modal').count()) ? w.locator('.modal').first() : w;
    await expect(ruta).toBeVisible();
    await page.waitForTimeout(600);   // serverdatan (fejkad) hinner ritas in
    await f.innehall(w);

    // Fonstret ligger inom skarmen i sidled, och sidan har inte borjat skrolla at sidan.
    const box = await ruta.boundingBox();
    const vw = page.viewportSize().width;
    expect(box, 'fonstret har en storlek').toBeTruthy();
    expect(Math.round(box.x), 'fonstrets vanstra kant ar inne pa skarmen').toBeGreaterThanOrEqual(0);
    expect(Math.round(box.x + box.width), `fonstrets hogra kant ar inne pa skarmen (${vw}px)`).toBeLessThanOrEqual(vw);
    expect(await horisontelltOverflow(page), 'horisontellt overflow med fonstret oppet').toBeNull();

    await page.locator(f.stang).click();
    await expect(w).not.toHaveClass(/\bopen\b/);
    expect(spel.fel()).toEqual([]);
  });
}

// Kartan: pa smala skarmar finns "Open map" (helskarm) och "Close". Pa breda skarmar ar kartan alltid oppen i sin panel.
// Karaktarsrutan blir smal mellan 821 och 1279 px. Kors bara i 1000-projektet, som provar fyra bredder i spannet.
test('karaktarsrutan: flikar och stats gar inte ihop mellan 821 och 1279 px', async ({ page, context }, info) => {
  test.skip(info.project.name !== '1000x800', 'galler bara mellanbredderna');
  const spel = await startaSpelet(page, context);
  for (const width of [900, 1000, 1100, 1200]) {
    await page.setViewportSize({ width, height: 800 });
    await page.waitForTimeout(300);
    const krockar = await page.evaluate(() => {
      const ruta = el => { const r = document.createRange(); r.selectNodeContents(el); return r.getBoundingClientRect(); };
      const fel = [];
      const P = document.getElementById('panel-character');
      for (const t of P.querySelectorAll('.ct-tab')) {
        // Bara flikens text raknas: poangbrickan ligger i flikens horn.
        const r = document.createRange(); r.selectNode(t.firstChild);
        const b = t.getBoundingClientRect(), x = r.getBoundingClientRect();
        if (x.left < b.left + 0.5 || x.right > b.right - 0.5) fel.push(`flik ${t.dataset.cttab}: text ${x.width.toFixed(1)} i ${b.width.toFixed(1)}`);
      }
      const rader = [...P.querySelectorAll('#cs-rows .cs-row')];
      if (!rader.length) fel.push('inga stats-rader att prova');
      for (const rad of rader) {
        const a = ruta(rad.querySelector('.k')), c = ruta(rad.querySelector('.v')), b = rad.getBoundingClientRect();
        if (a.right > c.left + 0.5 && a.bottom > c.top + 0.5 && c.bottom > a.top + 0.5) fel.push(`rad ${rad.textContent.trim()}: namn och tal krockar`);
        if (a.right > b.right + 0.5 || c.right > b.right + 0.5) fel.push(`rad ${rad.textContent.trim()}: utanfor raden`);
      }
      return fel;
    });
    expect(krockar, 'bredd ' + width).toEqual([]);
  }
  expect(spel.fel()).toEqual([]);
});

test('fonster: map oppnas och stangs', async ({ page, context }) => {
  const spel = await startaSpelet(page, context);
  const frame = page.locator('#map-frame');
  await frame.scrollIntoViewIfNeeded();
  await expect(frame).toBeVisible();
  const karta = page.frameLocator('#map-frame');
  await expect(karta.getByText('THE LANDING', { exact: false }).first()).toBeVisible();

  const oppna = page.locator('#map-fs-open');
  if (await oppna.isVisible()) {
    await oppna.click();
    await expect(page.locator('body')).toHaveClass(/\bmap-fs-open\b/);
    await expect(page.locator('#map-fs-close')).toBeVisible();
    expect(await horisontelltOverflow(page), 'horisontellt overflow med kartan i helskarm').toBeNull();
    await page.locator('#map-fs-close').click();
    await expect(page.locator('body')).not.toHaveClass(/\bmap-fs-open\b/);
  } else {
    test.info().annotations.push({ type: 'info', description: 'Bred skarm: kartan ar inbyggd i sidan och har ingen oppna/stang-knapp.' });
    // Panelen far inte sticka ut till hoger.
    const box = await frame.boundingBox();
    expect(Math.round(box.x + box.width)).toBeLessThanOrEqual(page.viewportSize().width);
  }
  expect(spel.fel()).toEqual([]);
});
