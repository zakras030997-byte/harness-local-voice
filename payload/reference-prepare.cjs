const fs=require('fs'),path=require('path');
async function prepareReferences({data,root,cache,python,run}){
 const {asset}=require('./prepare.cjs');
 const manifest=JSON.parse(fs.readFileSync(path.join(__dirname,'reference-model.json'),'utf8'));
 const model=path.join(cache,'qwen3-tts-'+manifest.revision),environment=path.join(data,'reference-runtime-0.3.0');
 fs.mkdirSync(model,{recursive:true,mode:0o700});
 console.log('Загружаю проверенные компоненты голосовых эталонов (Qwen3-TTS)…');
 for(const spec of manifest.files){if(!/^[a-zA-Z0-9_./-]+$/.test(spec.file)||spec.file.split('/').includes('..')||path.isAbsolute(spec.file))throw Error('Invalid model manifest');fs.mkdirSync(path.dirname(path.join(model,spec.file)),{recursive:true,mode:0o700});await asset(spec,[],model);}
 console.log('Настраиваю локальные голосовые эталоны…');
 if(!fs.existsSync(path.join(environment,'bin/python')))await run(python,['-m','venv',environment]);
 const executable=path.join(environment,'bin/python');
 await run(executable,['-m','pip','install','--no-cache-dir','--only-binary=:all:','--no-deps','--require-hashes','-r',path.join(__dirname,'reference-requirements.lock')]);
 await run(executable,['-m','pip','check']);
 await run(executable,['-c','import mlx.core,numpy,soundfile; from mlx_audio.tts.models.qwen3_tts import Model; print("Reference speech engine ready")']);
 fs.writeFileSync(path.join(root,'reference-engine.json'),JSON.stringify({python:executable,model,modelId:manifest.modelId,revision:manifest.revision}),{mode:0o600});
 return{model,environment};
}
module.exports={prepareReferences};
