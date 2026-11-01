// Fargvarianter: nya fargark dar bara klader byter farg. node skins.mjs <pack> <figs20> <utmapp skin>
import {NodeIO} from '@gltf-transform/core';import {ALL_EXTENSIONS} from '@gltf-transform/extensions';import {MeshoptDecoder} from 'meshoptimizer';import sharp from 'sharp';import fs from 'fs';
await MeshoptDecoder.ready;const io=new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({'meshopt.decoder':MeshoptDecoder});
const {bygg}=await import('./bygg.mjs');
const [pack,fd,ut]=process.argv.slice(2);fs.mkdirSync(ut,{recursive:true});const W='C:/Users/joaki/Documents/genesis-varld/assets/world3d/';
const rgb2hsl=(r,g,b)=>{r/=255;g/=255;b/=255;const mx=Math.max(r,g,b),mn=Math.min(r,g,b),l=(mx+mn)/2,d=mx-mn;let h=0,s=0;if(d){s=d/(1-Math.abs(2*l-1)||1);h=mx===r?((g-b)/d+6)%6:mx===g?(b-r)/d+2:(r-g)/d+4;h*=60;}return [h,s,l];};
const hsl2rgb=(h,s,l)=>{const c=(1-Math.abs(2*l-1))*s,x=c*(1-Math.abs((h/60)%2-1)),m=l-c/2;const [r,g,b]=h<60?[c,x,0]:h<120?[x,c,0]:h<180?[0,c,x]:h<240?[0,x,c]:h<300?[x,0,c]:[c,0,x];return [(r+m)*255,(g+m)*255,(b+m)*255];};
const hue=regler=>(d)=>{for(let i=0;i<d.length;i+=4){const [h,s,l]=rgb2hsl(d[i],d[i+1],d[i+2]);for(const R of regler){const inne=R.from[0]<=R.from[1]?h>=R.from[0]&&h<=R.from[1]:h>=R.from[0]||h<=R.from[1];if(inne&&s>=(R.minS||.12)){const q=hsl2rgb(R.to,Math.min(1,s*(R.s||1)),Math.min(1,l*(R.l||1)));d[i]=q[0];d[i+1]=q[1];d[i+2]=q[2];break;}}}};
// rutor i arket (8 x 4): farga en ruta efter ljusstyrkan
const cells=list=>(d,W2,H2)=>{const cw=W2/8,rh=H2/4;for(const [c,r,t,w=1,b=1.5] of list)for(let y=Math.round(r*rh);y<Math.round((r+1)*rh);y++)for(let x=Math.round(c*cw);x<Math.round((c+w)*cw);x++){const i=(y*W2+x)*4,L=Math.min(1,(.3*d[i]+.59*d[i+1]+.11*d[i+2])/255*b);d[i]=t[0]*L;d[i+1]=t[1]*L;d[i+2]=t[2]*L;}};
const G=[100,190],V=[225,345],B=[195,245],R=[340,12];const KRED=[335,15];
const SK={ // [figur, fil, regel]
 warden_blue:['knight',(a,w,h)=>{hue([{from:R,to:220,minS:.3}])(a);cells([[3,0,[120,160,235],1,1.55],[7,0,[120,160,235],1,1.55],[2,1,[120,160,235],2,1.55]])(a,w,h);}],warden_purple:['knight',(a,w,h)=>{hue([{from:R,to:280,minS:.3}])(a);cells([[3,0,[170,125,235],1,1.55],[7,0,[170,125,235],1,1.55],[2,1,[170,125,235],2,1.55]])(a,w,h);}],
 breaker_white:['barbarian',cells([[1,0,[235,240,250],1,1.5],[7,0,[205,215,230],1,1.5],[1,1,[230,235,245],1,1.5],[6,1,[210,220,235],1,1.6]])],breaker_black:['barbarian',cells([[1,0,[80,72,88],1,1.3],[7,0,[60,55,72],1,1.4],[1,1,[78,72,90],1,1.3],[6,1,[55,50,65],1,1.5]])],
 fabricator_green:['mage',hue([{from:V,to:135,s:1}])],fabricator_red:['mage',hue([{from:V,to:352,s:1.2}])],
 prospector_blue:['rogue',hue([{from:G,to:222}])],prospector_red:['rogue',hue([{from:G,to:352}])],
 runner_purple:['rogue_hooded',hue([{from:G,to:278}])],runner_red:['rogue_hooded',hue([{from:G,to:352}])],
 ranger_red:['ranger',hue([{from:B,to:355}])],ranger_green:['ranger',hue([{from:B,to:130}])],
 paladin_red:['paladin',hue([{from:[200,245],to:355,minS:.35}])],paladin_purple:['paladin',hue([{from:[200,245],to:280,minS:.35}])],
 skel_minion_blue:['skel_minion',hue([{from:KRED,to:222,minS:.3},{from:[12,40],to:222,minS:.3}])],skel_minion_green:['skel_minion',hue([{from:KRED,to:130,minS:.3},{from:[12,40],to:130,minS:.3}])],skel_rogue_blue:['skel_rogue',hue([{from:KRED,to:222,minS:.3}])],skel_rogue_green:['skel_rogue',hue([{from:KRED,to:130,minS:.3}])],skel_warrior_blue:['skel_warrior',hue([{from:KRED,to:222,minS:.3}])],skel_warrior_green:['skel_warrior',hue([{from:KRED,to:130,minS:.3}])],skel_mage_blue:['skel_mage',hue([{from:KRED,to:222,minS:.3}])],skel_mage_green:['skel_mage',hue([{from:KRED,to:130,minS:.3}])],
};
// Paladin: vit rustning, guld, bla kappa
const palad=async img=>{const {data,info}=await img.raw().toBuffer({resolveWithObject:true});cells([[3,0,[235,228,205],1,1.3],[7,0,[235,228,205],1,1.3],[2,1,[235,228,205],2,1.3],[4,0,[240,185,60],1,1.5],[7,1,[240,185,60],1,1.5],[0,1,[45,95,235],1,1.25],[2,2,[45,95,235],1,1.25],[5,0,[255,200,90],1,1.55],[6,0,[230,170,70],1,1.7],[5,1,[230,170,70],1,1.7],[3,2,[230,170,70],1,1.7]])(data,info.width,info.height);return sharp(data,{raw:{width:info.width,height:info.height,channels:4}}).png().toBuffer();};
await bygg('paladin',pack+'/Characters/gltf/Knight.glb',{r:'sword_2handed_color',l:'shield_badge_color'},['Knight_HelmetVisor'],palad);
let tot=0;for(const [k,[f,fn]] of Object.entries(SK)){const p=fs.existsSync(fd+'/'+f+'.glb')?fd+'/'+f+'.glb':W+f+'.glb';const d=await io.read(p);const T=d.getRoot().listTextures()[0];const {data,info}=await sharp(Buffer.from(T.getImage())).ensureAlpha().resize(512,512,{kernel:'nearest'}).raw().toBuffer({resolveWithObject:true});fn(data,info.width,info.height);const b=await sharp(data,{raw:{width:info.width,height:info.height,channels:4}}).webp({quality:90}).toBuffer();fs.writeFileSync(ut+'/'+k+'.webp',b);tot+=b.length;}
console.log(Object.keys(SK).length,'ark',Math.round(tot/1024),'kB');
