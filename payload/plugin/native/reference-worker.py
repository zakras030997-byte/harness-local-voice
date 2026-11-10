"""One local MLX reference synthesis; no downloads, retained worker or audio history."""
import os,sys,json,wave,time
os.environ.update(HF_HUB_OFFLINE='1',TRANSFORMERS_OFFLINE='1',HF_HUB_DISABLE_TELEMETRY='1',TOKENIZERS_PARALLELISM='false')
request=json.loads(sys.stdin.readline())
import numpy as np
import mlx.core as mx
from mlx_audio.tts.utils import load_model
started=time.monotonic()
model=load_model(request['model'])
parts=[]
for result in model.generate(text=request['text'],ref_audio=request['reference'],ref_text=request['transcript'],lang_code='ru',max_tokens=min(1200,max(180,len(request['text'])*3)),temperature=0.65,verbose=False):
 parts.append(np.asarray(result.audio,dtype=np.float32).reshape(-1))
if not parts:raise RuntimeError('Empty synthesis')
audio=np.concatenate(parts)
if not np.isfinite(audio).all() or len(audio)<100:raise RuntimeError('Invalid synthesis')
with wave.open(request['output'],'wb') as out:
 out.setnchannels(1);out.setsampwidth(2);out.setframerate(model.sample_rate);out.writeframes((np.clip(audio,-1,1)*32767).astype('<i2').tobytes())
print(json.dumps({'ok':True,'seconds':len(audio)/model.sample_rate,'elapsed':time.monotonic()-started}),flush=True)
