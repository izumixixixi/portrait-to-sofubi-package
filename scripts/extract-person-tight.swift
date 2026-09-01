#!/usr/bin/env swift

import CoreGraphics
import CoreImage
import Foundation
import ImageIO
import Vision

enum CutoutError: Error, CustomStringConvertible {
    case usage
    case unreadableInput(String)
    case cannotRender
    case noPerson
    case cannotWrite(String)

    var description: String {
        switch self {
        case .usage:
            return "Usage: extract-person-tight.swift <input-image> <output.png> [--padding 0.02]"
        case .unreadableInput(let path):
            return "Could not read input image: \(path)"
        case .cannotRender:
            return "Could not render the input image."
        case .noPerson:
            return "No person mask was found."
        case .cannotWrite(let path):
            return "Could not write transparent PNG: \(path)"
        }
    }
}

struct Arguments {
    let inputURL: URL
    let outputURL: URL
    let paddingFraction: CGFloat

    init(_ values: [String]) throws {
        guard values.count == 3 || values.count == 5 else { throw CutoutError.usage }
        inputURL = URL(fileURLWithPath: values[1])
        outputURL = URL(fileURLWithPath: values[2])

        if values.count == 5 {
            guard values[3] == "--padding",
                  let parsed = Double(values[4]),
                  parsed >= 0,
                  parsed <= 0.05 else {
                throw CutoutError.usage
            }
            paddingFraction = CGFloat(parsed)
        } else {
            paddingFraction = 0.02
        }
    }
}

struct CleanMask {
    let data: Data
    let bounds: CGRect
    let width: Int
    let height: Int
}

func cleanLargestPersonMask(
    _ pixelBuffer: CVPixelBuffer,
    componentThreshold: UInt8 = 64,
    edgeRadius: Int = 2
) throws -> CleanMask {
    CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

    guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
        throw CutoutError.noPerson
    }

    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
    var values = [UInt8](repeating: 0, count: width * height)
    let pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)

    if pixelFormat == kCVPixelFormatType_OneComponent8 {
        let source = baseAddress.assumingMemoryBound(to: UInt8.self)
        for y in 0..<height {
            let row = source.advanced(by: y * bytesPerRow)
            for x in 0..<width {
                values[y * width + x] = row[x]
            }
        }
    } else if pixelFormat == kCVPixelFormatType_OneComponent32Float {
        for y in 0..<height {
            let rowAddress = baseAddress.advanced(by: y * bytesPerRow)
            let row = rowAddress.assumingMemoryBound(to: Float.self)
            for x in 0..<width {
                let normalized = max(0, min(1, row[x]))
                values[y * width + x] = UInt8((normalized * 255).rounded())
            }
        }
    } else {
        throw CutoutError.noPerson
    }

    var labels = [Int32](repeating: -1, count: width * height)
    var queue = [Int]()
    queue.reserveCapacity(width * height / 2)
    var nextLabel: Int32 = 0
    var largestLabel: Int32 = -1
    var largestCount = 0

    let neighbors = [(-1, 0), (1, 0), (0, -1), (0, 1)]
    for startY in 0..<height {
        for startX in 0..<width {
            let start = startY * width + startX
            guard values[start] >= componentThreshold, labels[start] == -1 else { continue }

            queue.removeAll(keepingCapacity: true)
            queue.append(start)
            labels[start] = nextLabel
            var cursor = 0

            while cursor < queue.count {
                let index = queue[cursor]
                cursor += 1
                let x = index % width
                let y = index / width

                for (dx, dy) in neighbors {
                    let nx = x + dx
                    let ny = y + dy
                    guard nx >= 0, nx < width, ny >= 0, ny < height else { continue }
                    let neighbor = ny * width + nx
                    guard values[neighbor] >= componentThreshold, labels[neighbor] == -1 else { continue }
                    labels[neighbor] = nextLabel
                    queue.append(neighbor)
                }
            }

            if queue.count > largestCount {
                largestCount = queue.count
                largestLabel = nextLabel
            }
            nextLabel += 1
        }
    }

    guard largestLabel >= 0 else { throw CutoutError.noPerson }

    var keep = [UInt8](repeating: 0, count: width * height)
    for y in 0..<height {
        for x in 0..<width where labels[y * width + x] == largestLabel {
            for dy in -edgeRadius...edgeRadius {
                for dx in -edgeRadius...edgeRadius {
                    let nx = x + dx
                    let ny = y + dy
                    guard nx >= 0, nx < width, ny >= 0, ny < height else { continue }
                    keep[ny * width + nx] = 1
                }
            }
        }
    }

    var cleaned = [UInt8](repeating: 0, count: width * height)
    var minX = width
    var minY = height
    var maxX = -1
    var maxY = -1

    for y in 0..<height {
        for x in 0..<width {
            let index = y * width + x
            guard keep[index] == 1, values[index] > 8 else { continue }
            let value = values[index] >= 248 ? UInt8.max : values[index]
            cleaned[index] = value
            minX = min(minX, x)
            minY = min(minY, y)
            maxX = max(maxX, x)
            maxY = max(maxY, y)
        }
    }

    guard maxX >= minX, maxY >= minY else { throw CutoutError.noPerson }
    return CleanMask(
        data: Data(cleaned),
        bounds: CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1),
        width: width,
        height: height
    )
}

