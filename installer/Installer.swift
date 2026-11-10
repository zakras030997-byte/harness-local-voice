import Cocoa

final class Installer: NSObject, NSApplicationDelegate, NSWindowDelegate {
 var window:NSWindow!; var label:NSTextField!; var detail:NSTextField!; var progress:NSProgressIndicator!; var action:NSButton!; var running=false; var done=false; var pending=""
 let appPath=ProcessInfo.processInfo.environment["ANODHAS_HARNESS_APP"] ?? "/Applications/DeepSeek Harness.app"
 func applicationDidFinishLaunching(_ notification:Notification){
  NSApp.setActivationPolicy(.regular)
  window=NSWindow(contentRect:NSRect(x:0,y:0,width:540,height:400),styleMask:[.titled,.closable],backing:.buffered,defer:false);window.title="ANODHAS Voice";window.delegate=self;window.center()
  let v=window.contentView!;v.wantsLayer=true;v.layer?.backgroundColor=NSColor(calibratedRed:0.10,green:0.085,blue:0.14,alpha:1).cgColor
  let icon=NSImageView(frame:NSRect(x:38,y:280,width:68,height:68));icon.image=NSImage(systemSymbolName:"waveform.circle.fill",accessibilityDescription:"Голос");icon.contentTintColor=NSColor(calibratedRed:0.64,green:0.43,blue:1,alpha:1);icon.symbolConfiguration=NSImage.SymbolConfiguration(pointSize:62,weight:.regular);v.addSubview(icon)
  let title=text("Голос для Harness",NSRect(x:126,y:311,width:370,height:35),24,.semibold);v.addSubview(title)
  v.addSubview(text("Разговор · диктовка · чтение вслух",NSRect(x:126,y:281,width:370,height:25),14,.regular))
  label=text("Всё подключится автоматически",NSRect(x:38,y:223,width:464,height:30),17,.medium);v.addSubview(label)
  detail=text("Речь обрабатывается на Mac. При первой установке загрузятся модели, включая Qwen для голосовых эталонов (около 3 ГБ). Ваши модели и подписки Harness сохранятся.",NSRect(x:38,y:141,width:464,height:72),13,.regular);detail.textColor=NSColor(calibratedWhite:0.78,alpha:1);v.addSubview(detail)
  progress=NSProgressIndicator(frame:NSRect(x:38,y:117,width:464,height:5));progress.style = .bar;progress.isIndeterminate=true;progress.isHidden=true;v.addSubview(progress)
  action=NSButton(title:"Установить",target:self,action:#selector(start));action.frame=NSRect(x:340,y:47,width:162,height:38);action.bezelStyle = .rounded;action.keyEquivalent="\r";action.bezelColor=NSColor(calibratedRed:0.52,green:0.28,blue:0.88,alpha:1);action.contentTintColor=NSColor.white;v.addSubview(action)
  v.addSubview(text("Apple Silicon · macOS 26+",NSRect(x:38,y:53,width:270,height:24),12,.regular))
  window.makeKeyAndOrderFront(nil);NSApp.activate(ignoringOtherApps:true)
  if ProcessInfo.processInfo.arguments.contains("--ui-smoke"){DispatchQueue.main.asyncAfter(deadline:.now()+1){self.window.displayIfNeeded();if let bitmap=self.window.contentView!.bitmapImageRepForCachingDisplay(in:self.window.contentView!.bounds){self.window.contentView!.cacheDisplay(in:self.window.contentView!.bounds,to:bitmap);if let url=ProcessInfo.processInfo.environment["ANODHAS_INSTALLER_PREVIEW"],let data=bitmap.representation(using:.png,properties:[:]){try? data.write(to:URL(fileURLWithPath:url))}};let f=self.window.contentView!.bounds;let ok=f.width==540 && self.action.isEnabled && !self.running;print(ok ? "INSTALLER_UI_OK":"INSTALLER_UI_FAILED");NSApp.terminate(nil)}}
 }
 func text(_ s:String,_ frame:NSRect,_ size:CGFloat,_ weight:NSFont.Weight)->NSTextField{let t=NSTextField(wrappingLabelWithString:s);t.frame=frame;t.font = .systemFont(ofSize:size,weight:weight);t.textColor = .white;return t}
 @objc func start(){
  if done {NSWorkspace.shared.openApplication(at:URL(fileURLWithPath:appPath),configuration:NSWorkspace.OpenConfiguration()){_,_ in};NSApp.terminate(nil);return}
  guard !running else{return}
  guard FileManager.default.fileExists(atPath:appPath) else{show("Сначала установите DeepSeek Harness в папку «Программы».");return}
  let home=ProcessInfo.processInfo.environment["DSH_HOME"] ?? NSHomeDirectory()+"/.dsh"
  if !FileManager.default.fileExists(atPath:home+"/profiles/desktop/package.json") {let a=NSAlert();a.messageText="Сначала нужен первый запуск Harness";a.informativeText="Откройте Harness и завершите его начальную настройку. После этого вернитесь сюда и нажмите «Установить». Команды вводить не нужно.";a.addButton(withTitle:"Открыть Harness");a.addButton(withTitle:"Позже");if a.runModal() == .alertFirstButtonReturn{NSWorkspace.shared.openApplication(at:URL(fileURLWithPath:appPath),configuration:NSWorkspace.OpenConfiguration()){_,_ in}};return}
  let applications=NSWorkspace.shared.runningApplications.filter{$0.bundleURL?.standardizedFileURL.path == URL(fileURLWithPath:appPath).standardizedFileURL.path}
  if !applications.isEmpty {let a=NSAlert();a.messageText="Закрыть Harness для установки?";a.informativeText="Сначала завершите важные задачи. Установщик запросит обычный выход и сохранит настройки. Принудительного завершения не будет.";a.addButton(withTitle:"Закрыть и установить");a.addButton(withTitle:"Отмена");guard a.runModal() == .alertFirstButtonReturn else{return};applications.forEach{_=$0.terminate()};running=true;action.isEnabled=false;label.stringValue="Жду завершения Harness…";waitForQuit(0);return}
  install()
 }
 func waitForQuit(_ count:Int){let active=NSWorkspace.shared.runningApplications.contains{$0.bundleURL?.path==appPath};if !active{running=false;install();return};if count>=120{running=false;action.isEnabled=true;show("Harness ещё работает. Завершите его штатно и нажмите «Установить» снова.");return};DispatchQueue.main.asyncAfter(deadline:.now()+0.5){self.waitForQuit(count+1)}}
 func install(){running=true;action.isEnabled=false;progress.isHidden=false;progress.startAnimation(nil);label.stringValue="Подготавливаю установку…";detail.stringValue="Загрузка и проверка моделей могут занять время. Окно можно оставить открытым."
  let p=Process();p.executableURL=URL(fileURLWithPath:appPath+"/Contents/MacOS/DeepSeek Harness");p.arguments=[Bundle.main.resourcePath!+"/install.cjs"];var e=ProcessInfo.processInfo.environment;e["ELECTRON_RUN_AS_NODE"]="1";p.environment=e;let pipe=Pipe();p.standardOutput=pipe;p.standardError=FileHandle.nullDevice
  pipe.fileHandleForReading.readabilityHandler={h in let data=h.availableData;if data.isEmpty{return};let s=String(data:data,encoding:.utf8) ?? "";DispatchQueue.main.async{self.pending += s;while let i=self.pending.firstIndex(of:"\n"){let line=String(self.pending[..<i]);self.pending=String(self.pending[self.pending.index(after:i)...]);if let b=line.data(using:.utf8),let j=(try? JSONSerialization.jsonObject(with:b)) as? [String:String],let message=j["text"]{self.label.stringValue=message;if j["stage"]=="error"{self.detail.stringValue=message}}}}}
  p.terminationHandler={pr in DispatchQueue.main.asyncAfter(deadline:.now()+0.15){pipe.fileHandleForReading.readabilityHandler=nil;self.running=false;self.progress.stopAnimation(nil);self.progress.isHidden=true;self.action.isEnabled=true;if pr.terminationStatus==0{self.done=true;self.label.stringValue="Голосовой комплект установлен";self.detail.stringValue="В Harness появятся разговор, диктовка и кнопка чтения под ответами. Общие голос, скорость, громкость и перебивание — в настройках сферы.";self.action.title="Открыть Harness"}else{self.label.stringValue="Установка не завершена";self.action.title="Повторить"}}}
  do{try p.run()}catch{running=false;action.isEnabled=true;progress.stopAnimation(nil);show("Не удалось запустить установщик. "+error.localizedDescription)}
 }
 func show(_ s:String){let a=NSAlert();a.messageText="ANODHAS Voice";a.informativeText=s;a.addButton(withTitle:"Понятно");a.runModal()}
 func windowShouldClose(_ sender:NSWindow)->Bool{if running{show("Дождитесь завершения установки. Это защищает профиль Harness от неполного изменения.");return false};return true}
 func applicationShouldTerminateAfterLastWindowClosed(_ sender:NSApplication)->Bool{return true}
}
let delegate=Installer();NSApplication.shared.delegate=delegate;NSApplication.shared.run()
