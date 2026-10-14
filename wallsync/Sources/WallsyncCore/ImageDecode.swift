import CoreGraphics
import CryptoKit
import Foundation
import ImageIO

public enum ImageDecode {
    public static let thumbSize = CGSize(width: 546, height: 600)

    public static func pixelSize(_ url: URL) -> CGSize? {
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any],
              let w = props[kCGImagePropertyPixelWidth] as? Int,
              let h = props[kCGImagePropertyPixelHeight] as? Int else { return nil }
        return CGSize(width: w, height: h)
    }

    /// Decodes with the longest side at most `maxPixel`, fully decoded up front.
    public static func decode(_ url: URL, maxPixel: Int) -> CGImage? {
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let opts: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: max(1, maxPixel),
        ]
        return CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary)
    }

    /// Decodes at the smallest size that still aspect-fills `target` pixels.
    public static func decodeFill(_ url: URL, target: CGSize) -> CGImage? {
        guard let size = pixelSize(url) else { return nil }
        return decode(url, maxPixel: Geometry.fillMaxPixel(image: size, target: target))
    }

    /// Draws `image` aspect-filled and centered into a new image of `size`.
    public static func fill(_ image: CGImage, size: CGSize) -> CGImage? {
        let w = Int(size.width), h = Int(size.height)
        guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { return nil }
        let iw = CGFloat(image.width), ih = CGFloat(image.height)
        let scale = max(size.width / iw, size.height / ih)
        let dw = iw * scale, dh = ih * scale
        ctx.interpolationQuality = .high
        ctx.draw(image, in: CGRect(x: (size.width - dw) / 2, y: (size.height - dh) / 2, width: dw, height: dh))
        return ctx.makeImage()
    }

    public static func sha256(_ s: String) -> String {
        SHA256.hash(data: Data(s.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    /// Cache key for a file: sha256 of "path|mtime", with the mtime of the symlink target if it is a link.
    public static func key(for url: URL) -> String {
        let real = url.resolvingSymlinksInPath()
        let mtime = (try? FileManager.default.attributesOfItem(atPath: real.path)[.modificationDate] as? Date)?
            .timeIntervalSince1970 ?? 0
        return sha256("\(url.path)|\(mtime)")
    }

    public static func writeJPEG(_ image: CGImage, to url: URL, quality: Double) -> Bool {
        let tmp = url.deletingLastPathComponent()
            .appendingPathComponent(".\(url.lastPathComponent).\(getpid()).\(UInt32.random(in: 0...UInt32.max))")
        guard let dest = CGImageDestinationCreateWithURL(tmp as CFURL, "public.jpeg" as CFString, 1, nil) else {
            return false
        }
        CGImageDestinationAddImage(dest, image, [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
        guard CGImageDestinationFinalize(dest), rename(tmp.path, url.path) == 0 else {
            unlink(tmp.path)
            return false
        }
        return true
    }

    /// Picker thumbnail (546x600 JPEG, quality 0.8), cached in `cacheDir` by path and mtime.
    public static func thumbnail(for url: URL, cacheDir: URL) -> URL? {
        let out = cacheDir.appendingPathComponent(key(for: url) + ".jpg")
        if FileManager.default.fileExists(atPath: out.path) { return out }
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        guard let size = pixelSize(url),
              let img = decode(url, maxPixel: Geometry.fillMaxPixel(image: size, target: thumbSize)),
              let thumb = fill(img, size: thumbSize),
              writeJPEG(thumb, to: out, quality: 0.8) else { return nil }
        return out
    }

    /// A file the system wallpaper can show: formats it may not support become a unique JPEG.
    public static func desktopURL(for url: URL, cacheDir: URL) -> URL? {
        let native: Set<String> = ["png", "jpg", "jpeg", "heic", "tif", "tiff"]
        if native.contains(url.pathExtension.lowercased()) { return url }
        let out = cacheDir.appendingPathComponent("desktop-" + key(for: url) + ".jpg")
        if FileManager.default.fileExists(atPath: out.path) { return out }
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        guard let img = decode(url, maxPixel: 16384), writeJPEG(img, to: out, quality: 0.92) else { return nil }
        return out
    }
}