func foregroundMask(for sourceCG: CGImage) throws -> CVPixelBuffer {
    let handler = VNImageRequestHandler(cgImage: sourceCG, options: [:])

    if #available(macOS 14.0, *) {
        let foregroundRequest = VNGenerateForegroundInstanceMaskRequest()
        try handler.perform([foregroundRequest])
        if let observation = foregroundRequest.results?.first,
           !observation.allInstances.isEmpty {
            return try observation.generateMask(forInstances: observation.allInstances)
        }
    }

    let personRequest = VNGeneratePersonSegmentationRequest()
    personRequest.qualityLevel = .accurate
    personRequest.outputPixelFormat = kCVPixelFormatType_OneComponent8
    try handler.perform([personRequest])
    guard let observation = personRequest.results?.first else { throw CutoutError.noPerson }
    return observation.pixelBuffer
}

func run() throws {
    let arguments = try Arguments(CommandLine.arguments)
    guard var source = CIImage(contentsOf: arguments.inputURL, options: [.applyOrientationProperty: true]) else {
        throw CutoutError.unreadableInput(arguments.inputURL.path)
    }

    source = source.transformed(by: CGAffineTransform(
        translationX: -source.extent.origin.x,
        y: -source.extent.origin.y
    ))

    let context = CIContext(options: [.cacheIntermediates: false])
    guard let sourceCG = context.createCGImage(source, from: source.extent) else {
        throw CutoutError.cannotRender
    }

    let maskBuffer = try foregroundMask(for: sourceCG)
    let cleanMask = try cleanLargestPersonMask(maskBuffer)
    let maskPixelBounds = cleanMask.bounds
    let maskWidth = CGFloat(cleanMask.width)
    let maskHeight = CGFloat(cleanMask.height)
    let scaleX = source.extent.width / maskWidth
    let scaleY = source.extent.height / maskHeight

    let mask = CIImage(
        bitmapData: cleanMask.data,
        bytesPerRow: cleanMask.width,
        size: CGSize(width: cleanMask.width, height: cleanMask.height),
        format: .L8,
        colorSpace: nil
    )
        .transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        .cropped(to: source.extent)

    let transparent = CIImage(color: .clear).cropped(to: source.extent)
    guard let composited = CIFilter(
        name: "CIBlendWithMask",
        parameters: [
            kCIInputImageKey: source,
            kCIInputBackgroundImageKey: transparent,
            kCIInputMaskImageKey: mask,
        ]
    )?.outputImage else {
        throw CutoutError.cannotRender
    }

    let personX = maskPixelBounds.minX * scaleX
    let personWidth = maskPixelBounds.width * scaleX
    let personHeight = maskPixelBounds.height * scaleY
    let personY = (maskHeight - maskPixelBounds.maxY) * scaleY
    let margin = ceil(max(personWidth, personHeight) * arguments.paddingFraction)

    let crop = CGRect(
        x: max(source.extent.minX, floor(personX - margin)),
        y: max(source.extent.minY, floor(personY - margin)),
        width: 0,
        height: 0
    )
    let cropMaxX = min(source.extent.maxX, ceil(personX + personWidth + margin))
    let cropMaxY = min(source.extent.maxY, ceil(personY + personHeight + margin))
    let cropRect = CGRect(
        x: crop.minX,
        y: crop.minY,
        width: cropMaxX - crop.minX,
        height: cropMaxY - crop.minY
    ).integral

    let output = composited
        .cropped(to: cropRect)
        .transformed(by: CGAffineTransform(translationX: -cropRect.minX, y: -cropRect.minY))

    try FileManager.default.createDirectory(
        at: arguments.outputURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )

    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
        throw CutoutError.cannotRender
    }

    do {
        try context.writePNGRepresentation(
            of: output,
            to: arguments.outputURL,
            format: .RGBA8,
            colorSpace: colorSpace,
            options: [:]
        )
    } catch {
        throw CutoutError.cannotWrite(arguments.outputURL.path)
    }

    print("Wrote tight transparent cutout: \(arguments.outputURL.path)")
}

do {
    try run()
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
