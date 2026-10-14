import Foundation

/// CSS `cubic-bezier(x1, y1, x2, y2)`: maps time fraction to progress.
public struct CubicBezier: Equatable, Sendable {
    public let x1: Double, y1: Double, x2: Double, y2: Double

    public init(_ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double) {
        self.x1 = x1; self.y1 = y1; self.x2 = x2; self.y2 = y2
    }

    private func sample(_ t: Double, _ p1: Double, _ p2: Double) -> Double {
        let c = 3 * p1, b = 3 * (p2 - p1) - c, a = 1 - c - b
        return ((a * t + b) * t + c) * t
    }

    private func slope(_ t: Double) -> Double {
        let c = 3 * x1, b = 3 * (x2 - x1) - c, a = 1 - c - b
        return (3 * a * t + 2 * b) * t + c
    }

    /// Solves x(t) = x by Newton's method, falling back to bisection.
    private func solve(_ x: Double) -> Double {
        var t = x
        for _ in 0..<8 {
            let err = sample(t, x1, x2) - x
            if abs(err) < 1e-7 { return t }
            let d = slope(t)
            if abs(d) < 1e-6 { break }
            t -= err / d
        }
        var lo = 0.0, hi = 1.0
        t = x
        for _ in 0..<60 {
            let v = sample(t, x1, x2)
            if abs(v - x) < 1e-7 { break }
            if v < x { lo = t } else { hi = t }
            t = (lo + hi) / 2
        }
        return t
    }

    public func callAsFunction(_ x: Double) -> Double {
        if x <= 0 { return 0 }
        if x >= 1 { return 1 }
        return sample(solve(x), y1, y2)
    }
}

public enum TransitionKind: String, Codable, CaseIterable, Sendable {
    case wipe, grow

    public var duration: Double { self == .wipe ? 0.9 : 1.1 }

    public var curve: CubicBezier {
        self == .wipe ? CubicBezier(0.7, 0, 0.2, 1) : CubicBezier(0.65, 0, 0.35, 1)
    }
}
