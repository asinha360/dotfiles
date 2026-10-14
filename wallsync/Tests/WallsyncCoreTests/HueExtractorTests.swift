import CoreGraphics
import Testing
@testable import WallsyncCore

func makeImage(width: Int = 128, height: Int = 80, _ color: (Int, Int) -> RGB8) -> CGImage {
    var px = [UInt8](repeating: 255, count: width * height * 4)
    for y in 0..<height {
        for x in 0..<width {
            let c = color(x, y), i = (y * width + x) * 4
            px[i] = c.r; px[i + 1] = c.g; px[i + 2] = c.b
        }
    }
    let ctx = px.withUnsafeMutableBytes { buf in
        CGContext(data: buf.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                  space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
            .makeImage()!
    }
    return ctx
}

func hueDistance(_ a: Int, _ b: Int) -> Int {
    let d = abs(a - b) % 360
    return min(d, 360 - d)
}

struct HueExtractorTests {
    @Test(arguments: [0, 15, 42, 90, 140, 205, 270, 300, 355])
    func solidColours(hue: Int) {
        let c = ColorMath.hsl(Double(hue), 60, 50)
        let r = HueExtractor.extract(makeImage { _, _ in c })
        #expect(hueDistance(r.H, hue) <= 5, "got \(r.H)")
        #expect(r.C > 0.5)
    }

    @Test func gradient() {
        let r = HueExtractor.extract(makeImage { x, _ in ColorMath.hsl(190 + Double(x) / 127 * 30, 50, 45) })
        #expect(hueDistance(r.H, 205) <= 5, "got \(r.H)")
    }

    @Test func dominantOfTwo() {
        let r = HueExtractor.extract(makeImage { x, _ in
            x < 90 ? ColorMath.hsl(20, 55, 45) : ColorMath.hsl(250, 55, 45)
        })
        #expect(hueDistance(r.H, 20) <= 5, "got \(r.H)")
    }

    @Test func wrapsAroundZero() {
        let r = HueExtractor.extract(makeImage { x, _ in ColorMath.hsl(x < 64 ? 352 : 6, 60, 50) })
        #expect(hueDistance(r.H, 359) <= 5, "got \(r.H)")
    }

    @Test func greyHasNoChroma() {
        #expect(HueExtractor.extract(makeImage { x, _ in RGB8(UInt8(x), UInt8(x), UInt8(x)) }).C == 0)
        #expect(HueExtractor.extract(makeImage { _, _ in ColorMath.hsl(205, 4, 85) }).C == 0)
    }

    @Test func deterministic() {
        let img = makeImage { x, y in ColorMath.hsl(Double(x * 3 + y), 40, 40) }
        #expect(HueExtractor.extract(img) == HueExtractor.extract(img))
    }
}
