import Foundation

/// The applied wallpaper and its palette inputs, persisted in state.json.
public struct State: Codable, Equatable, Sendable {
    public var wallpaper: String
    public var H: Int
    public var C: Double

    public init(wallpaper: String, H: Int, C: Double) {
        self.wallpaper = wallpaper; self.H = H; self.C = C
    }

    public var palette: Palette { Palette(H: H, C: C) }

    public static func load(_ url: URL) -> State? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(State.self, from: data)
    }

    public func save(_ url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Template.writeAtomic(try encoder.encode(self), to: url)
    }
}

/// Installed locations from CONTRACT.md, rooted at $HOME.
public struct Paths: Sendable {
    public let home: URL
    public let walls: URL

    public init(env: [String: String] = ProcessInfo.processInfo.environment) {
        home = URL(fileURLWithPath: env["HOME"] ?? NSHomeDirectory(), isDirectory: true)
        walls = env["WALLSYNC_DIR"].map { URL(fileURLWithPath: $0, isDirectory: true) }
            ?? home.appendingPathComponent("Pictures/walls", isDirectory: true)
    }

    public var config: URL { home.appendingPathComponent(".config/wallsync", isDirectory: true) }
    public var templates: URL { config.appendingPathComponent("templates", isDirectory: true) }
    public var hook: URL { config.appendingPathComponent("hooks/apply.sh") }
    public var cache: URL { home.appendingPathComponent(".cache/wallsync", isDirectory: true) }
    public var out: URL { cache.appendingPathComponent("out", isDirectory: true) }
    public var state: URL { cache.appendingPathComponent("state.json") }
    public var socket: URL { cache.appendingPathComponent("wallsync.sock") }
    public var thumbs: URL { cache.appendingPathComponent("thumbs", isDirectory: true) }
    public var log: URL { home.appendingPathComponent("Library/Logs/wallsync.log") }
}
