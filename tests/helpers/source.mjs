// Laser spelets filer direkt fran disken (utan webblasare) for de "statiska" testerna.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

export const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');

let _html = null;
export function indexHtml() {
  if (_html === null) _html = fs.readFileSync(path.join(ROOT, 'index.html'), 'utf8');
  return _html;
}

/** Katalogen i <script type="application/json" id="genesis-catalog">. */
export function catalog() {
  const m = /<script type="application\/json" id="genesis-catalog">([\s\S]*?)<\/script>/.exec(indexHtml());
  if (!m) throw new Error('genesis-catalog hittades inte i index.html');
  return JSON.parse(m[1]);
}

/** Texten i ett element med en viss klass, ur rå-HTML:en (forsta traffen som innehaller "GENESIS v"). */
export function versionTexts() {
  const html = indexHtml();
  const snVer = [...html.matchAll(/<div class="sn-ver">([^<]*)<\/div>/g)].map(m => m[1].trim());
  const desc = [...html.matchAll(/<div class="desc">([^<]*GENESIS v[^<]*)<\/div>/g)].map(m => m[1].trim());
  return { snVer, desc, catalogVer: catalog().ver };
}

export function patchnotes() {
  return JSON.parse(fs.readFileSync(path.join(ROOT, 'patchnotes.json'), 'utf8'));
}

/** Tar bort JS-kommentarer (enkelt: rader med // och block /* *\/) utan att rora strangar med snedstreck i. */
function stripComments(src) {
  return src.replace(/\/\*[\s\S]*?\*\//g, '').replace(/(^|[^:'"\\])\/\/[^\n]*/g, '$1');
}

/** Nycklarna i objektet `const PETS = { ... };` i spelets kod. */
export function petKeys() {
  const html = indexHtml();
  const start = html.indexOf('const PETS = {');
  if (start < 0) throw new Error('const PETS hittades inte i index.html');
  let i = html.indexOf('{', start), depth = 0, end = -1;
  for (; i < html.length; i++) {
    const c = html[i];
    if (c === '{') depth++;
    else if (c === '}') { depth--; if (depth === 0) { end = i; break; } }
  }
  const body = stripComments(html.slice(html.indexOf('{', start) + 1, end));
  const keys = [];
  let d = 0;
  // Bara nycklar pa forsta nivan: "nyckel: {"
  const re = /([A-Za-z_$][\w$]*)\s*:\s*\{|[{}]/g;
  let m;
  while ((m = re.exec(body))) {
    if (m[0] === '{') d++;
    else if (m[0] === '}') d--;
    else { if (d === 0) keys.push(m[1]); d++; }
  }
  return keys;
}

/** Sökvägsmallen for hjalparbilder, t.ex. "assets/pets/{sp}.webp". */
export function petArtTemplate() {
  const m = /function petArt\(sp\)\{\s*return '([^']*)' \+ sp \+ '([^']*)';\s*\}/.exec(indexHtml());
  if (!m) throw new Error('function petArt(sp) har bytt form - uppdatera testet');
  return { prefix: m[1], suffix: m[2] };
}

export function exists(rel) {
  return fs.existsSync(path.join(ROOT, rel)) && fs.statSync(path.join(ROOT, rel)).isFile();
}
