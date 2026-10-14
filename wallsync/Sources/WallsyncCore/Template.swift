import Foundation

public enum Template {
    /// Replaces `{{key}}` with `vars[key]`; unknown placeholders are left as they are.
    public static func render(_ text: String, _ vars: [String: String]) -> String {
        text.replacing(/\{\{([A-Za-z0-9_]+)\}\}/) { m in vars[String(m.1)] ?? String(m.0) }
    }

    /// Writes via a temp file in the same directory and rename(2), so readers never see a partial file.
    public static func writeAtomic(_ data: Data, to url: URL, executable: Bool = false) throws {
        let tmp = url.deletingLastPathComponent().appendingPathComponent(".\(url.lastPathComponent).\(getpid()).tmp")
        let mode: Int = executable ? 0o755 : 0o644
        guard FileManager.default.createFile(atPath: tmp.path, contents: data, attributes: [.posixPermissions: mode])
        else { throw CocoaError(.fileWriteUnknown, userInfo: [NSFilePathErrorKey: tmp.path]) }
        guard rename(tmp.path, url.path) == 0 else {
            let err = errno
            unlink(tmp.path)
            throw POSIXError(POSIXErrorCode(rawValue: err) ?? .EIO)
        }
    }

    /// Renders every `*.tpl` in `dir` into `out` with `.tpl` stripped; `.sh` outputs are made executable.
    @discardableResult
    public static func renderDirectory(_ dir: URL, vars: [String: String], out: URL) throws -> [URL] {
        try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
        let names = try FileManager.default.contentsOfDirectory(atPath: dir.path)
            .filter { $0.hasSuffix(".tpl") && !$0.hasPrefix(".") }
            .sorted()
        return try names.map { name in
            let text = try String(contentsOf: dir.appendingPathComponent(name), encoding: .utf8)
            let target = out.appendingPathComponent(String(name.dropLast(4)))
            try writeAtomic(Data(render(text, vars).utf8), to: target, executable: target.pathExtension == "sh")
            return target
        }
    }
}
