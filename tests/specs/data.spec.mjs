// STATISKA TESTER: laser filerna direkt fran disken, ingen webblasare behovs.
import { test, expect } from '@playwright/test';
import { catalog, versionTexts, patchnotes, petKeys, petArtTemplate, exists } from '../helpers/source.mjs';

const VER_RE = /v(\d+\.\d+\.\d+)/;

test.describe('Version', () => {
  test('versionen ar identisk pa sina tre platser (sn-ver, desc, genesis-catalog "ver")', () => {
    const { snVer, desc, catalogVer } = versionTexts();
    expect(snVer, 'exakt en <div class="sn-ver"> i index.html').toHaveLength(1);
    expect(desc, 'exakt en <div class="desc"> med "GENESIS v" i index.html').toHaveLength(1);
    expect(catalogVer, 'genesis-catalog har ett "ver"').toMatch(VER_RE);
    expect(desc[0], 'desc (Installningar > Version) = sn-ver').toBe(snVer[0]);
    expect(catalogVer, 'genesis-catalog "ver" = sn-ver').toBe(snVer[0]);
  });

  test('nyaste posten i patchnotes.json har samma version', () => {
    const ver = VER_RE.exec(versionTexts().snVer[0])[1];
    const e = patchnotes().entries;
    expect(e.length).toBeGreaterThan(0);
    expect(e[0].ver, 'forsta (nyaste) posten i patchnotes.json').toBe(ver);
    // "Nyaste forst" ska verkligen galla: ingen post langre ned far ha hogre version.
    const num = v => v.split('.').map(Number);
    const cmp = (a, b) => { const x = num(a), y = num(b); for (let i = 0; i < 3; i++) if (x[i] !== y[i]) return x[i] - y[i]; return 0; };
    const hogre = e.filter(x => cmp(x.ver, e[0].ver) > 0).map(x => x.ver);
    expect(hogre, 'poster med hogre version an den forsta').toEqual([]);
  });
});

