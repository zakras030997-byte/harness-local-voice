import Cocoa
let image=NSImage(size:NSSize(width:1024,height:1024));image.lockFocus()
NSColor(calibratedRed:0.17,green:0.10,blue:0.25,alpha:1).setFill();NSBezierPath(roundedRect:NSRect(x:0,y:0,width:1024,height:1024),xRadius:220,yRadius:220).fill()
let circle=NSBezierPath(ovalIn:NSRect(x:128,y:128,width:768,height:768));NSColor(calibratedRed:0.52,green:0.28,blue:0.90,alpha:1).setFill();circle.fill()
NSColor.white.setStroke();for (i,height) in [120.0,280.0,410.0,220.0,100.0].enumerated(){let x=336.0+Double(i)*88;let p=NSBezierPath();p.lineWidth=38;p.lineCapStyle = .round;p.move(to:NSPoint(x:x,y:512-height/2));p.line(to:NSPoint(x:x,y:512+height/2));p.stroke()};image.unlockFocus()
let rep=NSBitmapImageRep(data:image.tiffRepresentation!)!;try rep.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:CommandLine.arguments[1]))
