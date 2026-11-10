const fs=require('fs'),path=require('path'),os=require('os');
const kind='anodhas-local-voice-temporary-v1',prefix='anodhas-voice-',owned=/^(owner\.json|[0-9a-f-]{36}(\.f32|\.txt|\.wav))$/;
function alive(pid){try{process.kill(pid,0);return true}catch(e){return e.code!=='ESRCH'}}
function createTempStore(root=os.tmpdir()){
 const uid=process.getuid?.();
 for(const e of fs.readdirSync(root,{withFileTypes:true})){if(!e.isDirectory()||e.isSymbolicLink()||!e.name.startsWith(prefix))continue;const p=path.join(root,e.name);try{const st=fs.lstatSync(p),f=path.join(p,'owner.json'),marker=fs.lstatSync(f);if(marker.isSymbolicLink()||!marker.isFile()||marker.size>1024||(uid!==undefined&&(st.uid!==uid||marker.uid!==uid)))continue;const m=JSON.parse(fs.readFileSync(f,'utf8'));if(m.kind!==kind||!Number.isSafeInteger(m.pid)||m.pid<=0||alive(m.pid))continue;const children=fs.readdirSync(p,{withFileTypes:true});if(children.some(c=>!c.isFile()||c.isSymbolicLink()||!owned.test(c.name)))continue;for(const c of children)fs.unlinkSync(path.join(p,c.name));fs.rmdirSync(p);}catch{/* An active, foreign or unverifiable directory is left untouched. */}}
 const dir=fs.mkdtempSync(path.join(root,prefix));fs.chmodSync(dir,0o700);fs.writeFileSync(path.join(dir,'owner.json'),JSON.stringify({kind,pid:process.pid}),{mode:0o600});return{dir,close(){for(const n of fs.readdirSync(dir))if(owned.test(n)&&fs.lstatSync(path.join(dir,n)).isFile())fs.unlinkSync(path.join(dir,n));fs.rmdirSync(dir);}};
}
module.exports={createTempStore};
