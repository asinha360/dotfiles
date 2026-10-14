import AppKit
import QuartzCore
import WallsyncCore

/// A borderless window at desktop level on one screen. It shows the current wallpaper and reveals the
/// next one through an animated CAShapeLayer mask; the system wallpaper is set once the reveal ends.
final class DesktopWindow: NSWindow {
    let target: NSScreen
    private let root = CALayer()
    private var current: CALayer?

    init(screen: NSScreen) {
        target = screen
        super.init(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        ignoresMouseEvents = true
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isReleasedWhenClosed = false
        animationBehavior = .none
        let view = NSView(frame: NSRect(origin: .zero, size: screen.frame.size))
        // Layer-hosting: assign the layer before wantsLayer so AppKit never draws into it.
        view.layer = root
        view.wantsLayer = true
        root.actions = Self.noActions
        contentView = view
        setFrame(screen.frame, display: false)
    }

    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect { frameRect }
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    static let noActions: [String: any CAAction] = [
        "contents": NSNull(), "bounds": NSNull(), "position": NSNull(), "path": NSNull(),
        "sublayers": NSNull(), "mask": NSNull(), "hidden": NSNull(), "onOrderIn": NSNull(), "onOrderOut": NSNull(),
    ]

    /// Image size in pixels the wallpaper should be decoded at for this screen.
    var pixelSize: CGSize {
        let s = target.backingScaleFactor
        return CGSize(width: target.frame.width * s, height: target.frame.height * s)
    }

    private func imageLayer(_ image: CGImage) -> CALayer {
        let layer = CALayer()
        layer.actions = Self.noActions
        layer.frame = root.bounds
        layer.contentsGravity = .resizeAspectFill
        layer.contentsScale = target.backingScaleFactor
        layer.masksToBounds = true
        layer.contents = image
        return layer
    }

    /// Shows `image` immediately.
    func show(_ image: CGImage) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let layer = imageLayer(image)
        root.addSublayer(layer)
        current?.removeFromSuperlayer()
        current = layer
        CATransaction.commit()
    }

    /// Reveals `image` over the current one, starting at `t0` (CACurrentMediaTime). `origin` is the grow
    /// centre in global Cocoa coordinates; screens that do not contain it start from their nearest edge.
    func reveal(_ image: CGImage, kind: TransitionKind, origin: CGPoint, t0: CFTimeInterval,
                completion: @escaping @MainActor () -> Void) {
        let size = root.bounds.size
        let from: CGPath, to: CGPath
        switch kind {
        case .wipe:
            from = Self.polygon(Geometry.wipe(0, size: size))
            to = Self.polygon(Geometry.wipe(1, size: size))
        case .grow:
            let o = Geometry.localOrigin(origin, screen: target.frame)
            let r = Geometry.growRadius(origin: o, size: size) + 2
            from = CGPath(ellipseIn: CGRect(x: o.x - 0.01, y: o.y - 0.01, width: 0.02, height: 0.02), transform: nil)
            to = CGPath(ellipseIn: CGRect(x: o.x - r, y: o.y - r, width: 2 * r, height: 2 * r), transform: nil)
        }
        let next = imageLayer(image)
        let mask = CAShapeLayer()
        mask.actions = Self.noActions
        mask.frame = root.bounds
        mask.fillColor = CGColor(gray: 1, alpha: 1)
        mask.path = to
        next.mask = mask

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        CATransaction.setCompletionBlock {
            MainActor.assumeIsolated {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                next.mask = nil
                self.current?.removeFromSuperlayer()
                self.current = next
                CATransaction.commit()
                completion()
            }
        }
        root.addSublayer(next)
        let c = kind.curve
        let anim = CABasicAnimation(keyPath: "path")
        anim.fromValue = from
        anim.toValue = to
        anim.duration = kind.duration
        anim.timingFunction = CAMediaTimingFunction(controlPoints: Float(c.x1), Float(c.y1), Float(c.x2), Float(c.y2))
        anim.beginTime = mask.convertTime(t0, from: nil)
        anim.fillMode = .backwards
        anim.isRemovedOnCompletion = true
        mask.add(anim, forKey: "reveal")
        CATransaction.commit()
    }

    static func polygon(_ points: [CGPoint]) -> CGPath {
        let path = CGMutablePath()
        path.addLines(between: points)
        path.closeSubpath()
        return path
    }
}
