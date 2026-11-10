import AppKit

func emit(_ value: [String:Any]) { if let d = try? JSONSerialization.data(withJSONObject:value) { FileHandle.standardOutput.write(d); FileHandle.standardOutput.write(Data([10])) } }
final class FloatingPanel: NSPanel { override var canBecomeKey: Bool { true }; override var canBecomeMain: Bool { false } }
final class Orb: NSView {
 var phase="idle", energy:CGFloat=0,flow:CGFloat=0
 override var isOpaque:Bool { false }
 override func mouseDown(with event:NSEvent) { window?.performDrag(with:event) }
 override func draw(_ dirtyRect:NSRect) {
  let inset:CGFloat = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? 7 : 7-energy*3
  let r=bounds.insetBy(dx:inset,dy:inset); let path=NSBezierPath(ovalIn:r)
  NSGraphicsContext.saveGraphicsState(); let shadow=NSShadow();shadow.shadowColor=NSColor.systemPurple.withAlphaComponent(0.55);shadow.shadowBlurRadius=18;shadow.set();NSColor.systemPurple.setFill();path.fill(); NSGraphicsContext.restoreGraphicsState()
  NSGraphicsContext.saveGraphicsState();path.addClip()
  let colors=[NSColor(calibratedRed:0.34,green:0.40,blue:0.86,alpha:1),NSColor(calibratedRed:0.57,green:0.42,blue:0.88,alpha:1),NSColor(calibratedRed:0.89,green:0.85,blue:1,alpha:1),NSColor.white]
  NSGradient(colors:colors)!.draw(in:r,angle:300)
  NSGraphicsContext.restoreGraphicsState()
  NSGraphicsContext.saveGraphicsState();path.addClip()
  let fogX:CGFloat = r.midX-r.width*0.9+sin(flow)*8
  let fogRect=NSRect(x:fogX,y:r.minY-r.height*0.3,width:r.width*1.6,height:r.height*0.8)
  let fog=NSBezierPath(ovalIn:fogRect);let mist=NSShadow();mist.shadowColor=NSColor.white.withAlphaComponent(0.5);mist.shadowBlurRadius=22;mist.set();NSColor.white.withAlphaComponent(0.1).setFill();fog.fill();NSGraphicsContext.restoreGraphicsState()
  let edge=NSGradient(colorsAndLocations:(NSColor.clear,0.54),(NSColor.black.withAlphaComponent(0.06),0.72),(NSColor.black.withAlphaComponent(0.48),1.0))!
  NSGraphicsContext.saveGraphicsState();path.addClip();edge.draw(fromCenter:NSPoint(x:r.midX,y:r.midY),radius:0,toCenter:NSPoint(x:r.midX,y:r.midY),radius:r.width/2,options:[]);NSGraphicsContext.restoreGraphicsState()
  NSColor(calibratedRed:0.28,green:0.13,blue:0.44,alpha:1).setStroke();path.lineWidth=2.5;path.stroke()
 }
}
final class Controller:NSObject,NSApplicationDelegate {
 var panel:FloatingPanel!,orb=Orb(),buttons:[String:NSButton]=[:],popover=NSPopover(),voice=NSPopUpButton(),volume=NSSlider(),rate=NSSlider(),rateValue=NSTextField(labelWithString:"1.0×"),allSpaces=NSButton(),lastUpdate=Date(),lastState:[String:Any]=[:],cueSound:NSSound?
 func applicationDidFinishLaunching(_ notification:Notification) {
  NSApp.setActivationPolicy(.accessory)
  panel=FloatingPanel(contentRect:NSRect(x:0,y:0,width:244,height:244),styleMask:[.borderless,.nonactivatingPanel],backing:.buffered,defer:false)
  panel.title="Локальный голос Harness";panel.isOpaque=false;panel.backgroundColor = .clear;panel.hasShadow=false;panel.hidesOnDeactivate=false;panel.isFloatingPanel=true;panel.level = .floating;panel.collectionBehavior=[.canJoinAllSpaces,.fullScreenAuxiliary];panel.isReleasedWhenClosed=false
  let v=NSView(frame:NSRect(x:0,y:0,width:244,height:244));panel.contentView=v
  orb.frame=NSRect(x:40,y:63,width:164,height:164);v.addSubview(orb)
  let controls:[(String,String,String,CGFloat,CGFloat)]=[("mic","mic","Заглушить микрофон",18,78),("end","xmark","Выключить голос, продолжить работу",56,41),("speaker","speaker.wave.2","Выключить озвучивание",106,28),("settings","gearshape","Настройки голоса",194,78),("stop","stop","Остановить задачу",156,41)]
  for (id,symbol,label,x,y) in controls { let b=NSButton(frame:NSRect(x:x,y:y,width:32,height:32));b.title="";b.image=NSImage(systemSymbolName:symbol,accessibilityDescription:label);b.imagePosition = .imageOnly;b.bezelStyle = .circular;b.isBordered=false;b.wantsLayer=true;b.layer?.cornerRadius=16;b.layer?.backgroundColor=NSColor(calibratedRed:0.17,green:0.13,blue:0.24,alpha:0.94).cgColor;b.layer?.borderColor=NSColor.white.withAlphaComponent(0.16).cgColor;b.layer?.borderWidth=1;b.contentTintColor=NSColor(calibratedWhite:0.94,alpha:1);b.toolTip=label;b.setAccessibilityLabel(label);b.identifier=NSUserInterfaceItemIdentifier(id);b.target=self;b.action=#selector(action(_:));v.addSubview(b);buttons[id]=b }
  setupPopover()
  Timer.scheduledTimer(withTimeInterval:0.08,repeats:true){_ in if !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {self.orb.flow+=0.025;self.orb.needsDisplay=true} }
  if let screen=NSScreen.main { let r=screen.visibleFrame;panel.setFrameOrigin(NSPoint(x:r.maxX-268,y:r.minY+70)) };panel.orderFrontRegardless()
  emit(["event":"ready","allSpaces":panel.collectionBehavior.contains(.canJoinAllSpaces),"transparent": !panel.isOpaque,"nonactivating":panel.styleMask.contains(.nonactivatingPanel)])
  DispatchQueue.global(qos:.utility).async { while let line=readLine() { guard let d=line.data(using:.utf8),let value=(try? JSONSerialization.jsonObject(with:d)) as? [String:Any] else {continue};DispatchQueue.main.async { self.receive(value) } };DispatchQueue.main.async { NSApp.terminate(nil) } }
  Timer.scheduledTimer(withTimeInterval:1,repeats:true){_ in if Date().timeIntervalSince(self.lastUpdate)>30 { emit(["action":"closed"]);NSApp.terminate(nil) } }
 }
 func setupPopover() {
  let vc=NSViewController();vc.view=NSView(frame:NSRect(x:0,y:0,width:266,height:216))
  let title=NSTextField(labelWithString:"Голос и звук");title.font = .boldSystemFont(ofSize:13);title.frame=NSRect(x:16,y:182,width:220,height:20);vc.view.addSubview(title)
  voice=NSPopUpButton(frame:NSRect(x:14,y:142,width:238,height:26));voice.target=self;voice.action=#selector(changeVoice);voice.setAccessibilityLabel("Голос ответов");vc.view.addSubview(voice)
  volume=NSSlider(value:0.85,minValue:0,maxValue:1,target:self,action:#selector(changeVolume));volume.frame=NSRect(x:16,y:108,width:232,height:24);volume.setAccessibilityLabel("Громкость ответа");vc.view.addSubview(volume)
  let rateTitle=NSTextField(labelWithString:"Скорость");rateTitle.frame=NSRect(x:16,y:76,width:62,height:20);rateTitle.font = .systemFont(ofSize:11);vc.view.addSubview(rateTitle)
  rate=NSSlider(value:1,minValue:0.7,maxValue:2,target:self,action:#selector(changeRate));rate.isContinuous=true;rate.frame=NSRect(x:80,y:72,width:126,height:24);rate.setAccessibilityLabel("Скорость ответа");vc.view.addSubview(rate)
  rateValue.frame=NSRect(x:210,y:76,width:42,height:20);rateValue.font = .monospacedDigitSystemFont(ofSize:11,weight:.regular);vc.view.addSubview(rateValue)
  allSpaces=NSButton(checkboxWithTitle:"На всех рабочих столах",target:self,action:#selector(changeSpaces));allSpaces.state = .on;allSpaces.frame=NSRect(x:14,y:37,width:238,height:24);vc.view.addSubview(allSpaces)
  let sample=NSButton(title:"Послушать",target:self,action:#selector(preview));sample.frame=NSRect(x:14,y:6,width:238,height:26);vc.view.addSubview(sample)
  popover.contentViewController=vc;popover.behavior = .transient;popover.animates = !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
 }
 func cue(_ name:String="click") { guard let url=Bundle.main.resourceURL?.appendingPathComponent("cues/"+name+".wav"),let sound=NSSound(contentsOf:url,byReference:true) else{return};cueSound?.stop();cueSound=sound;sound.volume=Float(max(0.15,volume.doubleValue));sound.play() }
 @objc func action(_ sender:NSButton) { let id=sender.identifier!.rawValue;if id != "end" {cue(id=="mic" ? ((lastState["micMuted"] as? Bool ?? false) ? "unmute":"mute"):"click")};if id=="settings" { if popover.isShown {popover.performClose(nil)}else{popover.show(relativeTo:sender.bounds,of:sender,preferredEdge:.minX)} }else{emit(["action":id])} }
 @objc func changeVoice(){cue();if let id=voice.selectedItem?.representedObject as? String{emit(["action":"voice","value":id])}}
 @objc func changeVolume(){emit(["action":"volume","value":volume.doubleValue])}
 @objc func changeRate(){rateValue.stringValue=String(format:"%.2g×",rate.doubleValue);emit(["action":"rate","value":rate.doubleValue])}
 @objc func changeSpaces(){cue();emit(["action":"spaces","value":allSpaces.state == .on])}
 @objc func preview(){cue();emit(["action":"sample"])}
 func receive(_ s:[String:Any]) {
  lastUpdate=Date();lastState=s;if s["quit"] as? Bool == true {NSApp.terminate(nil);return}
  if let catalog=s["voices"] as? [[String:String]],voice.numberOfItems==0 {for v in catalog {voice.addItem(withTitle:v["label"] ?? "");voice.lastItem?.representedObject=v["id"]}}
  if let id=s["voice"] as? String,let item=voice.itemArray.first(where:{$0.representedObject as? String == id}) {voice.select(item)}
  if let x=s["volume"] as? Double {volume.doubleValue=x}
  if let x=s["rate"] as? Double {rate.doubleValue=x;rateValue.stringValue=String(format:"%.2g×",x)}
  let muted=s["micMuted"] as? Bool ?? false,quiet=s["speakerMuted"] as? Bool ?? false
  buttons["mic"]?.image=NSImage(systemSymbolName:muted ? "mic.slash":"mic",accessibilityDescription:muted ? "Включить микрофон":"Заглушить микрофон")
  buttons["speaker"]?.image=NSImage(systemSymbolName:quiet ? "speaker.slash":"speaker.wave.2",accessibilityDescription:quiet ? "Включить озвучивание":"Выключить озвучивание")
  orb.phase=s["phase"] as? String ?? "idle";orb.energy=s["energy"] as? CGFloat ?? 0;orb.alphaValue=muted ? 0.6:1;orb.toolTip=s["status"] as? String;orb.needsDisplay=true
 }
}
let app=NSApplication.shared,controller=Controller();app.delegate=controller;app.run()
