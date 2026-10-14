import Foundation
import Testing
@testable import WallsyncCore

struct OSCTests {
    static let forbidden = ["\u{1B}]104", "\u{1B}]110", "\u{1B}]111", "\u{1B}]112"]

    @Test func goldenFrame() {
        let s = String(decoding: OSC.frame(Palette(H: 205, C: 0.2)), as: UTF8.self)
        let expected = "\u{1B}]4;"
            + "0;rgb:1a/1f/23;1;rgb:c3/9d/a8;2;rgb:93/bd/a8;3;rgb:bf/bb/96;4;rgb:a6/b7/c9;5;rgb:be/a0/c5;"
            + "6;rgb:93/b8/bd;7;rgb:d7/dc/e0;8;rgb:80/8b/93;9;rgb:d3/b6/be;10;rgb:ad/cd/bd;11;rgb:cf/cc/b0;"
            + "12;rgb:c0/cc/d8;13;rgb:cf/b9/d5;14;rgb:ad/c9/cd;15;rgb:ed/f0/f2\u{1B}\\"
            + "\u{1B}]10;rgb:d7/dc/e0\u{1B}\\"
            + "\u{1B}]11;rgb:12/15/17\u{1B}\\"
            + "\u{1B}]12;rgb:ed/f0/f2\u{1B}\\"
        #expect(s == expected)
        #expect(s.utf8.count < 360)
    }

    @Test func neverEmitsResetSequences() {
        let a = OSC.colors(Palette(H: 205, C: 0.2)).map(ColorMath.oklab)
        for h in stride(from: 0, to: 360, by: 15) {
            let b = OSC.colors(Palette(H: h, C: 1)).map(ColorMath.oklab)
            for t in stride(from: 0.0, through: 1.0, by: 0.1) {
                let s = String(decoding: OSC.frame(from: a, to: b, t: t), as: UTF8.self)
                for f in Self.forbidden { #expect(!s.contains(f)) }
                #expect(s.components(separatedBy: "\u{1B}]").count == 5)
                #expect(s.hasSuffix("\u{1B}\\"))
            }
        }
    }

    @Test func lerpEndpointsAreExact() {
        let p = Palette(H: 10, C: 0.6), q = Palette(H: 280, C: 0.1)
        let a = OSC.colors(p).map(ColorMath.oklab), b = OSC.colors(q).map(ColorMath.oklab)
        #expect(OSC.frame(from: a, to: b, t: 0) == OSC.frame(p))
        #expect(OSC.frame(from: a, to: b, t: 1) == OSC.frame(q))
    }
}
