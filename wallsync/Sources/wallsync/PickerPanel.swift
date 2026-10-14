import AppKit
import SwiftUI
import WallsyncCore

/// Full-screen nonactivating panel hosting the carousel. It takes key focus without activating the
/// daemon, and gives focus back to the previously frontmost app when it closes.
final class PickerPanel: NSPanel {
    let model = PickerModel()
    private var previous: NSRunningApplication?

    init() {
        super.init(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
        level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue - 1)
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        isFloatingPanel = true
        hidesOnDeactivate = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isReleasedWhenClosed = false
        animationBehavior = .none
        model.onClose = { [weak self] in self?.dismiss() }
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    /// Opens on the screen under the mouse with `paths`, selecting `current`.
    func present(paths: [String], current: String?, palette: Palette, thumbs: URL) {
        let mouse = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(mouse) }) ?? NSScreen.main else { return }
        previous = NSWorkspace.shared.frontmostApplication
        model.paths = paths
        model.selected = current.flatMap { paths.firstIndex(of: $0) } ?? 0
        model.palette = palette
        model.thumbDir = thumbs
        model.loadThumbs()
        setFrame(screen.frame, display: false)
        let host = NSHostingView(rootView: PickerView(model: model, topInset: screen.safeAreaInsets.top))
        host.safeAreaRegions = []
        contentView = host
        makeKeyAndOrderFront(nil)
    }

    func dismiss() {
        guard isVisible else { return }
        orderOut(nil)
        contentView = nil
        if let previous, previous.processIdentifier != getpid() { previous.activate() }
        previous = nil
    }

    /// SwiftUI coordinates of the hosting view (top-left origin) to global Cocoa coordinates.
    func global(_ p: CGPoint) -> CGPoint { CGPoint(x: frame.minX + p.x, y: frame.maxY - p.y) }

    override func sendEvent(_ event: NSEvent) {
        guard event.type == .keyDown else { return super.sendEvent(event) }
        switch (event.keyCode, event.charactersIgnoringModifiers) {
        case (123, _), (_, "h"): model.move(-1)
        case (124, _), (_, "l"): model.move(1)
        case (36, _), (76, _): model.choose(model.selected)
        case (53, _): dismiss()
        default: super.sendEvent(event)
        }
    }
}
