"""Offline stock Silero voices. JSON lines; no personal references or network."""
import sys,json,wave,torch,gc,numpy as np
from pathlib import Path
torch.set_num_threads(2)
root=Path(__file__).resolve().parents[1]
allowed={v['id'] for v in json.loads((root/'package/voices.json').read_text()) if v['id']!='Milena'}
current='v5_cis_base.pt'
model=torch.package.PackageImporter(str(root/'tts-runtime'/current)).load_pickle('tts_models','model')
print('READY',flush=True)
for line in sys.stdin:
 if line.strip()=='QUIT':break
 try:
  p=json.loads(line)
  if p['voice'] not in allowed or not isinstance(p['text'],str) or len(p['text'])>1200:raise ValueError('Invalid request')
  desired='v5_cis_base.pt' if p['voice'].startswith('ru_') else 'v5_6_ru.pt'
  if desired!=current:
   del model
   gc.collect()
   model=torch.package.PackageImporter(str(root/'tts-runtime'/desired)).load_pickle('tts_models','model')
   current=desired
  audio=model.apply_tts(text=p['text'],speaker=p['voice'],sample_rate=24000,put_accent=True,put_yo=True)
  pcm=(np.clip(audio.numpy(),-1,1)*32767).astype('<i2')
  with wave.open(p['output'],'wb') as f:f.setnchannels(1);f.setsampwidth(2);f.setframerate(24000);f.writeframes(pcm.tobytes())
  print('OK',flush=True)
 except Exception:
  print('ERROR',flush=True)
