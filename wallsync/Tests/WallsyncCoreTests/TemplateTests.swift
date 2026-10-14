import Foundation
import Testing
@testable import WallsyncCore

func scratchDir() throws -> URL {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent("wallsync-test-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir
}

struct TemplateTests {
    @Test func substitutesKnownAndKeepsUnknown() {
        let vars = ["fg_hex": "#D7DCE0", "H": "205"]
        #expect(Template.render("a={{fg_hex}} h={{H}} x={{nope}} y={{ fg_hex }} {{}}", vars)
            == "a=#D7DCE0 h=205 x={{nope}} y={{ fg_hex }} {{}}")
        #expect(Template.render("{{{{H}}}}", vars) == "{{205}}")
    }

    @Test func rendersDirectory() throws {
        let dir = try scratchDir(), tpl = dir.appendingPathComponent("tpl"), out = dir.appendingPathComponent("out")
        defer { try? FileManager.default.removeItem(at: dir) }
        try FileManager.default.createDirectory(at: tpl, withIntermediateDirectories: true)
        try "bg={{panel_hex}}\n".write(to: tpl.appendingPathComponent("ghostty.conf.tpl"), atomically: true, encoding: .utf8)
        try "#!/bin/sh\necho {{lineHi_argb}} {{unknown}}\n"
            .write(to: tpl.appendingPathComponent("borders.sh.tpl"), atomically: true, encoding: .utf8)
        try "ignored".write(to: tpl.appendingPathComponent("README"), atomically: true, encoding: .utf8)
        let written = try Template.renderDirectory(tpl, vars: Palette(H: 205, C: 0.2).dictionary(), out: out)
        #expect(written.map(\.lastPathComponent) == ["borders.sh", "ghostty.conf"])
        #expect(try String(contentsOf: out.appendingPathComponent("ghostty.conf"), encoding: .utf8) == "bg=#121517\n")
        let sh = out.appendingPathComponent("borders.sh")
        #expect(try String(contentsOf: sh, encoding: .utf8) == "#!/bin/sh\necho 0xB3E2E6E9 {{unknown}}\n")
        #expect(FileManager.default.isExecutableFile(atPath: sh.path))
        #expect(!FileManager.default.isExecutableFile(atPath: out.appendingPathComponent("ghostty.conf").path))
        #expect(try FileManager.default.contentsOfDirectory(atPath: out.path).sorted() == ["borders.sh", "ghostty.conf"])
    }
}
