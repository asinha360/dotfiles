import CoreGraphics
import Foundation

public enum Geometry {
    /// Slanted wipe mask at progress `p` for a rect of `size` in y-up coordinates (board A:
    /// polygon(-30% 0, -5% 0, -25% 100%, -30% 100%) to polygon(-30% 0, 130% 0, 110% 100%, -30% 100%)).
    /// Always 4 vertices in the same order, so paths interpolate: bottom-left, top-left, top edge, bottom edge.
    public static func wipe(_ p: Double, size: CGSize) -> [CGPoint] {
        let w = size.width, h = size.height
        let travel = 1.35 * p
        return [
            CGPoint(x: -0.3 * w, y: 0),
            CGPoint(x: -0.3 * w, y: h),
            CGPoint(x: (-0.05 + travel) * w, y: h),
            CGPoint(x: (-0.25 + travel) * w, y: 0),
        ]
    }

    /// Distance from `origin` to the farthest corner of a rect of `size` at the origin.
    public static func growRadius(origin: CGPoint, size: CGSize) -> Double {
        let corners = [CGPoint.zero, CGPoint(x: size.width, y: 0), CGPoint(x: 0, y: size.height),
                       CGPoint(x: size.width, y: size.height)]
        return corners.map { hypot($0.x - origin.x, $0.y - origin.y) }.max()!
    }

    /// Nearest point of `rect` to `point`, so screens without the origin start the grow at their edge.
    public static func clamp(_ point: CGPoint, to rect: CGRect) -> CGPoint {
        CGPoint(x: min(max(point.x, rect.minX), rect.maxX), y: min(max(point.y, rect.minY), rect.maxY))
    }

    /// Grow origin in the local coordinates of `screen`, given a global point.
    public static func localOrigin(_ global: CGPoint, screen: CGRect) -> CGPoint {
        let p = clamp(global, to: screen)
        return CGPoint(x: p.x - screen.minX, y: p.y - screen.minY)
    }

    /// Max pixel size to decode `image` at so it still aspect-fills `target` (never upscales).
    public static func fillMaxPixel(image: CGSize, target: CGSize) -> Int {
        guard image.width > 0, image.height > 0 else { return 0 }
        let scale = min(1, max(target.width / image.width, target.height / image.height))
        return Int((max(image.width, image.height) * scale).rounded(.up))
    }
}
