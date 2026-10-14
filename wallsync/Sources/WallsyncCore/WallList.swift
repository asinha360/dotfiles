import Foundation

/// Wallpapers in a directory (recursive), sorted by path.
public struct WallList: Equatable, Sendable {
    public static let extensions: Set<String> = ["png", "jpg", "jpeg", "heic", "webp"]
    public let paths: [String]

    public init(paths: [String]) { self.paths = paths }

    /// Paths keep the `dir` prefix as given, even when `dir` is a symlink.
    public static func scan(_ dir: URL) -> WallList {
        let root = dir.standardizedFileURL.path
        let real = URL(fileURLWithPath: root).resolvingSymlinksInPath().path
        guard let e = FileManager.default.enumerator(atPath: real) else { return WallList(paths: []) }
        var found: [String] = []
        for case let rel as String in e {
            if (rel as NSString).lastPathComponent.hasPrefix(".") {
                e.skipDescendants()
            } else if extensions.contains((rel as NSString).pathExtension.lowercased()) {
                found.append(root + "/" + rel)
            }
        }
        return WallList(paths: found.sorted { $0.localizedStandardCompare($1) == .orderedAscending })
    }

    func step(from current: String?, by delta: Int) -> String? {
        guard !paths.isEmpty else { return nil }
        guard let current, let i = paths.firstIndex(of: current) else {
            return delta > 0 ? paths.first : paths.last
        }
        return paths[((i + delta) % paths.count + paths.count) % paths.count]
    }

    public func next(after current: String?) -> String? { step(from: current, by: 1) }
    public func prev(before current: String?) -> String? { step(from: current, by: -1) }

    /// A random wallpaper other than `current` (unless it is the only one).
    public func random(excluding current: String?, using rng: inout some RandomNumberGenerator) -> String? {
        let pool = paths.count > 1 ? paths.filter { $0 != current } : paths
        return pool.randomElement(using: &rng)
    }

    public func random(excluding current: String?) -> String? {
        var rng = SystemRandomNumberGenerator()
        return random(excluding: current, using: &rng)
    }
}
