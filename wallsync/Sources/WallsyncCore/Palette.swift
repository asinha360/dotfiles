import Foundation

/// The Monolith palette for a wallpaper hue `H` and chroma factor `C` (see CONTRACT.md, Palette).
public struct Palette: Equatable, Sendable {
    public struct Entry: Equatable, Sendable {
        public let name: String
        public let rgb: RGB8
        public let alpha: Double
    }

    public let H: Int
    public let C: Double
    /// panel, solid, pill, line, lineHi, fg, sub, dim, hi, sel, ansi0...ansi15.
    public let entries: [Entry]

    static let base: [(String, Double, Double, Double)] = [
        ("panel", 14, 8, 0.70), ("solid", 14, 9, 1), ("pill", 14, 8, 0.62),
        ("line", 12, 72, 0.28), ("lineHi", 14, 90, 0.70),
        ("fg", 12, 86, 1), ("sub", 9, 70, 1), ("dim", 8, 54, 1), ("hi", 16, 94, 1),
        ("sel", 12, 32, 0.55),
    ]
    /// red, green, yellow, blue, magenta, cyan as (hue, lightness).
    static let slots: [(Double, Double)] = [(355, 69), (140, 66), (42, 67), (212, 72), (300, 70), (185, 66)]

    public init(H: Int, C: Double) {
        let h = ((H % 360) + 360) % 360
        let c = (min(max(C, 0), 1) * 100).rounded() / 100
        self.H = h
        self.C = c
        let hue = Double(h)
        var list = Self.base.map { Entry(name: $0.0, rgb: ColorMath.hsl(hue, $0.1, $0.2), alpha: $0.3) }
        let color = Dictionary(uniqueKeysWithValues: list.map { ($0.name, $0.rgb) })
        let sat = 22 + 12 * c
        func pulled(_ slot: Double) -> Double {
            var d = (hue - slot).truncatingRemainder(dividingBy: 360)
            if d < 0 { d += 360 }
            if d > 180 { d -= 360 }
            return slot + min(max(0.15 * d, -12), 12)
        }
        var ansi = [ColorMath.hsl(hue, 14, 12)]
        ansi += Self.slots.map { ColorMath.hsl(pulled($0.0), sat, $0.1) }
        ansi += [color["fg"]!, color["dim"]!]
        ansi += Self.slots.map { ColorMath.hsl(pulled($0.0), sat, $0.1 + 8) }
        ansi.append(color["hi"]!)
        list += ansi.enumerated().map { Entry(name: "ansi\($0.offset)", rgb: $0.element, alpha: 1) }
        entries = list
    }

    public func entry(_ name: String) -> Entry { entries.first { $0.name == name }! }
    public func color(_ name: String) -> RGB8 { entry(name).rgb }
    public var panel: RGB8 { entries[0].rgb }
    public var ansi: [RGB8] { entries.suffix(16).map(\.rgb) }

    /// Every template variable, in a stable order: H, C, wallpaper, then five forms per key.
    public func variables(wallpaper: String? = nil) -> [(String, String)] {
        var out: [(String, String)] = [("H", String(H)), ("C", String(C))]
        if let wallpaper { out.append(("wallpaper", wallpaper)) }
        let panel = self.panel
        for e in entries {
            let flat = ColorMath.flatten(e.rgb, alpha: e.alpha, over: panel)
            out += [
                (e.name, e.rgb.hex),
                (e.name + "_hex", "#" + e.rgb.hex),
                (e.name + "_argb", String(format: "0x%02X", ColorMath.byte(e.alpha)) + e.rgb.hex),
                (e.name + "_flat", "#" + flat.hex),
                (e.name + "_flat_argb", "0xFF" + flat.hex),
            ]
        }
        return out
    }

    public func dictionary(wallpaper: String? = nil) -> [String: String] {
        Dictionary(uniqueKeysWithValues: variables(wallpaper: wallpaper))
    }

    /// JSON object of every template variable; H and C are numbers, the rest strings.
    public func json(wallpaper: String? = nil) -> String {
        let body = variables(wallpaper: wallpaper).map { key, value in
            let v = key == "H" || key == "C" ? value : Self.quote(value)
            return "  \"\(key)\": \(v)"
        }
        return "{\n" + body.joined(separator: ",\n") + "\n}\n"
    }

    static func quote(_ s: String) -> String {
        var out = "\""
        for u in s.unicodeScalars {
            switch u {
            case "\"": out += "\\\""
            case "\\": out += "\\\\"
            case _ where u.value < 0x20: out += String(format: "\\u%04x", u.value)
            default: out.unicodeScalars.append(u)
            }
        }
        return out + "\""
    }

    /// Reads a palette JSON (as written by `json` or sample-palette.json) into template variables.
    public static func variables(json data: Data) throws -> [String: String] {
        guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw CocoaError(.propertyListReadCorrupt)
        }
        var out: [String: String] = [:]
        for (k, v) in obj {
            if let s = v as? String { out[k] = s } else if let n = v as? NSNumber { out[k] = n.stringValue }
        }
        return out
    }
}
