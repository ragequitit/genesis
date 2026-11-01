// Bygger spelets figurer av KayKit 2.0: vapen fast i handen, krympt som ovriga (meshopt + WebP). node bygg.mjs <pack> <ut>
import {NodeIO} from '@gltf-transform/core';import {ALL_EXTENSIONS,EXTTextureWebP} from '@gltf-transform/extensions';import {dedup,prune,meshopt,mergeDocuments,unpartition} from '@gltf-transform/functions';import {MeshoptEncoder,MeshoptDecoder} from 'meshoptimizer';import sharp from 'sharp';import fs from 'fs';
await MeshoptEncoder.ready;await MeshoptDecoder.ready;const io=new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({'meshopt.encoder':MeshoptEncoder,'meshopt.decoder':MeshoptDecoder});
const [pack,ut]=process.argv.slice(2);const C=pack+'/Characters/gltf/',A=pack+'/Assets/gltf/';
const FIG={knight:['Knight',{r:'sword_1handed',l:'shield_round'}],barbarian:['Barbarian',{r:'axe_2handed'}],mage:['Mage',{r:'staff'}],rogue:['Rogue',{r:'dagger',l:'dagger'}],rogue_hooded:['Rogue_Hooded',{r:'crossbow_1handed'}],ranger:['Ranger',{l:'bow_withString'}]};
const namn=process.argv[4]?process.argv[4].split(','):Object.keys(FIG);
export async function bygg(key,src,wp,hide=[],recolor=null){const d=await io.read(src),r=d.getRoot();const bone=n=>r.listNodes().find(x=>x.getName()===n);
 for(const sida of Object.keys(wp)){const w=await io.read(A+wp[sida]+'.gltf');const before=new Set(r.listNodes());mergeDocuments(d,w);const nya=r.listNodes().filter(n=>!before.has(n));const top=nya.filter(n=>n.getMesh());const slot=bone('handslot.'+sida);for(const n of top){r.listScenes().forEach(s=>{if(s.listChildren().includes(n))s.removeChild(n)});slot.addChild(n);}}
 r.listScenes().slice(1).forEach(s=>s.dispose());r.setDefaultScene(r.listScenes()[0]);
 for(const n of r.listNodes()){if(hide.includes(n.getName())){n.dispose();}}
 await d.transform(dedup());
 for(const t of r.listTextures()){let img=sharp(Buffer.from(t.getImage())).ensureAlpha();if(recolor)img=sharp(await recolor(img));const b=await img.resize(512,512,{kernel:'nearest'}).webp({quality:92,alphaQuality:100}).toBuffer();t.setImage(new Uint8Array(b)).setMimeType('image/webp').setURI('t.webp');}
 d.createExtension(EXTTextureWebP).setRequired(true);
 await d.transform(dedup(),prune({keepLeaves:true,keepAttributes:true}),unpartition(),meshopt({encoder:MeshoptEncoder,level:'medium'}));await io.write(ut+'/'+key+'.glb',d);console.log(key,Math.round(fs.statSync(ut+'/'+key+'.glb').size/1024)+'kB','noder',r.listNodes().length,r.listNodes().filter(n=>n.getMesh()).map(n=>n.getName()).join(' '));}
if(process.argv[1].endsWith('bygg.mjs')){fs.mkdirSync(ut,{recursive:true});for(const k of namn)await bygg(k,C+FIG[k][0]+'.glb',FIG[k][1]);}
