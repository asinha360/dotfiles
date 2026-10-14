import Foundation
import Testing
@testable import WallsyncCore

struct WallListTests {
    @Test func scanFiltersAndSorts() throws {
        let dir = try scratchDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        try FileManager.default.createDirectory(at: dir.appendingPathComponent("sub"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: dir.appendingPathComponent(".hidden"), withIntermediateDirectories: true)
        for f in ["b.JPG", "a10.png", "a2.png", "c.txt", ".x.png", "sub/d.webp", "e.heic", "f.jpeg", ".hidden/g.png"] {
            FileManager.default.createFile(atPath: dir.appendingPathComponent(f).path, contents: Data())
        }
        let names = WallList.scan(dir).paths.map { String($0.dropFirst(dir.path.count + 1)) }
        #expect(names == ["a2.png", "a10.png", "b.JPG", "e.heic", "f.jpeg", "sub/d.webp"])
        #expect(WallList.scan(dir.appendingPathComponent("missing")).paths.isEmpty)

        let link = dir.deletingLastPathComponent().appendingPathComponent("wallsync-link-\(UUID().uuidString)")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: dir)
        defer { try? FileManager.default.removeItem(at: link) }
        #expect(WallList.scan(link).paths.first == link.path + "/a2.png")
    }

    @Test func nextPrevWrap() {
        let w = WallList(paths: ["/a", "/b", "/c"])
        #expect(w.next(after: "/a") == "/b")
        #expect(w.next(after: "/c") == "/a")
        #expect(w.prev(before: "/a") == "/c")
        #expect(w.prev(before: "/b") == "/a")
        #expect(w.next(after: nil) == "/a")
        #expect(w.prev(before: "/zzz") == "/c")
        #expect(WallList(paths: []).next(after: "/a") == nil)
    }

    @Test func randomNeverRepeatsCurrent() {
        let w = WallList(paths: ["/a", "/b", "/c"])
        var rng = SystemRandomNumberGenerator()
        for _ in 0..<300 { #expect(w.random(excluding: "/b", using: &rng) != "/b") }
        #expect(WallList(paths: ["/a"]).random(excluding: "/a") == "/a")
        #expect(WallList(paths: []).random(excluding: nil) == nil)
    }

    @Test func stateRoundTrip() throws {
        let dir = try scratchDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("nested/state.json")
        let s = State(wallpaper: "/w/fog.png", H: 205, C: 0.2)
        try s.save(url)
        #expect(State.load(url) == s)
        #expect(State.load(dir.appendingPathComponent("none.json")) == nil)
    }

    @Test func pathsFollowHome() {
        let p = Paths(env: ["HOME": "/h"])
        #expect(p.socket.path == "/h/.cache/wallsync/wallsync.sock")
        #expect(p.out.path == "/h/.cache/wallsync/out")
        #expect(p.hook.path == "/h/.config/wallsync/hooks/apply.sh")
        #expect(p.walls.path == "/h/Pictures/walls")
        #expect(Paths(env: ["HOME": "/h", "WALLSYNC_DIR": "/w"]).walls.path == "/w")
    }
}
