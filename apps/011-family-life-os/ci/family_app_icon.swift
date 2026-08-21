#!/usr/bin/env swift
import CoreGraphics
import Foundation
import ImageIO

let defaultPath = "apps/011-family-life-os/prototype/FamilyLifePrototype/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
let arguments = Array(CommandLine.arguments.dropFirst())
let path: String
if arguments.first == "verify" {
    path = arguments.count > 1 ? arguments[1] : defaultPath
} else {
    path = arguments.first ?? defaultPath
}

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("ERROR: \(message)\n".utf8))
    exit(1)
}

let inputURL = URL(fileURLWithPath: path) as CFURL
guard let source = CGImageSourceCreateWithURL(inputURL, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
    fail("Could not decode AppIcon PNG at \(path)")
}

guard image.width == 1024 && image.height == 1024 else {
    fail("AppIcon must be exactly 1024x1024, got \(image.width)x\(image.height)")
}

let width = image.width
let height = image.height
let bytesPerPixel = 4
let bytesPerRow = width * bytesPerPixel
var pixels = [UInt8](repeating: 0, count: bytesPerRow * height)

let rendered = pixels.withUnsafeMutableBytes { rawBuffer -> Bool in
    guard let baseAddress = rawBuffer.baseAddress,
          let context = CGContext(
            data: baseAddress,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
          ) else {
        return false
    }
    context.setBlendMode(.copy)
    context.interpolationQuality = .none
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    return true
}

guard rendered else {
    fail("Could not render AppIcon into RGB verification buffer")
}

var samples: [Double] = []
let step = 32
for y in stride(from: 16, to: height, by: step) {
    for x in stride(from: 16, to: width, by: step) {
        let index = y * bytesPerRow + x * bytesPerPixel
        let red = Double(pixels[index]) / 255.0
        let green = Double(pixels[index + 1]) / 255.0
        let blue = Double(pixels[index + 2]) / 255.0
        let luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue
        samples.append(luminance)
    }
}

guard !samples.isEmpty else {
    fail("No AppIcon pixels could be sampled")
}

let mean = samples.reduce(0, +) / Double(samples.count)
let variance = samples.reduce(0) { $0 + pow($1 - mean, 2) } / Double(samples.count)
let standardDeviation = sqrt(variance)
let minimum = samples.min() ?? 0
let maximum = samples.max() ?? 0
let range = maximum - minimum

print(String(
    format: "ICON_VISUAL mean=%.4f std=%.4f min=%.4f max=%.4f range=%.4f samples=%d",
    mean,
    standardDeviation,
    minimum,
    maximum,
    range,
    samples.count
))

guard mean >= 0.30 else {
    fail(String(format: "AppIcon is visually too dark / near-black (mean luminance %.4f)", mean))
}

guard standardDeviation >= 0.075 && range >= 0.30 else {
    fail(String(format: "AppIcon is visually too flat (std %.4f, range %.4f)", standardDeviation, range))
}

print("Family AppIcon visual verification passed.")