// ---------- patchnotes.json ----------
const HTML_TAGS = 'a abbr b blockquote br code del details div em font h1 h2 h3 h4 h5 h6 hr i img ins kbd li mark ol p pre q s script small span strike strong style sub summary sup table tbody td th thead tr u ul iframe svg video audio source button input label form'.split(' ');
const TAG_RE = new RegExp('</?(' + HTML_TAGS.join('|') + ')(\\s[^<>]*)?\\s*/?>', 'i');
const ENTITY_RE = /&(nbsp|amp|lt|gt|quot|#\d+|#x[0-9a-f]+);/i;
export function hasHtml(s) { return TAG_RE.test(s) || ENTITY_RE.test(s); }

function* strings(x, p = '') {
  if (Array.isArray(x)) for (let i = 0; i < x.length; i++) yield* strings(x[i], `${p}[${i}]`);
  else if (x && typeof x === 'object') for (const k of Object.keys(x)) yield* strings(x[k], p ? `${p}.${k}` : k);
  else if (typeof x === 'string') yield [p, x];
}

test.describe('patchnotes.json', () => {
  test('HTML-detektorn fungerar (sjalvtest)', () => {
    for (const s of ['<b>x</b>', 'a<br>b', '<br/>', '<a href="x">y</a>', 'x &amp; y', '<SPAN class="z">'])
      expect(hasHtml(s), s).toBe(true);
    // Vanlig text som ser ut som taggar men inte ar det (finns i patchnoterna i dag).
    for (const s of ['<3 and >:) work', 'Open <namn>.', 'a < b > c', '5 < 6'])
      expect(hasHtml(s), s).toBe(false);
  });

  test('inga HTML-taggar i nagon text', () => {
    const fynd = [];
    let antal = 0;
    for (const e of patchnotes().entries)
      for (const [p, s] of strings(e)) { antal++; if (hasHtml(s)) fynd.push(`${e.ver} ${p}: ${s.slice(0, 120)}`); }
    expect(antal, 'antal granskade texter').toBeGreaterThan(1000);
    expect(fynd).toEqual([]);
  });

  test('varje post har sina obligatoriska falt', () => {
    const d = patchnotes();
    expect(Array.isArray(d.entries)).toBe(true);
    const fel = [];
    const sett = new Set();
    for (const [i, e] of d.entries.entries()) {
      const id = `post ${i} (${e && e.ver})`;
      const krav = (ok, msg) => { if (!ok) fel.push(`${id}: ${msg}`); };
      krav(typeof e.ver === 'string' && /^\d+\.\d+\.\d+$/.test(e.ver), 'ver ska vara "X.Y.Z"');
      krav(!sett.has(e.ver), 'ver finns redan tidigare i listan'); sett.add(e.ver);
      krav(typeof e.date === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(e.date) && !isNaN(Date.parse(e.date)), 'date ska vara ett riktigt datum "AAAA-MM-DD"');
      for (const k of ['title_en', 'title_sv', 'hint_en', 'fun_en', 'fun_sv'])
        krav(typeof e[k] === 'string' && e[k].trim() !== '', `${k} saknas eller ar tom`);
      krav(['daily', 'now', 'hold'].includes(e.discord), 'discord ska vara daily, now eller hold');
      for (const L of ['en', 'sv']) {
        krav(Array.isArray(e[L]) && e[L].length > 0, `${L} ska vara en lista med minst ett avsnitt`);
        (Array.isArray(e[L]) ? e[L] : []).forEach((s, j) => {
          krav(s && typeof s.h === 'string' && s.h.trim() !== '', `${L}[${j}].h (rubrik) saknas`);
          krav(s && Array.isArray(s.li) && s.li.length > 0 && s.li.every(x => typeof x === 'string' && x.trim() !== ''), `${L}[${j}].li ska vara en lista med text`);
        });
      }
      if ('viktigt' in e) krav(Array.isArray(e.viktigt) && e.viktigt.every(x => typeof x === 'string'), 'viktigt ska vara en lista med text');
    }
    expect(d.entries.length).toBeGreaterThan(100);
    expect(fel).toEqual([]);
  });
});

// ---------- bilder ----------
const IMG_RE = /\.(webp|png|jpe?g|gif|svg|avif)$/i;

test.describe('Bilder', () => {
  test('varje bildsokvag i klientens katalog (genesis-catalog) finns pa disken', () => {
    const paths = new Map();   // sokvag -> var den star
    for (const [p, s] of strings(catalog())) if (IMG_RE.test(s)) { if (!paths.has(s)) paths.set(s, p); }
    expect(paths.size, 'antal bildsokvagar i katalogen').toBeGreaterThan(500);
    /* Gamla saker som ingen spelare har och som inte tillverkas (kollat mot servern 2026-11-02, Chris beslut): ingen bild bestalls.
       Far nagon av dem en bild, eller borjar anvandas igen, ska den bort har. */
    const GAMLA = new Set(['q_dressing_roll', 'q_fuel_gem', 'q_route_marker', 'q_spare_toolkit', 'battery', 'circuit', 'cog', 'data_chip',
      'genesis_spore', 'glass_moss', 'lens', 'neon_bloom', 'null_orchid', 'power_core', 'prism_sap', 'refined_bioessence', 'static_cap', 'tech_parts', 'wire']
      .map(k => (k.startsWith('q_') ? 'assets/items/quest/' : 'assets/materials/') + k + '.webp'));
    const saknas = [...paths].filter(([s]) => !exists(s) && !GAMLA.has(s)).map(([s, p]) => `${s}   (${p})`).sort();
    expect(saknas, `${saknas.length} bilder i katalogen saknas pa disken`).toEqual([]);
  });

  test('varje hjalpare i PETS har en bild', () => {
    const keys = petKeys();
    expect(keys.length, 'antal hjalpare i PETS').toBeGreaterThan(40);
    const { prefix, suffix } = petArtTemplate();
    const saknas = keys.filter(k => !exists(prefix + k + suffix)).map(k => prefix + k + suffix);
    expect(saknas).toEqual([]);
    // Katalogens hjalparlista ska tacka samma hjalpare som PETS.
    const cat = catalog().pets || {};
    expect(keys.filter(k => !cat[k]), 'i PETS men inte i katalogen').toEqual([]);
    expect(Object.keys(cat).filter(k => !keys.includes(k)), 'i katalogen men inte i PETS').toEqual([]);
  });
});
