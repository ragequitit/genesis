// [TILLAGT v5.981.0] Tar bort kommentarer ur spelets HTML-filer innan de publiceras (Chris 2026-10-20).
// Koden i sig andras inte: ingen omdopning (mangle) och ingen omskrivning (compress) - bara kommentarer och tomrum.
// Anvands av .github/workflows/pages.yml. Kor lokalt: node .github/scripts/strip.mjs <in-mapp> <ut-mapp>
import { minify } from 'html-minifier-terser';
import fs from 'node:fs';
import path from 'node:path';

const [inDir, outDir] = process.argv.slice(2);
if (!inDir || !outDir) { console.error('usage: strip.mjs <in> <out>'); process.exit(1); }
const FILES = ['index.html', 'admin.html', 'genesis-map.html'];

for (const f of FILES) {
  const src = path.join(inDir, f);
  if (!fs.existsSync(src)) continue;
  const html = fs.readFileSync(src, 'utf8');
  const out = await minify(html, {
    removeComments: true,
    collapseWhitespace: false,
    minifyCSS: { level: 1 },
    minifyJS: { compress: false, mangle: false, format: { comments: false } },
  });
  fs.writeFileSync(path.join(outDir, f), out, 'utf8');
  console.log(f + ': ' + Math.round(html.length / 1024) + ' kB -> ' + Math.round(out.length / 1024) + ' kB');
}
