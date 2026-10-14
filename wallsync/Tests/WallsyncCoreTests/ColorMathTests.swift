import Testing
@testable import WallsyncCore

struct ColorMathTests {
    @Test func hslMatchesCSS() {
        #expect(ColorMath.hsl(0, 100, 50) == RGB8(255, 0, 0))
        #expect(ColorMath.hsl(120, 100, 50) == RGB8(0, 255, 0))
        #expect(ColorMath.hsl(240, 100, 25) == RGB8(0, 0, 128))
        #expect(ColorMath.hsl(205, 14, 8).hex == "121517")
        #expect(ColorMath.hsl(-155, 14, 8) == ColorMath.hsl(205, 14, 8))
    }

    @Test func hexRoundTrip() {
        #expect(RGB8(hex: "#AFB9C0") == RGB8(0xAF, 0xB9, 0xC0))
        #expect(RGB8(hex: "afb9c0")?.hex == "AFB9C0")
        #expect(RGB8(hex: "xyz") == nil)
    }

    @Test func flattenAndContrast() {
        let panel = RGB8(hex: "121517")!
        #expect(ColorMath.flatten(RGB8(hex: "AFB9C0")!, alpha: 0.28, over: panel).hex == "3E4346")
        #expect(abs(ColorMath.contrast(RGB8(255, 255, 255), RGB8(0, 0, 0)) - 21) < 1e-9)
        #expect(ColorMath.byte(0.7) == 0xB3)
    }

    @Test func oklabRoundTrip() {
        for c in [RGB8(0, 0, 0), RGB8(255, 255, 255), RGB8(18, 21, 23), RGB8(195, 157, 168), RGB8(12, 200, 90)] {
            #expect(ColorMath.rgb(ColorMath.oklab(c)) == c)
        }
        let a = ColorMath.oklab(RGB8(0, 0, 0)), b = ColorMath.oklab(RGB8(255, 255, 255))
        #expect(ColorMath.rgb(ColorMath.lerp(a, b, 0)) == RGB8(0, 0, 0))
        #expect(ColorMath.rgb(ColorMath.lerp(a, b, 1)) == RGB8(255, 255, 255))
    }
}
