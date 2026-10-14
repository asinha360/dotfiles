import CoreGraphics
import Foundation

public struct HueResult: Equatable, Sendable {
    public let H: Int
    public let C: Double
}

/// Dominant hue and chroma factor of an image.
public enum HueExtractor {
    static let width = 64, height = 40
    /// Mean weight below which an image counts as grey.
    static let greyLimit = 0.015
    /// Mean weight that maps to C = 1.
    static let fullChroma = 0.25

    public static func extract(_ image: CGImage) -> HueResult {
        var px = [UInt8](repeating: 0, count: width * height * 4)
        let space = CGColorSpace(name: CGColorSpace.sRGB)!
        px.withUnsafeMutableBytes { buf in
            let ctx = CGContext(data: buf.baseAddress, width: width, height: height, bitsPerComponent: 8,
                                bytesPerRow: width * 4, space: space,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            ctx.interpolationQuality = .medium
            ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        return extract(rgba: px)
    }

    public static func extract(url: URL) -> HueResult? {
        ImageDecode.decode(url, maxPixel: 256).map(extract)
    }

    /// Weight w = c * (1 - |2L - 1|) per pixel (HSL chroma and lightness), 36-bin circular
    /// histogram smoothed [1,2,1], hue = weighted circular mean of the peak bin and its neighbours.
    public static func extract(rgba px: [UInt8]) -> HueResult {
        let n = px.count / 4
        var weight = [Double](repeating: 0, count: 36)
        var sx = weight, sy = weight
        var total = 0.0
        for i in 0..<n {
            let r = Double(px[4 * i]) / 255, g = Double(px[4 * i + 1]) / 255, b = Double(px[4 * i + 2]) / 255
            let mx = max(r, g, b), mn = min(r, g, b), c = mx - mn
            if c < 0.02 { continue }
            let l = (mx + mn) / 2
            let w = c * (1 - abs(2 * l - 1))
            var h: Double
            if mx == r { h = (g - b) / c } else if mx == g { h = (b - r) / c + 2 } else { h = (r - g) / c + 4 }
            h *= 60
            if h < 0 { h += 360 }
            let bin = min(Int(h / 10), 35)
            let rad = h * .pi / 180
            weight[bin] += w
            sx[bin] += w * cos(rad)
            sy[bin] += w * sin(rad)
            total += w
        }
        guard total > 0 else { return HueResult(H: 0, C: 0) }
        let smooth = (0..<36).map { (i: Int) -> Double in
            let left: Double = weight[(i + 35) % 36], right: Double = weight[(i + 1) % 36]
            return left + 2 * weight[i] + right
        }
        var peak = 0
        for i in 1..<36 where smooth[i] > smooth[peak] { peak = i }
        let bins = [(peak + 35) % 36, peak, (peak + 1) % 36]
        let x = bins.reduce(0) { $0 + sx[$1] }, y = bins.reduce(0) { $0 + sy[$1] }
        var hue = Int((atan2(y, x) * 180 / .pi).rounded()) % 360
        if hue < 0 { hue += 360 }
        let mean = total / Double(n)
        let chroma = mean < greyLimit ? 0 : (min(1, mean / fullChroma) * 100).rounded() / 100
        return HueResult(H: hue, C: chroma)
    }
}
