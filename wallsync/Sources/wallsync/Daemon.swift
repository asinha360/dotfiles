import AppKit
import QuartzCore
import WallsyncCore

/// Decoded inputs for one change, produced off the main thread.
nonisolated struct Decoded: @unchecked Sendable {
    var hue: HueResult?
    var images: [CGImage?]
    var desktop: URL?
}

/// The background app: socket server, ⌥W picker, desktop windows and the per-change timeline.
final class Daemon {
    let paths: Paths
    private var server: IPC.Server?
    private var windows: [DesktopWindow] = []
    private var state: State?
    /// True while a change or a window rebuild runs; requests that arrive meanwhile keep only the latest.
    private var busy = false
    private var pending: Request?
    private var rebuildPending = false
    private var rebuildWork: DispatchWorkItem?
    private let morph = TTYMorph()
    private let picker = PickerPanel()
    private var hotKey: HotKey?
    private var signals: [any DispatchSourceSignal] = []

    static func run(_ paths: Paths) -> Never {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let daemon = Daemon(paths)
        daemon.start()
        withExtendedLifetime(daemon) { app.run() }
        exit(0)
    }

    init(_ paths: Paths) { self.paths = paths }

    private func start() {
        try? FileManager.default.createDirectory(at: paths.cache, withIntermediateDirectories: true)
        do {
            server = try IPC.Server(path: paths.socket.path) { [weak self] req in
                self?.handle(req) ?? Response(ok: false, error: "daemon is shutting down")
            }
        } catch IPC.Failure.alreadyRunning {
            Log.write("another daemon is already listening on \(paths.socket.path)")
            exit(1)
        } catch {
            Log.write("socket: \(error)")
            exit(1)
        }
        for sig in [SIGTERM, SIGINT, SIGHUP] {
            signal(sig, SIG_IGN)
            let source = DispatchSource.makeSignalSource(signal: sig, queue: .main)
            source.setEventHandler { [weak self] in
                MainActor.assumeIsolated {
                    self?.server?.stop()
                    exit(0)
                }
            }
            source.resume()
            signals.append(source)
        }
        hotKey = HotKey { [weak self] in self?.togglePicker() }
        if hotKey == nil { Log.write("could not register the ⌥W hotkey") }
        picker.model.onApply = { [weak self] path, local in
            guard let self else { return }
            let o = self.picker.global(local)
            self.submit(Request(cmd: "set", path: path, origin: [o.x, o.y]))
        }
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.screensChanged() }
        }
        state = State.load(paths.state)
        if let state { renderTemplates(state.palette, wallpaper: state.wallpaper) }
        let walls = WallList.scan(paths.walls).paths, thumbs = paths.thumbs
        Task.detached(priority: .utility) {
            for p in walls { _ = ImageDecode.thumbnail(for: URL(fileURLWithPath: p), cacheDir: thumbs) }
        }
        rebuildPending = true
        run(nil)
        Log.write("daemon started (\(walls.count) wallpapers in \(paths.walls.path))")
    }

    // MARK: Requests

    private func handle(_ req: Request) -> Response {
        switch req.cmd {
        case "status":
            return Response(ok: true, wallpaper: state?.wallpaper, H: state?.H, C: state?.C, busy: busy)
        case "pick":
            togglePicker()
            return Response(ok: true)
        case "set":
            guard let path = req.path, FileManager.default.isReadableFile(atPath: path) else {
                return Response(ok: false, error: "cannot read \(req.path ?? "nil")")
            }
        case "next", "prev", "random":
            if WallList.scan(paths.walls).paths.isEmpty {
                return Response(ok: false, error: "no wallpapers in \(paths.walls.path)")
            }
        default:
            return Response(ok: false, error: "unknown command \(req.cmd)")
        }
        let queued = busy
        submit(req)
        return Response(ok: true, busy: queued)
    }

    private func submit(_ req: Request) {
        if busy { pending = req } else { run(req) }
    }

    /// Runs a pending window rebuild and then `req`, then whatever arrived meanwhile.
    private func run(_ req: Request?) {
        busy = true
        Task {
            if rebuildPending {
                rebuildPending = false
                await rebuildWindows()
            }
            if let req {
                do { try await change(req) } catch { Log.write("\(req.cmd): \(error)") }
            }
            busy = false
            if rebuildPending || pending != nil {
                let next = pending
                pending = nil
                run(next)
            }
        }
    }

    private func resolve(_ req: Request) throws -> String {
        if req.cmd == "set", let path = req.path { return path }
        let list = WallList.scan(paths.walls), current = state?.wallpaper
        let path = switch req.cmd {
        case "next": list.next(after: current)
        case "prev": list.prev(before: current)
        default: list.random(excluding: current)
        }
        guard let path else { throw UsageError("no wallpapers in \(paths.walls.path)") }
        return path
    }

    // MARK: Timeline

    private func decode(_ path: String, sizes: [CGSize], full: Bool) async -> Decoded {
        let cache = paths.cache
        return await Task.detached(priority: .userInitiated) {
            let url = URL(fileURLWithPath: path)
            return Decoded(hue: full ? HueExtractor.extract(url: url) : nil,
                           images: sizes.map { ImageDecode.decodeFill(url, target: $0) },
                           desktop: full ? ImageDecode.desktopURL(for: url, cacheDir: cache) : nil)
        }.value
    }

    private func change(_ req: Request) async throws {
        // The daemon's windows are usually occluded, so keep App Nap from delaying the timeline.
        let activity = ProcessInfo.processInfo.beginActivity(options: [.userInitiated, .latencyCritical],
                                                             reason: "wallsync change")
        defer { ProcessInfo.processInfo.endActivity(activity) }
        let path = try resolve(req)
        let decoded = await decode(path, sizes: windows.map(\.pixelSize), full: true)
        guard let hue = decoded.hue else { throw UsageError("cannot decode \(path)") }
        let palette = Palette(H: hue.H, C: hue.C)
        let kind = req.transition ?? TransitionKind.allCases.randomElement()!
        let origin = req.origin.map { CGPoint(x: $0[0], y: $0[1]) } ?? NSEvent.mouseLocation
        let t0 = CACurrentMediaTime() + 0.05
        let ms = Int(kind.duration * 1000)
        Log.write("\(req.cmd) \(path) H=\(palette.H) C=\(palette.C) \(kind.rawValue)")

        renderTemplates(palette, wallpaper: path)
        Hooks.run("start", paths: paths, durationMS: ms, wallpaper: path)
        picker.model.palette = palette
        morph.start(from: state?.palette, to: palette, kind: kind, t0: t0)
        DispatchQueue.main.asyncAfter(deadline: .now() + max(0, t0 + kind.duration / 2 - CACurrentMediaTime())) {
            [paths] in Hooks.run("mid", paths: paths, durationMS: ms, wallpaper: path)
        }
        let reveals = zip(windows, decoded.images).compactMap { w, image in image.map { (w, $0) } }
        await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in
            var left = reveals.count, resumed = false
            func finish() {
                guard !resumed else { return }
                resumed = true
                done.resume()
            }
            // Watchdog: a reveal whose completion never fires (display asleep) must not wedge the queue.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05 + kind.duration + (reveals.isEmpty ? 0 : 1)) {
                if !resumed, !reveals.isEmpty { Log.write("reveal timed out") }
                finish()
            }
            for (window, image) in reveals {
                window.reveal(image, kind: kind, origin: origin, t0: t0) {
                    left -= 1
                    if left == 0 { finish() }
                }
            }
        }

        if let url = decoded.desktop {
            for window in windows {
                do {
                    try NSWorkspace.shared.setDesktopImageURL(url, for: window.target, options: [
                        .imageScaling: NSImageScaling.scaleProportionallyUpOrDown.rawValue, .allowClipping: true,
                    ])
                } catch {
                    Log.write("setDesktopImageURL: \(error)")
                }
            }
        }
        let next = State(wallpaper: path, H: palette.H, C: palette.C)
        state = next
        try next.save(paths.state)
    }

    private func renderTemplates(_ palette: Palette, wallpaper: String) {
        do {
            try FileManager.default.createDirectory(at: paths.out, withIntermediateDirectories: true)
            try Template.writeAtomic(Data(palette.json(wallpaper: wallpaper).utf8),
                                     to: paths.out.appendingPathComponent("palette.json"))
        } catch {
            Log.write("palette.json: \(error)")
        }
        do {
            try Template.renderDirectory(paths.templates, vars: palette.dictionary(wallpaper: wallpaper), out: paths.out)
        } catch {
            Log.write("render: \(error)")
        }
    }

    // MARK: Screens and picker

    private func rebuildWindows() async {
        for w in windows { w.orderOut(nil) }
        windows = NSScreen.screens.map(DesktopWindow.init)
        for w in windows { w.orderFrontRegardless() }
        guard let path = state?.wallpaper, FileManager.default.fileExists(atPath: path) else { return }
        let decoded = await decode(path, sizes: windows.map(\.pixelSize), full: false)
        for (w, image) in zip(windows, decoded.images) { if let image { w.show(image) } }
    }

    private func screensChanged() {
        rebuildWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.rebuildPending = true
                if !self.busy { self.run(nil) }
            }
        }
        rebuildWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
    }

    private func togglePicker() {
        if picker.isVisible {
            picker.dismiss()
        } else {
            picker.present(paths: WallList.scan(paths.walls).paths, current: state?.wallpaper,
                           palette: state?.palette ?? Palette(H: 205, C: 0.2), thumbs: paths.thumbs)
        }
    }
}
