import AppKit
import UniformTypeIdentifiers

func emit(_ value: [String:Any]) { if let d = try? JSONSerialization.data(withJSONObject:value) { FileHandle.standardOutput.write(d); FileHandle.standardOutput.write(Data([10])) } }
final class FloatingPanel: NSPanel { override var canBecomeKey: Bool { true }; override var canBecomeMain: Bool { false } }
final class Orb: NSView {
 let glassTexture=NSImage(contentsOf:Bundle.main.resourceURL!.appendingPathComponent("sphere-glass.png"))
 var phase="idle", energy:CGFloat=0,displayEnergy:CGFloat=0,flow:CGFloat=0
 override var isOpaque:Bool { false }
 override func mouseDown(with event:NSEvent) { window?.performDrag(with:event) }
 override func draw(_ dirtyRect:NSRect) {
  let reduced=NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
  let e=reduced ? CGFloat(0):max(0,min(1,displayEnergy))
  let r=bounds.insetBy(dx:7-e*1.5,dy:7-e*1.5), shape=NSBezierPath(ovalIn:r)
  let amber=NSColor(calibratedRed:1,green:0.57,blue:0.16,alpha:1)
  let violet=NSColor(calibratedRed:0.76,green:0.43,blue:1,alpha:1)
  NSGraphicsContext.saveGraphicsState()
  let glow=NSShadow();glow.shadowColor=amber.withAlphaComponent(0.42);glow.shadowBlurRadius=12;glow.set();NSColor(calibratedRed:0.25,green:0.11,blue:0.20,alpha:1).setFill();shape.fill();NSGraphicsContext.restoreGraphicsState()
  NSGraphicsContext.saveGraphicsState();shape.addClip()
  NSGradient(colorsAndLocations:(NSColor(calibratedRed:0.055,green:0.027,blue:0.09,alpha:1),0),(NSColor(calibratedRed:0.12,green:0.052,blue:0.18,alpha:1),0.5),(NSColor(calibratedRed:0.28,green:0.13,blue:0.37,alpha:1),1))!.draw(in:r,angle:300)
  if let image=glassTexture {image.draw(in:r.insetBy(dx:-r.width*0.03,dy:-r.height*0.03),from:.zero,operation:.sourceOver,fraction:1,respectFlipped:true,hints:[.interpolation:NSImageInterpolation.high])}
  let bloom=NSGradient(colorsAndLocations:(violet.withAlphaComponent(0.22+e*0.13),0),(violet.withAlphaComponent(0.07),0.55),(NSColor.clear,1))!
  bloom.draw(fromCenter:NSPoint(x:r.midX,y:r.minY+r.height*0.40),radius:0,toCenter:NSPoint(x:r.midX,y:r.midY),radius:r.width*0.52,options:[])
  for cloud in 0..<4 {
   let k=CGFloat(cloud),drift=reduced ? CGFloat(0):flow*0.18
   let center=NSPoint(x:r.midX+sin(drift+k*1.7)*r.width*0.23,y:r.midY+cos(drift*0.7+k*1.9)*r.height*0.25)
   let color=cloud==3 ? NSColor(calibratedRed:0.95,green:0.50,blue:0.18,alpha:0.08):NSColor(calibratedRed:0.57+0.04*k,green:0.32,blue:0.83,alpha:0.13)
   NSGradient(starting:color,ending:.clear)!.draw(fromCenter:center,radius:0,toCenter:center,radius:r.width*(0.32+k*0.015),options:[])
  }
  let speed:CGFloat=phase=="speaking" ? 1.6:1, t0=reduced ? CGFloat(0.7):flow*speed
  for strand in 0..<46 {
   let band=(CGFloat(strand)-22.5)/22.5,p=NSBezierPath()
   for step in 0...128 {
    let t=CGFloat(step)/128,env=pow(max(0,sin(t * .pi)),0.85)
    let first=sin(t * .pi*4.0-t0*2.2+band*0.46)
    let second=sin(t * .pi*7.0+t0*0.65+band*0.22)
    let height=r.height*(0.001+e*0.16)
    let y=r.midY+(first+second*0.30)*height*env+band*r.height*0.030*env*e
    let pt=NSPoint(x:r.minX+t*r.width,y:y)
    if step==0{p.move(to:pt)}else{p.line(to:pt)}
   }
   if strand==23 {let sh=NSShadow();sh.shadowColor=violet;sh.shadowBlurRadius=9;sh.set()}
   NSColor(calibratedRed:0.87,green:0.66,blue:1,alpha:0.20+0.26*(1-abs(band))).setStroke();p.lineWidth=strand==23 ? 1.15:0.48;p.stroke()
   if strand==23{NSShadow().set()}
  }
  let edge=NSGradient(colorsAndLocations:(NSColor.clear,0.53),(NSColor.black.withAlphaComponent(0.18),0.79),(NSColor.black.withAlphaComponent(0.69),1))!
  edge.draw(fromCenter:NSPoint(x:r.midX,y:r.midY),radius:0,toCenter:NSPoint(x:r.midX,y:r.midY),radius:r.width/2,options:[])
  let reflection=NSBezierPath();reflection.move(to:NSPoint(x:r.minX+r.width*0.10,y:r.minY+r.height*0.72));reflection.curve(to:NSPoint(x:r.minX+r.width*0.60,y:r.minY+r.height*0.97),controlPoint1:NSPoint(x:r.minX+r.width*0.15,y:r.maxY),controlPoint2:NSPoint(x:r.minX+r.width*0.44,y:r.maxY));reflection.curve(to:NSPoint(x:r.minX+r.width*0.30,y:r.minY+r.height*0.68),controlPoint1:NSPoint(x:r.minX+r.width*0.49,y:r.minY+r.height*0.90),controlPoint2:NSPoint(x:r.minX+r.width*0.30,y:r.minY+r.height*0.70));reflection.close()
  NSGradient(starting:NSColor.white.withAlphaComponent(glassTexture == nil ? 0.64:0.08),ending:NSColor.white.withAlphaComponent(0.01))!.draw(in:reflection,angle:305)
  let sheen=NSBezierPath(ovalIn:NSRect(x:r.minX-r.width*0.1,y:r.minY+r.height*0.15,width:r.width*0.30,height:r.height*0.72));NSColor(calibratedRed:1,green:0.68,blue:0.31,alpha:0.08).setFill();sheen.fill()
  NSGraphicsContext.restoreGraphicsState()
  let ring=NSBezierPath(ovalIn:r);ring.append(NSBezierPath(ovalIn:r.insetBy(dx:2.8,dy:2.8)));ring.windingRule = .evenOdd
  NSGradient(colorsAndLocations:(amber,0),(NSColor(calibratedRed:1,green:0.88,blue:0.65,alpha:1),0.32),(violet,0.70),(NSColor(calibratedRed:0.95,green:0.75,blue:1,alpha:1),1))!.draw(in:ring,angle:290)
  let inner=NSBezierPath(ovalIn:r.insetBy(dx:4,dy:4));inner.lineWidth=0.6;NSColor(calibratedRed:0.89,green:0.68,blue:1,alpha:0.35).setStroke();inner.stroke()
  let shine=NSBezierPath();shine.appendArc(withCenter:NSPoint(x:r.midX,y:r.midY),radius:r.width/2-1,startAngle:128,endAngle:184,clockwise:false);let sh=NSShadow();sh.shadowColor=amber;sh.shadowBlurRadius=7;NSGraphicsContext.saveGraphicsState();sh.set();NSColor(calibratedRed:1,green:0.89,blue:0.66,alpha:0.95).setStroke();shine.lineWidth=1.4;shine.stroke();NSGraphicsContext.restoreGraphicsState()
 }
}
final class OrbitSurface:NSView {
 override var isOpaque:Bool {false}
 override func draw(_ dirtyRect:NSRect){
  func point(_ t:CGFloat)->NSPoint{let u=1-t;return NSPoint(x:u*u*u*21+3*u*u*t*64+3*u*t*t*180+t*t*t*223,y:u*u*u*85+3*u*u*t*4+3*u*t*t*4+t*t*t*85)}
  NSGraphicsContext.saveGraphicsState();let glow=NSShadow();glow.shadowColor=NSColor.orange.withAlphaComponent(0.6);glow.shadowBlurRadius=10;glow.set()
  for i in 0..<110 {let t=CGFloat(i)/110,p=NSBezierPath();p.move(to:point(t));p.line(to:point(CGFloat(i+1)/110));p.lineWidth=1.0;p.lineCapStyle = .round
   NSColor(calibratedRed:1,green:0.65,blue:0.24,alpha:pow(sin(.pi*(t+0.0045)),0.85)*0.75).setStroke();p.stroke()
  };NSGraphicsContext.restoreGraphicsState()
 }
}
final class GlassButton:NSButton {
 override func draw(_ dirtyRect:NSRect){
  let r=bounds.insetBy(dx:1,dy:1),circle=NSBezierPath(ovalIn:r)
  NSGraphicsContext.saveGraphicsState();let glow=NSShadow();glow.shadowColor=NSColor.orange.withAlphaComponent(isHighlighted ? 0.65:0.20);glow.shadowBlurRadius=5;glow.set()
  NSGradient(starting:NSColor(calibratedRed:0.39,green:0.22,blue:0.08,alpha:isHighlighted ? 0.95:0.81),ending:NSColor(calibratedRed:0.09,green:0.045,blue:0.06,alpha:0.94))!.draw(in:circle,angle:270)
  circle.lineWidth=1;NSColor(calibratedRed:1,green:0.68,blue:0.29,alpha:0.87).setStroke();circle.stroke();NSGraphicsContext.restoreGraphicsState();super.draw(dirtyRect)
 }
}
final class Controller:NSObject,NSApplicationDelegate {
 var referenceForm:NSPanel?,referenceName=NSTextField(),referenceText=NSTextView(),pickedReference:URL?,currentVoiceIds:[String]=[]
 var widgetScale:Double=1
 var panel:FloatingPanel!,orb=Orb(),buttons:[String:NSButton]=[:],popover=NSPopover(),voice=NSPopUpButton(),volume=NSSlider(),rate=NSSlider(),sensitivity=NSSlider(),sizeSlider=NSSlider(),sizeValue=NSTextField(labelWithString:"100%"),volumeValue=NSTextField(labelWithString:"85%"),sensitivityValue=NSTextField(labelWithString:"1.0×"),rateValue=NSTextField(labelWithString:"1.0×"),allSpaces=NSButton(),lastUpdate=Date(),lastState:[String:Any]=[:],cueSound:NSSound?
 func applicationDidFinishLaunching(_ notification:Notification) {
  NSApp.setActivationPolicy(.accessory)
  panel=FloatingPanel(contentRect:NSRect(x:0,y:0,width:244,height:244),styleMask:[.borderless,.nonactivatingPanel],backing:.buffered,defer:false)
  panel.title="Локальный голос Harness";panel.isOpaque=false;panel.backgroundColor = .clear;panel.hasShadow=false;panel.hidesOnDeactivate=false;panel.isFloatingPanel=true;panel.level = .floating;panel.collectionBehavior=[.canJoinAllSpaces,.fullScreenAuxiliary];panel.isReleasedWhenClosed=false
  let v=OrbitSurface(frame:NSRect(x:0,y:0,width:244,height:244));panel.contentView=v
  orb.frame=NSRect(x:40,y:63,width:164,height:164);v.addSubview(orb)
  let controls:[(String,String,String,CGFloat,CGFloat)]=[("mic","mic","Заглушить микрофон",18,78),("end","xmark","Выключить голос, продолжить работу",156,41),("speaker","speaker.wave.2","Выключить озвучивание",106,28),("settings","gearshape","Настройки голоса",56,41),("stop","stop","Остановить задачу",194,78)]
  for (id,symbol,label,x,y) in controls { let b=GlassButton(frame:NSRect(x:x,y:y,width:34,height:34));b.title="";b.image=NSImage(systemSymbolName:symbol,accessibilityDescription:label);b.imagePosition = .imageOnly;b.symbolConfiguration=NSImage.SymbolConfiguration(pointSize:19,weight:.medium);b.bezelStyle = .circular;b.isBordered=false;b.wantsLayer=true;b.layer?.cornerRadius=17;b.layer?.backgroundColor=NSColor.clear.cgColor;b.layer?.borderColor=NSColor.white.withAlphaComponent(0.16).cgColor;b.layer?.borderWidth=0;b.contentTintColor=NSColor(calibratedRed:1,green:0.88,blue:0.66,alpha:1);b.toolTip=label;b.setAccessibilityLabel(label);b.identifier=NSUserInterfaceItemIdentifier(id);b.target=self;b.action=#selector(action(_:));v.addSubview(b);buttons[id]=b }
  setupPopover()
  Timer.scheduledTimer(withTimeInterval:0.0333,repeats:true){_ in if self.panel.isVisible && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {self.orb.flow+=0.03;self.orb.displayEnergy+=(self.orb.energy-self.orb.displayEnergy)*(self.orb.energy>self.orb.displayEnergy ? 0.52:0.22);self.orb.needsDisplay=true} }
  if let screen=NSScreen.main { let r=screen.visibleFrame;panel.setFrameOrigin(NSPoint(x:r.maxX-268,y:r.minY+70)) };panel.orderFrontRegardless()
  emit(["event":"ready","allSpaces":panel.collectionBehavior.contains(.canJoinAllSpaces),"transparent": !panel.isOpaque,"nonactivating":panel.styleMask.contains(.nonactivatingPanel)])
  DispatchQueue.global(qos:.utility).async { while let line=readLine() { guard let d=line.data(using:.utf8),let value=(try? JSONSerialization.jsonObject(with:d)) as? [String:Any] else {continue};DispatchQueue.main.async { self.receive(value) } };DispatchQueue.main.async { NSApp.terminate(nil) } }
  Timer.scheduledTimer(withTimeInterval:1,repeats:true){_ in if Date().timeIntervalSince(self.lastUpdate)>30 { emit(["action":"closed"]);NSApp.terminate(nil) } }
 }
 func setupPopover() {
  let vc=NSViewController();vc.view=NSView(frame:NSRect(x:0,y:0,width:266,height:318))
  let title=NSTextField(labelWithString:"Голос и звук");title.font = .boldSystemFont(ofSize:13);title.frame=NSRect(x:16,y:284,width:220,height:20);vc.view.addSubview(title)
  voice=NSPopUpButton(frame:NSRect(x:14,y:244,width:238,height:26));voice.target=self;voice.action=#selector(changeVoice);voice.setAccessibilityLabel("Голос ответов");vc.view.addSubview(voice)
  func row(_ text:String,_ y:CGFloat,_ slider:NSSlider,_ value:NSTextField){let label=NSTextField(labelWithString:text);label.frame=NSRect(x:16,y:y+4,width:64,height:20);label.font = .systemFont(ofSize:11);vc.view.addSubview(label);slider.frame=NSRect(x:80,y:y,width:126,height:24);slider.isContinuous=true;vc.view.addSubview(slider);value.frame=NSRect(x:210,y:y+4,width:42,height:20);value.font = .monospacedDigitSystemFont(ofSize:11,weight:.regular);vc.view.addSubview(value)}
  sizeSlider=NSSlider(value:1,minValue:0.6,maxValue:1.6,target:self,action:#selector(changeSize));sizeSlider.setAccessibilityLabel("Размер виджета");row("Размер",210,sizeSlider,sizeValue)
  sensitivity=NSSlider(value:1,minValue:0.5,maxValue:3,target:self,action:#selector(changeSensitivity));sensitivity.setAccessibilityLabel("Чувствительность микрофона");sensitivity.toolTip="Выше — лучше слышен тихий голос, но сильнее фоновый шум. 1× — обычная чувствительность.";row("Микрофон",178,sensitivity,sensitivityValue)
  volume=NSSlider(value:0.85,minValue:0,maxValue:1,target:self,action:#selector(changeVolume));volume.setAccessibilityLabel("Громкость ответа");row("Громкость",146,volume,volumeValue)
  rate=NSSlider(value:1,minValue:0.7,maxValue:2,target:self,action:#selector(changeRate));rate.setAccessibilityLabel("Скорость ответа");row("Скорость",114,rate,rateValue)
  allSpaces=NSButton(checkboxWithTitle:"На всех рабочих столах",target:self,action:#selector(changeSpaces));allSpaces.state = .on;allSpaces.frame=NSRect(x:14,y:76,width:238,height:24);vc.view.addSubview(allSpaces)
  let sample=NSButton(title:"Послушать",target:self,action:#selector(preview));sample.frame=NSRect(x:14,y:42,width:238,height:26);vc.view.addSubview(sample)
  let add=NSButton(title:"Добавить голосовой эталон",target:self,action:#selector(addReference));add.frame=NSRect(x:14,y:8,width:238,height:28);add.setAccessibilityLabel("Добавить голосовой эталон");vc.view.addSubview(add)
  popover.contentViewController=vc;popover.behavior = .transient;popover.animates = !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
 }
 func applySize(_ requested:Double){let value=max(0.6,min(1.6,requested));guard abs(value-widgetScale)>0.001 else{return};widgetScale=value;let old=panel.frame,screen=panel.screen?.visibleFrame ?? NSScreen.main!.visibleFrame;let side=min(244*value,min(screen.width-24,screen.height-24));panel.setContentSize(NSSize(width:side,height:side));panel.contentView?.setBoundsSize(NSSize(width:244,height:244));panel.setFrameOrigin(NSPoint(x:max(screen.minX+12,min(screen.maxX-side-12,old.midX-side/2)),y:max(screen.minY+12,min(screen.maxY-side-12,old.midY-side/2))))}
 @objc func changeSize(){sizeValue.stringValue=String(format:"%.0f%%",sizeSlider.doubleValue*100);applySize(sizeSlider.doubleValue);emit(["action":"size","value":sizeSlider.doubleValue])}
 @objc func addReference(){
  popover.performClose(nil);let picker=NSOpenPanel();picker.title="Голосовой образец 3–30 секунд";picker.message="WAV, MP3, M4A или AIFF. Образец сохраняется только на этом Mac.";picker.allowedContentTypes=[.audio];picker.allowsMultipleSelection=false;picker.canChooseDirectories=false
  picker.begin{response in guard response == .OK,let url=picker.url else{return};self.pickedReference=url;self.showReferenceForm(url)}
 }
 func showReferenceForm(_ url:URL){
  referenceForm?.close();let f=NSPanel(contentRect:NSRect(x:0,y:0,width:344,height:320),styleMask:[.titled,.closable],backing:.buffered,defer:false);f.title="Голосовой эталон";f.isReleasedWhenClosed=false;f.level = .floating;f.center();referenceForm=f
  let view=f.contentView!;let nameLabel=NSTextField(labelWithString:"Название голоса");nameLabel.frame=NSRect(x:18,y:260,width:300,height:20);view.addSubview(nameLabel)
  referenceName=NSTextField(frame:NSRect(x:18,y:229,width:308,height:28));referenceName.stringValue=String(url.deletingPathExtension().lastPathComponent.prefix(64));referenceName.setAccessibilityLabel("Название голоса");view.addSubview(referenceName)
  let source=NSTextField(labelWithString:url.lastPathComponent);source.lineBreakMode = .byTruncatingMiddle;source.frame=NSRect(x:18,y:199,width:308,height:20);source.font = .systemFont(ofSize:11);view.addSubview(source)
  let hint=NSTextField(wrappingLabelWithString:"Текст образца можно оставить пустым: его распознает Handy.");hint.frame=NSRect(x:18,y:158,width:308,height:34);hint.font = .systemFont(ofSize:11);view.addSubview(hint)
  let scroll=NSScrollView(frame:NSRect(x:18,y:76,width:308,height:76));scroll.borderType = .bezelBorder;scroll.hasVerticalScroller=true;referenceText=NSTextView(frame:scroll.bounds);referenceText.isRichText=false;referenceText.font = .systemFont(ofSize:12);referenceText.setAccessibilityLabel("Текст голосового образца");scroll.documentView=referenceText;view.addSubview(scroll)
  let note=NSTextField(labelWithString:"Свой голос или образец с разрешением.");note.frame=NSRect(x:18,y:50,width:308,height:18);note.font = .systemFont(ofSize:10);note.textColor = .secondaryLabelColor;view.addSubview(note)
  let save=NSButton(title:"Добавить",target:self,action:#selector(saveReference));save.frame=NSRect(x:210,y:10,width:116,height:30);save.keyEquivalent="\r";view.addSubview(save);f.makeKeyAndOrderFront(nil);f.makeFirstResponder(referenceName)
 }
 @objc func saveReference(){guard let url=pickedReference else{return};let name=referenceName.stringValue.trimmingCharacters(in:.whitespacesAndNewlines);guard !name.isEmpty&&name.count<=64 else{NSSound.beep();return};emit(["action":"reference_import","value":["path":url.path,"name":name,"transcript":referenceText.string]]);referenceForm?.close();pickedReference=nil}
 func cue(_ name:String="click") { guard let url=Bundle.main.resourceURL?.appendingPathComponent("cues/"+name+".wav"),let sound=NSSound(contentsOf:url,byReference:true) else{return};cueSound?.stop();cueSound=sound;sound.volume=Float(max(0.15,volume.doubleValue));sound.play() }
 @objc func action(_ sender:NSButton) { let id=sender.identifier!.rawValue;if id != "end" {cue(id=="mic" ? ((lastState["micMuted"] as? Bool ?? false) ? "unmute":"mute"):"click")};if id=="settings" { if popover.isShown {popover.performClose(nil)}else{popover.show(relativeTo:sender.bounds,of:sender,preferredEdge:.minX)} }else{emit(["action":id])} }
 @objc func changeVoice(){cue();if let id=voice.selectedItem?.representedObject as? String{emit(["action":"voice","value":id])}}
 @objc func changeVolume(){volumeValue.stringValue=String(format:"%.0f%%",volume.doubleValue*100);emit(["action":"volume","value":volume.doubleValue])}
 @objc func changeSensitivity(){sensitivityValue.stringValue=String(format:"%.1f×",sensitivity.doubleValue);emit(["action":"sensitivity","value":sensitivity.doubleValue])}
 @objc func changeRate(){rateValue.stringValue=String(format:"%.2g×",rate.doubleValue);emit(["action":"rate","value":rate.doubleValue])}
 @objc func changeSpaces(){cue();emit(["action":"spaces","value":allSpaces.state == .on])}
 @objc func preview(){cue();emit(["action":"sample"])}
 func receive(_ s:[String:Any]) {
  lastUpdate=Date();lastState=s;if s["quit"] as? Bool == true {NSApp.terminate(nil);return}
  if let catalog=s["voices"] as? [[String:Any]] {let ids=catalog.compactMap{$0["id"] as? String};if ids != currentVoiceIds {currentVoiceIds=ids;voice.removeAllItems();for v in catalog {voice.addItem(withTitle:v["label"] as? String ?? "");voice.lastItem?.representedObject=v["id"] as? String}}}
  if let id=s["voice"] as? String,let item=voice.itemArray.first(where:{$0.representedObject as? String == id}) {voice.select(item)}
  if let x=s["volume"] as? Double {volume.doubleValue=x;volumeValue.stringValue=String(format:"%.0f%%",x*100)}
  if let x=s["size"] as? Double {sizeSlider.doubleValue=x;sizeValue.stringValue=String(format:"%.0f%%",x*100);applySize(x)}
  if let x=s["sensitivity"] as? Double {sensitivity.doubleValue=x;sensitivityValue.stringValue=String(format:"%.1f×",x)}
  if let x=s["rate"] as? Double {rate.doubleValue=x;rateValue.stringValue=String(format:"%.2g×",x)}
  let muted=s["micMuted"] as? Bool ?? false,quiet=s["speakerMuted"] as? Bool ?? false
  buttons["mic"]?.image=NSImage(systemSymbolName:muted ? "mic.slash":"mic",accessibilityDescription:muted ? "Включить микрофон":"Заглушить микрофон")
  buttons["speaker"]?.image=NSImage(systemSymbolName:quiet ? "speaker.slash":"speaker.wave.2",accessibilityDescription:quiet ? "Включить озвучивание":"Выключить озвучивание")
  orb.phase=s["phase"] as? String ?? "idle";orb.energy=s["energy"] as? CGFloat ?? 0;orb.alphaValue=1;orb.toolTip=s["status"] as? String;orb.needsDisplay=true
 }
}
let app=NSApplication.shared,controller=Controller();app.delegate=controller;app.run()
