import Darwin
import Foundation

/// One request per connection: a JSON line in, a JSON line back.
public struct Request: Codable, Equatable, Sendable {
    public var cmd: String
    public var path: String?
    public var transition: TransitionKind?
    /// Grow origin in global Cocoa coordinates (points, bottom-left of the primary screen).
    public var origin: [Double]?

    public init(cmd: String, path: String? = nil, transition: TransitionKind? = nil, origin: [Double]? = nil) {
        self.cmd = cmd; self.path = path; self.transition = transition; self.origin = origin
    }
}

public struct Response: Codable, Equatable, Sendable {
    public var ok: Bool
    public var error: String?
    public var wallpaper: String?
    public var H: Int?
    public var C: Double?
    public var busy: Bool?

    public init(ok: Bool, error: String? = nil, wallpaper: String? = nil, H: Int? = nil, C: Double? = nil,
                busy: Bool? = nil) {
        self.ok = ok; self.error = error; self.wallpaper = wallpaper; self.H = H; self.C = C; self.busy = busy
    }
}

public struct UsageError: Error, CustomStringConvertible {
    public let description: String
    public init(_ description: String) { self.description = description }
}

public enum Command: Equatable, Sendable {
    case daemon
    case palette(String)
    case render(palette: String, templates: String, out: String)
    case request(Request)

    public static let usage = """
        usage: wallsync daemon
               wallsync set <path> [--transition wipe|grow] [--origin x,y]
               wallsync next|prev|random [--transition wipe|grow]
               wallsync pick
               wallsync palette <path>
               wallsync render <palette.json> <templates_dir> <out_dir>
               wallsync status
        """

    public static func parse(_ args: [String], cwd: String = FileManager.default.currentDirectoryPath) throws
        -> Command
    {
        guard let cmd = args.first else { throw UsageError(usage) }
        var rest = Array(args.dropFirst())
        func absolute(_ p: String) -> String {
            URL(fileURLWithPath: p, relativeTo: URL(fileURLWithPath: cwd, isDirectory: true)).standardizedFileURL.path
        }
        func option(_ name: String) throws -> String? {
            guard let i = rest.firstIndex(of: name) else { return nil }
            guard i + 1 < rest.count else { throw UsageError("\(name) needs a value") }
            defer { rest.removeSubrange(i...i + 1) }
            return rest[i + 1]
        }
        func transition() throws -> TransitionKind? {
            guard let v = try option("--transition") else { return nil }
            guard let t = TransitionKind(rawValue: v) else { throw UsageError("--transition must be wipe or grow") }
            return t
        }
        func expect(_ n: Int) throws {
            if rest.count != n { throw UsageError(usage) }
        }
        switch cmd {
        case "daemon":
            try expect(0)
            return .daemon
        case "set":
            let t = try transition()
            var origin: [Double]?
            if let o = try option("--origin") {
                let xy = o.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
                guard xy.count == 2 else { throw UsageError("--origin must be x,y") }
                origin = xy
            }
            try expect(1)
            return .request(Request(cmd: "set", path: absolute(rest[0]), transition: t, origin: origin))
        case "next", "prev", "random":
            let t = try transition()
            try expect(0)
            return .request(Request(cmd: cmd, transition: t))
        case "pick", "status":
            try expect(0)
            return .request(Request(cmd: cmd))
        case "palette":
            try expect(1)
            return .palette(absolute(rest[0]))
        case "render":
            try expect(3)
            return .render(palette: rest[0], templates: rest[1], out: rest[2])
        default:
            throw UsageError(usage)
        }
    }
}

public enum IPC {
    public enum Failure: Error, Equatable {
        case notRunning, alreadyRunning, pathTooLong, io(String)
    }

    static func address(_ path: String) throws -> sockaddr_un {
        var addr = sockaddr_un()
        let bytes = Array(path.utf8)
        guard bytes.count < MemoryLayout.size(ofValue: addr.sun_path) else { throw Failure.pathTooLong }
        addr.sun_family = sa_family_t(AF_UNIX)
        addr.sun_len = UInt8(MemoryLayout<sockaddr_un>.size)
        withUnsafeMutableBytes(of: &addr.sun_path) { $0.copyBytes(from: bytes) }
        return addr
    }

