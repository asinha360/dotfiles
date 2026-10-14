import Foundation

/// Terminal colour frames for Ghostty. Only OSC 4/10/11/12 are ever emitted: on Ghostty 1.3.1 the
/// reset sequences 104/110/111/112 break later config reloads.
public enum OSC {
    static let st = "\u{1B}\\"

    /// Frame colours in order: ansi0...ansi15, fg (OSC 10), panel (OSC 11), hi (OSC 12).
    public static func colors(_ p: Palette) -> [RGB8] {
        p.ansi + [p.color("fg"), p.panel, p.color("hi")]
    }

    static func spec(_ c: RGB8) -> String {
        String(format: "rgb:%02x/%02x/%02x", c.r, c.g, c.b)
    }

    /// One buffer: a single OSC 4 setting all 16 slots, then OSC 10, 11 and 12, each ended with ST.
    public static func frame(_ colors: [RGB8]) -> [UInt8] {
        precondition(colors.count == 19)
        let slots = (0..<16).map { "\($0);\(spec(colors[$0]))" }.joined(separator: ";")
        let s = "\u{1B}]4;\(slots)\(st)"
            + "\u{1B}]10;\(spec(colors[16]))\(st)"
            + "\u{1B}]11;\(spec(colors[17]))\(st)"
            + "\u{1B}]12;\(spec(colors[18]))\(st)"
        return Array(s.utf8)
    }

    public static func frame(_ p: Palette) -> [UInt8] { frame(colors(p)) }

    /// Frame at progress `t` between two palettes, interpolated in OKLab.
    public static func frame(from a: [OKLab], to b: [OKLab], t: Double) -> [UInt8] {
        frame(zip(a, b).map { ColorMath.rgb(ColorMath.lerp($0, $1, t)) })
    }
}
