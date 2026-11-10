from pathlib import Path
import shutil,plistlib,subprocess,hashlib
base=Path(__file__).resolve().parent
out=base.parent/'build/release';out.mkdir(parents=True,exist_ok=True)
app=out/'Установить ANODHAS Voice.app'
res=app/'Contents/Resources';bin=app/'Contents/MacOS';res.mkdir(parents=True,exist_ok=True);bin.mkdir(parents=True,exist_ok=True)
payload=base.parent/'payload'
orb=payload/'plugin/native/VoiceOrb.app'
subprocess.run(['xcrun','swiftc','-sdk','/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk','-module-cache-path',str(base/'swift-cache'),'-target','arm64-apple-macos26.0',str(payload/'plugin/native/src/voice-panel.swift'),'-o',str(orb/'Contents/MacOS/voice-panel'),'-framework','Cocoa'],check=True)
subprocess.run(['codesign','--force','--deep','--sign','-',str(orb)],check=True)
(payload/'SHA256SUMS').write_text(''.join(hashlib.sha256(f.read_bytes()).hexdigest()+'  '+f.relative_to(payload).as_posix()+'\n' for f in sorted(payload.rglob('*')) if f.is_file() and not f.is_symlink() and f.name!='SHA256SUMS'))
shutil.copytree(payload,res/'payload',dirs_exist_ok=True)
shutil.copy2(base/'install.cjs',res/'install.cjs')
plist={'CFBundleIdentifier':'ai.anodhas.harness.voice.installer','CFBundleName':'ANODHAS Voice Installer','CFBundleDisplayName':'Установить ANODHAS Voice','CFBundleExecutable':'VoiceInstaller','CFBundlePackageType':'APPL','CFBundleShortVersionString':'0.3.0','CFBundleVersion':'30','LSMinimumSystemVersion':'26.0','NSHighResolutionCapable':True,'CFBundleIconFile':'Voice.icns'}
(app/'Contents/Info.plist').write_bytes(plistlib.dumps(plist))
subprocess.run(['xcrun','swiftc','-sdk','/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk','-module-cache-path',str(base/'swift-cache'),'-target','arm64-apple-macos26.0',str(base/'Installer.swift'),'-o',str(bin/'VoiceInstaller'),'-framework','Cocoa'],check=True)
subprocess.run(['xcrun','swiftc','-sdk','/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk','-module-cache-path',str(base/'swift-cache'),str(base/'Icon.swift'),'-o',str(base/'icon-tool')],check=True)
subprocess.run([str(base/'icon-tool'),str(base/'icon.png')],check=True)
icons=base/'Voice.iconset';icons.mkdir(exist_ok=True)
for size in [16,32,128,256,512]:
 for scale in [1,2]:
  name=f'icon_{size}x{size}'+('@2x' if scale==2 else '')+'.png'
  subprocess.run(['sips','-z',str(size*scale),str(size*scale),str(base/'icon.png'),'--out',str(icons/name)],check=True,stdout=subprocess.DEVNULL)
import struct
chunks=[]
for kind,name in [('icp4','icon_16x16.png'),('icp5','icon_32x32.png'),('icp6','icon_32x32@2x.png'),('ic07','icon_128x128.png'),('ic08','icon_256x256.png'),('ic09','icon_512x512.png'),('ic10','icon_512x512@2x.png')]:
 data=(icons/name).read_bytes();chunks.append(kind.encode()+struct.pack('>I',len(data)+8)+data)
data=b''.join(chunks);(res/'Voice.icns').write_bytes(b'icns'+struct.pack('>I',len(data)+8)+data)
subprocess.run(['codesign' ,'--force','--deep','--sign','-',str(app)],check=True)
print(app)
