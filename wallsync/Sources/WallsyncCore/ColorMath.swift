import Foundation

public struct RGB8: Hashable, Sendable {
    public var r: UInt8, g: UInt8, b: UInt8

    public init(_ r: UInt8, _ g: UInt8, _ b: UInt8) {
        self.r = r; self.g = g; self.b = b
    }

    public init?(hex: String) {
        let s = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        self.init(UInt8(v >> 16 & 0xFF), UInt8(v >> 8 & 0xFF), UInt8(v & 0xFF))
    }

    /// `RRGGBB`, uppercase.
    public var hex: String { String(format: "%02X%02X%02X", r, g, b) }
}

public struct OKLab: Equatable, Sendable {
    public var L: Double, a: Double, b: Double
    public init(_ L: Double, _ a: Double, _ b: Double) {
        self.L = L; self.a = a; self.b = b
    }
}

public enum ColorMath {
    /// Unit float to byte exactly as the contract says: `Int(x*255 + 0.5)`.
    public static func byte(_ x: Double) -> UInt8 {
        UInt8(Int(min(max(x, 0), 1) * 255 + 0.5))
    }

    /// CSS Color 4 hsl-to-rgb. `h` in degrees, `s` and `l` in percent.
    public static func hsl(_ h: Double, _ s: Double, _ l: Double) -> RGB8 {
        var hue = h.truncatingRemainder(dividingBy: 360)
        if hue < 0 { hue += 360 }
        let sat = s / 100, light = l / 100
        func f(_ n: Double) -> Double {
            let k = (n + hue / 30).truncatingRemainder(dividingBy: 12)
            let a = sat * min(light, 1 - light)
            return light - a * max(-1, min(k - 3, 9 - k, 1))
        }
        return RGB8(byte(f(0)), byte(f(8)), byte(f(4)))
    }

    /// Composites `c` at `alpha` over the opaque `p`, per channel `Int(a*c + (1-a)*p + 0.5)`.
    public static func flatten(_ c: RGB8, alpha: Double, over p: RGB8) -> RGB8 {
        func mix(_ x: UInt8, _ y: UInt8) -> UInt8 {
            UInt8(Int(alpha * Double(x) + (1 - alpha) * Double(y) + 0.5))
        }
        return RGB8(mix(c.r, p.r), mix(c.g, p.g), mix(c.b, p.b))
    }

    public static func toLinear(_ c: Double) -> Double {
        c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
    }

    public static func toGamma(_ c: Double) -> Double {
        c <= 0.0031308 ? 12.92 * c : 1.055 * pow(c, 1 / 2.4) - 0.055
    }

    public static func luminance(_ c: RGB8) -> Double {
        let r = toLinear(Double(c.r) / 255), g = toLinear(Double(c.g) / 255), b = toLinear(Double(c.b) / 255)
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    /// WCAG 2 contrast ratio.
    public static func contrast(_ x: RGB8, _ y: RGB8) -> Double {
        let a = luminance(x), b = luminance(y)
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }

    public static func oklab(_ c: RGB8) -> OKLab {
        let r = toLinear(Double(c.r) / 255), g = toLinear(Double(c.g) / 255), b = toLinear(Double(c.b) / 255)
        let l = cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b)
        let m = cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b)
        let s = cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b)
        return OKLab(
            0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
            1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
            0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s)
    }

    public static func rgb(_ c: OKLab) -> RGB8 {
        let l = pow(c.L + 0.3963377774 * c.a + 0.2158037573 * c.b, 3)
        let m = pow(c.L - 0.1055613458 * c.a - 0.0638541728 * c.b, 3)
        let s = pow(c.L - 0.0894841775 * c.a - 1.2914855480 * c.b, 3)
        let r = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
        let g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
        let b = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
        return RGB8(byte(toGamma(max(r, 0))), byte(toGamma(max(g, 0))), byte(toGamma(max(b, 0))))
    }

    public static func lerp(_ x: OKLab, _ y: OKLab, _ t: Double) -> OKLab {
        OKLab(x.L + (y.L - x.L) * t, x.a + (y.a - x.a) * t, x.b + (y.b - x.b) * t)
    }
}
