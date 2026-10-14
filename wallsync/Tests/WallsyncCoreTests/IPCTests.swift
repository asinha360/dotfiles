import Foundation
import Testing
@testable import WallsyncCore

struct IPCTests {
    @Test func parsesCommands() throws {
        #expect(try Command.parse(["daemon"]) == .daemon)
        #expect(try Command.parse(["set", "a/b.png", "--transition", "grow", "--origin", "10,-20.5"], cwd: "/w")
            == .request(Request(cmd: "set", path: "/w/a/b.png", transition: .grow, origin: [10, -20.5])))
        #expect(try Command.parse(["set", "--transition", "wipe", "/x.png"], cwd: "/w")
            == .request(Request(cmd: "set", path: "/x.png", transition: .wipe)))
        #expect(try Command.parse(["next"]) == .request(Request(cmd: "next")))
        #expect(try Command.parse(["random", "--transition", "wipe"]) == .request(Request(cmd: "random", transition: .wipe)))
        #expect(try Command.parse(["pick"]) == .request(Request(cmd: "pick")))
        #expect(try Command.parse(["status"]) == .request(Request(cmd: "status")))
        #expect(try Command.parse(["palette", "f.png"], cwd: "/w") == .palette("/w/f.png"))
        #expect(try Command.parse(["render", "p.json", "t", "o"]) == .render(palette: "p.json", templates: "t", out: "o"))
        for bad in [[], ["bogus"], ["set"], ["next", "x"], ["set", "a", "--transition", "fade"], ["set", "a", "--origin", "1"],
                    ["render", "a", "b"], ["set", "a", "--transition"]] {
            #expect(throws: UsageError.self) { try Command.parse(bad) }
        }
    }

    @Test func requestJSON() throws {
        let r = Request(cmd: "set", path: "/a.png", transition: .grow, origin: [1, 2])
        #expect(try JSONDecoder().decode(Request.self, from: JSONEncoder().encode(r)) == r)
        let raw = Data(#"{"cmd":"next","transition":"wipe"}"#.utf8)
        #expect(try JSONDecoder().decode(Request.self, from: raw) == Request(cmd: "next", transition: .wipe))
    }

    @Test func notRunningWithoutDaemon() throws {
        let path = FileManager.default.temporaryDirectory.appendingPathComponent("ws-none-\(getpid()).sock").path
        #expect(throws: IPC.Failure.notRunning) { try IPC.send(Request(cmd: "status"), socket: path) }
        #expect(throws: IPC.Failure.pathTooLong) {
            try IPC.send(Request(cmd: "status"), socket: "/tmp/" + String(repeating: "x", count: 120))
        }
    }

    @Test func roundTrip() throws {
        let path = FileManager.default.temporaryDirectory.appendingPathComponent("ws-\(getpid()).sock").path
        let fd = try IPC.listen(at: path)
        defer { close(fd); unlink(path) }
        var st = stat()
        stat(path, &st)
        #expect(st.st_mode & 0o777 == 0o600)
        #expect(throws: IPC.Failure.alreadyRunning) { try IPC.listen(at: path) }
        signal(SIGPIPE, SIG_IGN)
        // The alreadyRunning probe above is queued first; skip connections that send nothing.
        let server = Thread {
            while true {
                let client = accept(fd, nil, nil)
                guard let req = IPC.readRequest(client) else { close(client); continue }
                IPC.reply(client, Response(ok: req.cmd == "status", wallpaper: req.path, H: 205, C: 0.2, busy: false))
                return
            }
        }
        server.start()
        let resp = try IPC.send(Request(cmd: "status", path: "/x.png"), socket: path)
        #expect(resp == Response(ok: true, wallpaper: "/x.png", H: 205, C: 0.2, busy: false))
    }

    @Test func serverAnswersOnTheMainActor() async throws {
        let path = FileManager.default.temporaryDirectory.appendingPathComponent("ws-srv-\(getpid()).sock").path
        let server = try IPC.Server(path: path) { req in
            MainActor.assertIsolated()
            return Response(ok: true, wallpaper: req.path, busy: req.cmd == "set")
        }
        defer { server.stop() }
        // A client that connects and sends nothing must not block the others.
        let idle = try IPC.connect(path)
        defer { close(idle) }
        let results = try await withThrowingTaskGroup(of: Response.self) { group in
            for i in 0..<8 {
                group.addTask { try IPC.send(Request(cmd: "set", path: "/w/\(i).png"), socket: path, timeout: 5) }
            }
            return try await group.reduce(into: []) { $0.append($1) }
        }
        #expect(Set(results.compactMap(\.wallpaper)) == Set((0..<8).map { "/w/\($0).png" }))
        #expect(results.allSatisfy { $0.ok && $0.busy == true })
    }
}
