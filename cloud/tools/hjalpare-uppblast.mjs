/* [TILLAGT v5.1373.0] Gor en hjalpare till 3D av spelets bild: node hjalpare-uppblast.mjs assets/pets/<art>.webp ut.glb [tjocklek=.26]
   Krav: npm i @gltf-transform/core @gltf-transform/extensions @gltf-transform/functions meshoptimizer sharp */
/* Gor en uppblast 3D-figur av en hjalparbild (alfa = silhuett). Framsida och baksida mots i kanten. */
import {Document, NodeIO} from '@gltf-transform/core';
import {ALL_EXTENSIONS, EXTTextureWebP} from '@gltf-transform/extensions';
import {weld, simplify, meshopt, normals, getBounds} from '@gltf-transform/functions';
import {MeshoptEncoder, MeshoptSimplifier} from 'meshoptimizer';
import sharp from 'sharp'; import fs from 'fs';
await MeshoptEncoder.ready; await MeshoptSimplifier.ready;
const [src, dst, depthArg] = process.argv.slice(2); const DEPTH = +depthArg || .2;
const img = sharp(src); const {data, info} = await img.ensureAlpha().raw().toBuffer({resolveWithObject: true});
const W = info.width, H = info.height, S = 2;   // rutnat var 2:a pixel
const GW = Math.floor(W / S) + 1, GH = Math.floor(H / S) + 1;
const A = (x, y) => (x < 0 || y < 0 || x >= W || y >= H) ? 0 : data[(y * W + x) * 4 + 3] / 255;
// inne = rutnatspunkt med alfa > .5 ; avstand till kanten (chamfer)
const inside = new Uint8Array(GW * GH), dist = new Float32Array(GW * GH);
for (let j = 0; j < GH; j++) for (let i = 0; i < GW; i++){ inside[j * GW + i] = A(Math.min(W - 1, i * S), Math.min(H - 1, j * S)) > .5 ? 1 : 0; dist[j * GW + i] = inside[j * GW + i] ? 1e9 : 0; }
const D1 = 1, D2 = 1.4142;
for (let j = 0; j < GH; j++) for (let i = 0; i < GW; i++){ const k = j * GW + i; if (!dist[k]) continue; let d = dist[k];
  if (i > 0) d = Math.min(d, dist[k - 1] + D1); if (j > 0) d = Math.min(d, dist[k - GW] + D1); if (i > 0 && j > 0) d = Math.min(d, dist[k - GW - 1] + D2); if (i < GW - 1 && j > 0) d = Math.min(d, dist[k - GW + 1] + D2); if (i === 0 || j === 0 || i === GW - 1) d = Math.min(d, 1); dist[k] = d; }
for (let j = GH - 1; j >= 0; j--) for (let i = GW - 1; i >= 0; i--){ const k = j * GW + i; if (!dist[k]) continue; let d = dist[k];
  if (i < GW - 1) d = Math.min(d, dist[k + 1] + D1); if (j < GH - 1) d = Math.min(d, dist[k + GW] + D1); if (i < GW - 1 && j < GH - 1) d = Math.min(d, dist[k + GW + 1] + D2); if (i > 0 && j < GH - 1) d = Math.min(d, dist[k + GW - 1] + D2); if (j === GH - 1) d = Math.min(d, 1); dist[k] = d; }
let dmax = 0; for (const d of dist) dmax = Math.max(dmax, d);
// en cell ar med om alla fyra horn ar inne
const cellIn = (i, j) => inside[j * GW + i] && inside[j * GW + i + 1] && inside[(j + 1) * GW + i] && inside[(j + 1) * GW + i + 1];
const used = new Uint8Array(GW * GH);
for (let j = 0; j < GH - 1; j++) for (let i = 0; i < GW - 1; i++) if (cellIn(i, j)) [[0,0],[1,0],[0,1],[1,1]].forEach(([a,b]) => used[(j + b) * GW + i + a] = 1);
// kantpunkt = anvand punkt dar nagon av de fyra kringliggande cellerna saknas -> z = 0 (fram och bak mots)
const isEdge = (i, j) => { for (const [a, b] of [[-1,-1],[0,-1],[-1,0],[0,0]]){ const ci = i + a, cj = j + b; if (ci < 0 || cj < 0 || ci >= GW - 1 || cj >= GH - 1 || !cellIn(ci, cj)) return true; } return false; };
const pos = [], uv = [], col = [], idx = [], idxB = [], map = [new Int32Array(GW * GH).fill(-1), new Int32Array(GW * GH).fill(-1)];
const sc = 1 / Math.max(W, H);
for (const side of [0, 1]) for (let j = 0; j < GH; j++) for (let i = 0; i < GW; i++){ const k = j * GW + i; if (!used[k]) continue;
  if (side === 1 && isEdge(i, j)){ map[1][k] = map[0][k]; continue; }
  const dn = isEdge(i, j) ? 0 : Math.min(1, dist[k] / dmax), z = DEPTH * Math.sqrt(dn * (2 - dn)) * (side ? -.8 : 1);
  map[side][k] = pos.length / 3; pos.push((i * S - W / 2) * sc, (H / 2 - j * S) * sc, z); uv.push(Math.min(W - 1, i * S) / W, Math.min(H - 1, j * S) / H);
  }
