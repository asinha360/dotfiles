import Foundation
import Testing
@testable import WallsyncCore

struct ImageDecodeTests {
    /// A symlinked wallpaper is re-keyed when its target changes, and distinct links keep distinct keys.
    @Test func keyFollowsSymlinkTarget() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("ws-key-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let target = dir.appendingPathComponent("a.png"), link = dir.appendingPathComponent("l.png")
        let other = dir.appendingPathComponent("m.png")
        try Data([1]).write(to: target)
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: target)
        try FileManager.default.createSymbolicLink(at: other, withDestinationURL: target)
        let before = ImageDecode.key(for: link)
        #expect(before != ImageDecode.key(for: other))
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 1_000_000)],
                                              ofItemAtPath: target.path)
        #expect(ImageDecode.key(for: link) != before)
    }
}