    static func withAddress<T>(_ path: String, _ body: (UnsafePointer<sockaddr>, socklen_t) -> T) throws -> T {
        var addr = try address(path)
        return withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { body($0, socklen_t(MemoryLayout<sockaddr_un>.size)) }
        }
    }

    static func configure(_ fd: Int32, timeout: Double) {
        var tv = timeval(tv_sec: Int(timeout), tv_usec: Int32((timeout - floor(timeout)) * 1_000_000))
        let tvSize = socklen_t(MemoryLayout<timeval>.size)
        setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, tvSize)
        setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &tv, tvSize)
        var on: Int32 = 1
        setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &on, socklen_t(MemoryLayout<Int32>.size))
    }

    static func connect(_ path: String) throws -> Int32 {
        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else { throw Failure.io("socket: errno \(errno)") }
        guard try withAddress(path, { Darwin.connect(fd, $0, $1) }) == 0 else {
            close(fd)
            throw Failure.notRunning
        }
        return fd
    }

    /// Sends one request to the daemon and waits for its reply. Throws `.notRunning` without a daemon.
    public static func send(_ req: Request, socket path: String, timeout: Double = 10) throws -> Response {
        let fd = try connect(path)
        defer { close(fd) }
        configure(fd, timeout: timeout)
        guard writeAll(fd, try JSONEncoder().encode(req) + [0x0A]) else { throw Failure.io("write failed") }
        guard let line = readLine(fd) else { throw Failure.io("no reply from daemon") }
        return try JSONDecoder().decode(Response.self, from: line)
    }

    /// Binds the listening socket (mode 0600), replacing a stale one. Throws `.alreadyRunning` if a
    /// daemon answers on it.
    public static func listen(at path: String) throws -> Int32 {
        if FileManager.default.fileExists(atPath: path) {
            if let fd = try? connect(path) {
                close(fd)
                throw Failure.alreadyRunning
            }
            unlink(path)
        }
        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else { throw Failure.io("socket: errno \(errno)") }
        guard try withAddress(path, { bind(fd, $0, $1) }) == 0 else {
            let err = errno
            close(fd)
            throw Failure.io("bind \(path): errno \(err)")
        }
        chmod(path, 0o600)
        guard Darwin.listen(fd, 16) == 0 else {
            close(fd)
            throw Failure.io("listen: errno \(errno)")
        }
        return fd
    }

    /// Reads the request line from an accepted client. Blocks up to `timeout`.
    public static func readRequest(_ fd: Int32, timeout: Double = 2) -> Request? {
        configure(fd, timeout: timeout)
        return readLine(fd).flatMap { try? JSONDecoder().decode(Request.self, from: $0) }
    }

    /// Writes the reply line and closes the client.
    public static func reply(_ fd: Int32, _ resp: Response) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        _ = writeAll(fd, ((try? encoder.encode(resp)) ?? Data()) + [0x0A])
        close(fd)
    }

    /// Listening socket driven by a DispatchSource. Each client is read off the main thread, answered by
    /// `handle` on the main actor, and replied to off the main thread.
    public final class Server: Sendable {
        let path: String
        let source: DispatchSourceRead

        public init(path: String, handle: @escaping @MainActor @Sendable (Request) -> Response) throws {
            let fd = try IPC.listen(at: path)
            _ = fcntl(fd, F_SETFL, O_NONBLOCK)
            self.path = path
            source = DispatchSource.makeReadSource(fileDescriptor: fd, queue: DispatchQueue(label: "wallsync.ipc"))
            source.setEventHandler {
                while true {
                    let client = accept(fd, nil, nil)
                    if client < 0 { break }
                    // Accepted sockets inherit O_NONBLOCK on Darwin; the client reads rely on SO_RCVTIMEO.
                    _ = fcntl(client, F_SETFL, 0)
                    DispatchQueue.global(qos: .userInitiated).async {
                        guard let req = IPC.readRequest(client) else {
                            close(client)
                            return
                        }
                        Task { @MainActor in
                            let resp = handle(req)
                            DispatchQueue.global(qos: .userInitiated).async { IPC.reply(client, resp) }
                        }
                    }
                }
            }
            source.setCancelHandler { close(fd) }
            source.resume()
        }

        public func stop() {
            source.cancel()
            unlink(path)
        }
    }

    static func readLine(_ fd: Int32, limit: Int = 1 << 16) -> Data? {
        var out = Data()
        var buf = [UInt8](repeating: 0, count: 4096)
        while out.count < limit {
            let n = buf.withUnsafeMutableBytes { read(fd, $0.baseAddress, $0.count) }
            if n <= 0 { break }
            if let i = buf[0..<n].firstIndex(of: 0x0A) {
                out.append(contentsOf: buf[0..<i])
                return out
            }
            out.append(contentsOf: buf[0..<n])
        }
        return out.isEmpty ? nil : out
    }

    static func writeAll(_ fd: Int32, _ data: Data) -> Bool {
        data.withUnsafeBytes { raw in
            var off = 0
            while off < raw.count {
                let n = write(fd, raw.baseAddress! + off, raw.count - off)
                if n <= 0 { return false }
                off += n
            }
            return true
        }
    }
}
