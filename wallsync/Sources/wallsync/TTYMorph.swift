import Foundation
import QuartzCore
import WallsyncCore

/// Morphs every Ghostty surface from one palette to another with OSC frames at ~30fps, on the same
/// `CACurrentMediaTime` clock and curve as the desktop animation, then sends SIGUSR2 so Ghostty reloads
/// the rendered config (new windows pick up the palette from it).
nonisolated final class TTYMorph: @unchecked Sendable {
    private let queue = DispatchQueue(label: "wallsync.morph", qos: .userInteractive)
    // Everything below is only touched on `queue`.
    private var timer: DispatchSourceTimer?
    private var fds: [Int32] = []
    private var activity: NSObjectProtocol?

    func start(from old: Palette?, to new: Palette, kind: TransitionKind, t0: CFTimeInterval) {
        queue.async { self.begin(from: old, to: new, kind: kind, t0: t0) }
    }

    private func begin(from old: Palette?, to new: Palette, kind: TransitionKind, t0: CFTimeInterval) {
        finish()
        let (pids, ttys) = TTYScan.ttys(childrenOf: "ghostty")
        fds = ttys.compactMap { path in
            let fd = open(path, O_WRONLY | O_NONBLOCK | O_NOCTTY | O_CLOEXEC)
            return fd < 0 ? nil : fd
        }
        let final = OSC.frame(new)
        guard let old, !fds.isEmpty else {
            writeFinal(final, pids: pids)
            return
        }
        let a = OSC.colors(old).map(ColorMath.oklab), b = OSC.colors(new).map(ColorMath.oklab)
        activity = ProcessInfo.processInfo.beginActivity(options: [.userInitiated, .latencyCritical],
                                                         reason: "wallsync terminal morph")
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + max(0, t0 - CACurrentMediaTime()), repeating: .milliseconds(33),
                       leeway: .milliseconds(2))
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            let p = (CACurrentMediaTime() - t0) / kind.duration
            if p >= 1 {
                self.writeFinal(final, pids: pids)
                return
            }
            let frame = OSC.frame(from: a, to: b, t: kind.curve(max(0, p)))
            for fd in self.fds { _ = frame.withUnsafeBytes { write(fd, $0.baseAddress, $0.count) } }
        }
        self.timer = timer
        timer.resume()
    }

    /// The last frame must land exactly, so it retries short writes for up to ~100ms per tty.
    private func writeFinal(_ frame: [UInt8], pids: [pid_t]) {
        for fd in fds {
            frame.withUnsafeBytes { raw in
                var off = 0, tries = 0
                while off < raw.count && tries < 50 {
                    let n = write(fd, raw.baseAddress! + off, raw.count - off)
                    if n > 0 {
                        off += n
                    } else if n < 0 && errno != EAGAIN && errno != EINTR {
                        break
                    } else {
                        tries += 1
                        usleep(2000)
                    }
                }
            }
        }
        for pid in pids { kill(pid, SIGUSR2) }
        finish()
    }

    private func finish() {
        timer?.cancel()
        timer = nil
        for fd in fds { close(fd) }
        fds = []
        if let activity { ProcessInfo.processInfo.endActivity(activity) }
        activity = nil
    }
}
