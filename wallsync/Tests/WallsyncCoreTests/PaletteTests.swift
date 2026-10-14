import Foundation
import Testing
@testable import WallsyncCore

struct PaletteTests {
    static let sample = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("sample-palette.json")

    @Test func goldenSampleIsReproducedExactly() throws {
        let golden = try Palette.variables(json: Data(contentsOf: Self.sample))
        let ours = Palette(H: 205, C: 0.2).dictionary()
        #expect(golden.count == 132)
        #expect(Set(ours.keys) == Set(golden.keys))
        for (key, value) in golden {
            #expect(ours[key] == value, "\(key)")
        }
    }

    @Test func jsonRoundTripsThroughRender() throws {
        let p = Palette(H: 205, C: 0.2)
        let parsed = try Palette.variables(json: Data(p.json(wallpaper: "/tmp/a \"b\".png").utf8))
        #expect(parsed == p.dictionary(wallpaper: "/tmp/a \"b\".png"))
        #expect(parsed.count == 133)
    }

    @Test func contrastHoldsForEveryHueAndChroma() {
        for h in stride(from: 0, through: 355, by: 5) {
            for c in [0.0, 0.5, 1.0] {
                let p = Palette(H: h, C: c)
                #expect(ColorMath.contrast(p.color("fg"), p.panel) >= 7, "fg H=\(h) C=\(c)")
                for i in 1...15 {
                    #expect(ColorMath.contrast(p.ansi[i], p.panel) >= 3, "ansi\(i) H=\(h) C=\(c)")
                }
            }
        }
    }

    @Test func deterministicAndNormalised() {
        #expect(Palette(H: 205, C: 0.2).json() == Palette(H: 205, C: 0.2).json())
        #expect(Palette(H: 565, C: 0.204) == Palette(H: 205, C: 0.2))
        #expect(Palette(H: -155, C: 0.2).H == 205)
    }

    @Test func ansiHuePullIsClamped() {
        // red slot 355 toward H=205: delta -150, pull clamped to -12, so hue 343.
        #expect(Palette(H: 205, C: 0.2).ansi[1] == ColorMath.hsl(343, 24.4, 69))
        // blue slot 212 toward H=205: delta -7, pull -1.05.
        #expect(Palette(H: 205, C: 0.2).ansi[4] == ColorMath.hsl(210.95, 24.4, 72))
    }
}