for (let j = 0; j < GH - 1; j++) for (let i = 0; i < GW - 1; i++){ if (!cellIn(i, j)) continue;
  const q = (s, a, b) => map[s][(j + b) * GW + i + a];
  idx.push(q(0,0,0), q(0,0,1), q(0,1,0), q(0,1,0), q(0,0,1), q(0,1,1));   // framsidan mot +z
  idxB.push(q(1,0,0), q(1,1,0), q(1,0,1), q(1,1,0), q(1,1,1), q(1,0,1)); }
/* mjuka normaler (snitt av ytornas) - fore weld/simplify, sa delade punkter behalls */
const nrm = new Float32Array(pos.length);
const ALL = idx.concat(idxB);
for (let t = 0; t < ALL.length; t += 3){ const [a, b, c] = [ALL[t], ALL[t + 1], ALL[t + 2]].map(v => v * 3);
  const ux = pos[b] - pos[a], uy = pos[b + 1] - pos[a + 1], uz = pos[b + 2] - pos[a + 2], vx = pos[c] - pos[a], vy = pos[c + 1] - pos[a + 1], vz = pos[c + 2] - pos[a + 2];
  const nx = uy * vz - uz * vy, ny = uz * vx - ux * vz, nz = ux * vy - uy * vx; for (const v of [a, b, c]){ nrm[v] += nx; nrm[v + 1] += ny; nrm[v + 2] += nz; } }
/* kantpunkter dar fram och bak tar ut varandra: peka rakt utat fran mitten (aldrig nollvektor - den ger NaN och svart glod) */
for (let v = 0; v < nrm.length; v += 3){ let L = Math.hypot(nrm[v], nrm[v + 1], nrm[v + 2]);
  if (!(L > 1e-6)){ nrm[v] = pos[v]; nrm[v + 1] = pos[v + 1]; nrm[v + 2] = 0; L = Math.hypot(nrm[v], nrm[v + 1]); if (!(L > 1e-6)){ nrm[v + 2] = 1; L = 1; } }
  nrm[v] /= L; nrm[v + 1] /= L; nrm[v + 2] /= L; }
const doc = new Document(); const buf = doc.createBuffer();
const acc = (arr, type, T) => doc.createAccessor().setType(type).setArray(new T(arr)).setBuffer(buf);
const P = acc(pos, 'VEC3', Float32Array), U = acc(uv, 'VEC2', Float32Array), N = acc(nrm, 'VEC3', Float32Array);
doc.createExtension(EXTTextureWebP).setRequired(true);
/* baksidan: samma bild suddad och morkare - kroppens farger utan ansikte */
const back = await sharp(src).ensureAlpha().blur(9).modulate({brightness: .78}).webp({quality: 80}).toBuffer();
const mat = (im) => doc.createMaterial().setBaseColorTexture(doc.createTexture().setImage(im).setMimeType('image/webp')).setMetallicFactor(0).setRoughnessFactor(.8).setAlphaMode('MASK').setAlphaCutoff(.4);
const mesh = doc.createMesh();
mesh.addPrimitive(doc.createPrimitive().setAttribute('POSITION', P).setAttribute('TEXCOORD_0', U).setAttribute('NORMAL', N).setIndices(acc(idx, 'SCALAR', Uint32Array)).setMaterial(mat(fs.readFileSync(src))));
mesh.addPrimitive(doc.createPrimitive().setAttribute('POSITION', P).setAttribute('TEXCOORD_0', U).setAttribute('NORMAL', N).setIndices(acc(idxB, 'SCALAR', Uint32Array)).setMaterial(mat(back)));
const node = doc.createNode('helper').setMesh(mesh); doc.createScene().addChild(node);
await doc.transform(weld(), simplify({simplifier: MeshoptSimplifier, ratio: .2, error: .01}));
const b = getBounds(doc.getRoot().listScenes()[0]); const h = b.max[1] - b.min[1], s = 1 / h;
node.setScale([s, s, s]); const b2 = getBounds(doc.getRoot().listScenes()[0]); node.setTranslation([-(b2.min[0] + b2.max[0]) / 2, -b2.min[1], -(b2.min[2] + b2.max[2]) / 2]);
await doc.transform(meshopt({encoder: MeshoptEncoder, level: 'medium'}));
const io = new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({'meshopt.encoder': MeshoptEncoder}); await io.write(dst, doc);
console.log(src.split('/').pop(), 'tri', (idx.length + idxB.length) / 3, (fs.statSync(dst).size / 1024).toFixed(0) + 'kB');
