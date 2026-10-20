import Cocoa

func color(_ value: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((value >> 16) & 255)/255, green: CGFloat((value >> 8) & 255)/255, blue: CGFloat(value & 255)/255, alpha: alpha)
}
func png(_ size: Int) -> Data {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    let scale = NSAffineTransform(); scale.scale(by: CGFloat(size)/1024); scale.concat()
    let tile = NSBezierPath(roundedRect: NSRect(x: 42, y: 42, width: 940, height: 940), xRadius: 218, yRadius: 218)
    NSGradient(starting: color(0x14253f), ending: color(0x050912))!.draw(in: tile, angle: -50)
    color(0x406080, 0.4).setStroke(); tile.lineWidth = 2; tile.stroke()
    NSGradient(starting: color(0x66caff, 0.22), ending: color(0x66caff, 0))!.draw(in: NSBezierPath(ovalIn: NSRect(x: 150, y: 150, width: 724, height: 724)), relativeCenterPosition: .zero)
    for (angle, tint) in [(32.0, UInt32(0x00efff)), (-58.0, UInt32(0xff28d4))] {
        NSGraphicsContext.saveGraphicsState()
        let transform = NSAffineTransform(); transform.translateX(by: 512, yBy: 512); transform.rotate(byDegrees: CGFloat(angle)); transform.concat()
        let ring = NSBezierPath(ovalIn: NSRect(x: -309, y: -124, width: 618, height: 248)); ring.lineWidth = 18; color(tint).setStroke(); ring.stroke()
        NSGraphicsContext.restoreGraphicsState()
    }
    let crystal = NSBezierPath(); crystal.move(to: NSPoint(x: 512, y: 633)); crystal.line(to: NSPoint(x: 585, y: 512)); crystal.line(to: NSPoint(x: 512, y: 391)); crystal.line(to: NSPoint(x: 439, y: 512)); crystal.close(); color(0xd7faff).setFill(); crystal.fill()
    let inner = NSBezierPath(); inner.move(to: NSPoint(x: 512, y: 577)); inner.line(to: NSPoint(x: 552, y: 512)); inner.line(to: NSPoint(x: 512, y: 447)); inner.line(to: NSPoint(x: 472, y: 512)); inner.close(); color(0x67d6f1).setFill(); inner.fill()
    let satellite = NSBezierPath(ovalIn: NSRect(x: 707, y: 707, width: 48, height: 48)); color(0xff28d4).setFill(); satellite.fill(); satellite.lineWidth = 9; color(0x080d1c).setStroke(); satellite.stroke()
    NSGraphicsContext.restoreGraphicsState()
    return bitmap.representation(using: .png, properties: [:])!
}
func int32(_ value: Int) -> Data { var n = UInt32(value).bigEndian; return withUnsafeBytes(of: &n) { Data($0) } }
var chunks = Data()
for (tag, size) in [("icp4",16),("icp5",32),("icp6",64),("ic07",128),("ic08",256),("ic09",512),("ic10",1024)] {
    let image = png(size); chunks.append(Data(tag.utf8)); chunks.append(int32(image.count+8)); chunks.append(image)
}
var icon = Data("icns".utf8); icon.append(int32(chunks.count+8)); icon.append(chunks)
try icon.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
if CommandLine.arguments.count > 2 { try png(512).write(to: URL(fileURLWithPath: CommandLine.arguments[2])) }
