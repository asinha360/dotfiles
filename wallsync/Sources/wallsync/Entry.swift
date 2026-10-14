import Foundation
import WallsyncCore

@main
enum Entry {
    static func main() {
        signal(SIGPIPE, SIG_IGN)
        let paths = Paths()
        do {
            switch try Command.parse(Array(CommandLine.arguments.dropFirst())) {
            case .daemon:
                Daemon.run(paths)
            case .palette(let path):
                guard let hue = HueExtractor.extract(url: URL(fileURLWithPath: path)) else {
                    fail("cannot decode \(path)")
                }
                print(Palette(H: hue.H, C: hue.C).json(wallpaper: path), terminator: "")
            case .render(let palette, let templates, let out):
                let vars = try Palette.variables(json: Data(contentsOf: URL(fileURLWithPath: palette)))
                try Template.renderDirectory(URL(fileURLWithPath: templates, isDirectory: true), vars: vars,
                                             out: URL(fileURLWithPath: out, isDirectory: true))
            case .request(let req):
                exit(send(req, paths))
            }
        } catch let e as UsageError {
            fputs(e.description + "\n", stderr)
            exit(1)
        } catch {
            fail("\(error)")
        }
    }

    static func send(_ req: Request, _ paths: Paths) -> Int32 {
        do {
            let resp = try IPC.send(req, socket: paths.socket.path)
            guard resp.ok else {
                fputs("wallsync: \(resp.error ?? "request failed")\n", stderr)
                return 1
            }
            if req.cmd == "status" {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
                print(String(decoding: try encoder.encode(resp), as: UTF8.self))
            }
            return 0
        } catch IPC.Failure.notRunning {
            fputs("wallsync: daemon not running\n", stderr)
            return 3
        } catch IPC.Failure.pathTooLong {
            // No daemon can listen on a path longer than sun_path either.
            fputs("wallsync: daemon not running (socket path too long: \(paths.socket.path))\n", stderr)
            return 3
        } catch {
            fputs("wallsync: \(error)\n", stderr)
            return 1
        }
    }

    static func fail(_ message: String) -> Never {
        fputs("wallsync: \(message)\n", stderr)
        exit(1)
    }
}
