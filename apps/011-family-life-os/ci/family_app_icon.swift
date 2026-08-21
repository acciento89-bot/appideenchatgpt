#!/usr/bin/env swift
import AppKit
import Foundation
import ImageIO

let defaultPath = "apps/011-family-life-os/prototype/FamilyLifePrototype/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
let arguments = Array(CommandLine.arguments.dropFirst())
let mode = arguments.first ?? "verify"
let path = arguments.count > 1 ? arguments[1] : defaultPath

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("ERROR: \(message)\n".utf8))
    exit(1)
}

func roundedRect(_ rect: NSRect, radius: CGFloat, color: NSColor) {
    color.setFill()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}

func generateIcon(at outputPath: String) throws {
    let width = 1024
    let height = 1024
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: width,
        pixelsHigh: height,
        bitsPerSample: 8,
        samplesPerPixel: 3,
        hasAlpha: false,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bitmapFormat: [],
        bytesPerRow: 0,
        bitsPerPixel: 0
    ), let graphics = NSGraphicsContext(bitmapImageRep: bitmap) else {
        fail("Could not create RGB bitmap context")
    }

    bitmap.size = NSSize(width: width, height: height)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphics
    graphics.imageInterpolation = .high
    graphics.shouldAntialias = true

    let canvas = NSRect(x: 0, y: 0, width: width, height: height)
    let start = NSColor(calibratedRed: 46/255, green: 63/255, blue: 142/255, alpha: 1)
    let end = NSColor(calibratedRed: 103/255, green: 115/255, blue: 220/255, alpha: 1)
    guard let gradient = NSGradient(starting: start, ending: end) else {
        fail("Could not create icon gradient")
    }
    gradient.draw(in: canvas, angle: -35)

    NSColor.white.withAlphaComponent(0.055).setFill()
    NSBezierPath(ovalIn: NSRect(x: 168, y: 168, width: 688, height: 688)).fill()

    // Gather -> Order: three calm incoming pieces converge into one organized form.
    roundedRect(NSRect(x: 140, y: 438, width: 260, height: 148), radius: 74,
                color: NSColor(calibratedRed: 244/255, green: 133/255, blue: 122/255, alpha: 1))
    roundedRect(NSRect(x: 438, y: 624, width: 148, height: 260), radius: 74,
                color: NSColor(calibratedRed: 145/255, green: 207/255, blue: 245/255, alpha: 1))
    roundedRect(NSRect(x: 624, y: 438, width: 260, height: 148), radius: 74,
                color: NSColor(calibratedRed: 247/255, green: 190/255, blue: 94/255, alpha: 1))

    // Slight overlaps make the direction toward the center obvious at small sizes.
    roundedRect(NSRect(x: 300, y: 462, width: 150, height: 100), radius: 50,
                color: NSColor(calibratedRed: 244/255, green: 133/255, blue: 122/255, alpha: 1))
    roundedRect(NSRect(x: 462, y: 574, width: 100, height: 150), radius: 50,
                color: NSColor(calibratedRed: 145/255, green: 207/255, blue: 245/255, alpha: 1))
    roundedRect(NSRect(x: 574, y: 462, width: 150, height: 100), radius: 50,
                color: NSColor(calibratedRed: 247/255, green: 190/255, blue: 94/255, alpha: 1))

    let shadow = NSShadow()
    shadow.shadowColor = NSColor(calibratedWhite: 0.04, alpha: 0.24)
    shadow.shadowBlurRadius = 28
    shadow.shadowOffset = NSSize(width: 0, height: -12)
    shadow.set()
    roundedRect(NSRect(x: 330, y: 330, width: 364, height: 364), radius: 105,
                color: NSColor(calibratedRed: 248/255, green: 249/255, blue: 1, alpha: 1))

    NSShadow().set()
    let orderColor = NSColor(calibratedRed: 74/255, green: 86/255, blue: 173/255, alpha: 1)
    roundedRect(NSRect(x: 418, y: 554, width: 188, height: 38), radius: 19, color: orderColor)
    roundedRect(NSRect(x: 388, y: 493, width: 248, height: 38), radius: 19, color: orderColor)
    roundedRect(NSRect(x: 430, y: 432, width: 164, height: 38), radius: 19, color: orderColor)

    NSGraphicsContext.restoreGraphicsState()

    guard let png = bitmap.representation(using: .png, properties: [.compressionFactor: 1.0]) else {
        fail("Could not encode icon as PNG")
    }
    let outputURL = URL(fileURLWithPath: outputPath)
    try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    try png.write(to: outputURL, options: .atomic)
}

func verifyIcon(at inputPath: String) {
    let inputURL = URL(fileURLWithPath: inputPath) as CFURL
    guard let source = CGImageSourceCreateWithURL(inputURL, nil),
          let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        fail("Could not decode AppIcon PNG at \(inputPath)")
    }
    guard cgImage.width == 1024 && cgImage.height == 1024 else {
        fail("AppIcon must be exactly 1024x1024, got \(cgImage.width)x\(cgImage.height)")
    }

    let bitmap = NSBitmapImageRep(cgImage: cgImage)
    var samples: [Double] = []
    let step = 32
    for y in stride(from: 16, to: bitmap.pixelsHigh, by: step) {
        for x in stride(from: 16, to: bitmap.pixelsWide, by: step) {
            guard let raw = bitmap.colorAt(x: x, y: y),
                  let color = raw.usingColorSpace(.deviceRGB) else { continue }
            let luminance = 0.2126 * Double(color.redComponent)
                + 0.7152 * Double(color.greenComponent)
                + 0.0722 * Double(color.blueComponent)
            samples.append(luminance)
        }
    }
    guard !samples.isEmpty else { fail("No pixels could be sampled") }

    let mean = samples.reduce(0, +) / Double(samples.count)
    let variance = samples.reduce(0) { $0 + pow($1 - mean, 2) } / Double(samples.count)
    let stddev = sqrt(variance)
    let minimum = samples.min() ?? 0
    let maximum = samples.max() ?? 0
    let range = maximum - minimum

    print(String(format: "ICON_VISUAL mean=%.4f std=%.4f min=%.4f max=%.4f range=%.4f samples=%d",
                 mean, stddev, minimum, maximum, range, samples.count))

    guard mean >= 0.30 else {
        fail(String(format: "AppIcon is visually too dark / near-black (mean luminance %.4f)", mean))
    }
    guard stddev >= 0.075 && range >= 0.30 else {
        fail(String(format: "AppIcon is visually too flat (std %.4f, range %.4f)", stddev, range))
    }
}

do {
    switch mode {
    case "generate":
        try generateIcon(at: path)
        verifyIcon(at: path)
        print("Generated Family AppIcon at \(path)")
    case "verify":
        verifyIcon(at: path)
    default:
        fail("Usage: family_app_icon.swift [generate|verify] [path]")
    }
} catch {
    fail(error.localizedDescription)
}
