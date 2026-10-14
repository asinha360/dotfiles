import Foundation
import WallsyncCore

/// Runs `hooks/apply.sh <phase>` without waiting; output goes to the log, and it is killed after 5s.
enum Hooks {
    static func run(_ phase: String, paths: Paths, durationMS: Int, wallpaper: String) {
        guard FileManager.default.fileExists(atPath: paths.hook.path) else { return }
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:" + (env["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin")
        env["WALLSYNC_OUT"] = paths.out.path
        env["WALLSYNC_PHASE"] = phase
        env["WALLSYNC_DURATION_MS"] = String(durationMS)
        env["WALLSYNC_WALLPAPER"] = wallpaper
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/bash")
        p.arguments = [paths.hook.path, phase]
        p.environment = env
        p.standardInput = FileHandle.nullDevice
        if let log = Log.handle(paths) {
            p.standardOutput = log
            p.standardError = log
        }
        do {
            try p.run()
        } catch {
            Log.write("hook \(phase): \(error)")
            return
        }
        let pid = p.processIdentifier
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if p.isRunning {
                Log.write("hook \(phase): killed after 5s")
                kill(pid, SIGKILL)
            }
        }
    }
}

enum Log {
    static func write(_ message: String) {
        let stamp = Date().formatted(.iso8601)
        fputs("\(stamp) wallsync: \(message)\n", stderr)
    }

    /// Append handle on the log file, shared by hook children.
    static func handle(_ paths: Paths) -> FileHandle? {
        let path = paths.log.path
        try? FileManager.default.createDirectory(at: paths.log.deletingLastPathComponent(), withIntermediateDirectories: true)
        let fd = open(path, O_WRONLY | O_APPEND | O_CREAT | O_CLOEXEC, 0o644)
        return fd < 0 ? nil : FileHandle(fileDescriptor: fd, closeOnDealloc: true)
    }
}
