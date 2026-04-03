#!/usr/bin/env swift
import AppKit
import Foundation

let iconsetDir = "StickyNote.iconset"
try! FileManager.default.createDirectory(atPath: iconsetDir,
                                          withIntermediateDirectories: true,
                                          attributes: nil)

func drawIcon(size: Int) -> NSImage {
    let s = CGFloat(size)
    let image = NSImage(size: NSSize(width: s, height: s))
    image.lockFocus()

    // Colors
    let yellow     = NSColor(calibratedRed: 1.00, green: 0.95, blue: 0.50, alpha: 1.0)
    let yellowDark = NSColor(calibratedRed: 0.80, green: 0.72, blue: 0.18, alpha: 1.0)
    let foldFront  = NSColor(calibratedRed: 0.96, green: 0.90, blue: 0.62, alpha: 1.0)
    let foldShadow = NSColor(calibratedRed: 0.70, green: 0.62, blue: 0.10, alpha: 0.60)
    let lineColor  = NSColor(calibratedRed: 0.45, green: 0.38, blue: 0.04, alpha: 0.50)

    let pad      = s * 0.07
    let fold     = s >= 32 ? s * 0.22 : 0
    let radius   = s * 0.12

    let r = NSRect(x: pad, y: pad, width: s - 2*pad, height: s - 2*pad)

    // --- Body path: rounded rect with top-right corner clipped for fold ---
    let body = NSBezierPath()
    // bottom-left corner
    body.move(to: NSPoint(x: r.minX + radius, y: r.minY))
    body.line(to: NSPoint(x: r.maxX - radius, y: r.minY))
    // bottom-right corner
    body.appendArc(withCenter: NSPoint(x: r.maxX - radius, y: r.minY + radius),
                   radius: radius, startAngle: 270, endAngle: 0)
    // right side up to fold cut
    body.line(to: NSPoint(x: r.maxX, y: r.maxY - fold))
    // diagonal fold cut
    body.line(to: NSPoint(x: r.maxX - fold, y: r.maxY))
    // top edge
    body.line(to: NSPoint(x: r.minX + radius, y: r.maxY))
    // top-left corner
    body.appendArc(withCenter: NSPoint(x: r.minX + radius, y: r.maxY - radius),
                   radius: radius, startAngle: 90, endAngle: 180)
    // left side down
    body.line(to: NSPoint(x: r.minX, y: r.minY + radius))
    // bottom-left corner arc
    body.appendArc(withCenter: NSPoint(x: r.minX + radius, y: r.minY + radius),
                   radius: radius, startAngle: 180, endAngle: 270)
    body.close()

    // Drop shadow
    NSGraphicsContext.current?.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.28)
    shadow.shadowOffset = NSSize(width: s * 0.02, height: -(s * 0.025))
    shadow.shadowBlurRadius = s * 0.07
    shadow.set()
    yellow.setFill()
    body.fill()
    NSGraphicsContext.current?.restoreGraphicsState()

    // Body fill (no shadow this time, clean)
    yellow.setFill()
    body.fill()

    // Body border
    yellowDark.setStroke()
    body.lineWidth = max(0.5, s * 0.018)
    body.stroke()

    // --- Fold triangle ---
    if fold > 0 {
        // Shadow of fold
        let foldShadowPath = NSBezierPath()
        foldShadowPath.move(to: NSPoint(x: r.maxX - fold, y: r.maxY))
        foldShadowPath.line(to: NSPoint(x: r.maxX,        y: r.maxY - fold))
        foldShadowPath.line(to: NSPoint(x: r.maxX - fold, y: r.maxY - fold))
        foldShadowPath.close()
        foldShadow.setFill()
        foldShadowPath.fill()

        // Fold front (the curled page)
        let foldPath = NSBezierPath()
        foldPath.move(to: NSPoint(x: r.maxX - fold, y: r.maxY))
        foldPath.line(to: NSPoint(x: r.maxX,        y: r.maxY - fold))
        foldPath.line(to: NSPoint(x: r.maxX - fold, y: r.maxY - fold))
        foldPath.close()
        foldFront.setFill()
        foldPath.fill()

        // Fold border lines
        yellowDark.setStroke()
        foldPath.lineWidth = max(0.5, s * 0.018)
        foldPath.stroke()

        // Diagonal crease line
        let crease = NSBezierPath()
        crease.move(to: NSPoint(x: r.maxX - fold, y: r.maxY))
        crease.line(to: NSPoint(x: r.maxX, y: r.maxY - fold))
        yellowDark.setStroke()
        crease.lineWidth = max(0.5, s * 0.018)
        crease.stroke()
    }

    // --- Text lines ---
    if size >= 32 {
        lineColor.setStroke()
        let lx0     = r.minX + s * 0.13
        let lx1     = r.maxX - s * 0.13 - (fold > 0 ? fold * 0.25 : 0)
        let lineW   = max(1.0, s * 0.045)
        let count   = size >= 64 ? 4 : 3
        let yStart  = r.minY + r.height * 0.22
        let spacing = r.height * 0.18

        for i in 0..<count {
            let y   = yStart + CGFloat(i) * spacing
            let end = i == count - 1 ? lx0 + (lx1 - lx0) * 0.55 : lx1
            let line = NSBezierPath()
            line.move(to: NSPoint(x: lx0, y: y))
            line.line(to: NSPoint(x: end, y: y))
            line.lineWidth   = lineW
            line.lineCapStyle = .round
            line.stroke()
        }
    }

    image.unlockFocus()
    return image
}

func savePNG(_ image: NSImage, to path: String) {
    guard let tiff   = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png    = bitmap.representation(using: .png, properties: [:]) else {
        print("Error generando PNG: \(path)"); return
    }
    try! png.write(to: URL(fileURLWithPath: path))
}

// iconset standard entries
let entries: [(file: String, px: Int)] = [
    ("icon_16x16.png",      16),
    ("icon_16x16@2x.png",   32),
    ("icon_32x32.png",      32),
    ("icon_32x32@2x.png",   64),
    ("icon_128x128.png",   128),
    ("icon_128x128@2x.png",256),
    ("icon_256x256.png",   256),
    ("icon_256x256@2x.png",512),
    ("icon_512x512.png",   512),
    ("icon_512x512@2x.png",1024)
]

var cache: [Int: NSImage] = [:]
for entry in entries {
    if cache[entry.px] == nil { cache[entry.px] = drawIcon(size: entry.px) }
    savePNG(cache[entry.px]!, to: "\(iconsetDir)/\(entry.file)")
    print("  \(entry.file)")
}
print("Iconset listo.")
