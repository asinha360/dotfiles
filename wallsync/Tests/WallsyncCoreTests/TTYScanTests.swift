import Foundation
import Testing
@testable import WallsyncCore

struct TTYScanTests {
    @Test func findsOwnChildren() throws {
        let procs = TTYScan.processes()
        let me = try #require(procs.first { $0.pid == getpid() })
        #expect(me.ppid == getppid())
        #expect(!me.name.isEmpty)

        let child = Process()
        child.executableURL = URL(fileURLWithPath: "/bin/sleep")
        child.arguments = ["5"]
        try child.run()
        defer { child.terminate() }
        let found = TTYScan.processes().first { $0.pid == child.processIdentifier }
        #expect(found?.ppid == getpid())
        #expect(found?.name == "sleep")
    }

    /// Every process ps shows with a tty, including root-owned ones like Ghostty's /usr/bin/login, has it.
    @Test func matchesPs() throws {
        let ps = Process(), pipe = Pipe()
        ps.executableURL = URL(fileURLWithPath: "/bin/ps")
        ps.arguments = ["-axo", "pid=,user=,tty="]
        ps.standardOutput = pipe
        try ps.run()
        let out = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        ps.waitUntilExit()
        let byPid = Dictionary(TTYScan.processes().map { ($0.pid, $0) }, uniquingKeysWith: { a, _ in a })
        #expect(byPid[1]?.name == "launchd")
        var checked = 0
        for line in out.split(separator: "\n") {
            let f = line.split(separator: " ", omittingEmptySubsequences: true)
            guard f.count == 3, let pid = pid_t(f[0]), f[2] != "??" else { continue }
            // Short-lived processes (ps itself) may be gone by now; root-owned logins must not be missing.
            guard let p = byPid[pid] else {
                #expect(f[1] != "root", "root pid \(pid) missing")
                continue
            }
            #expect(p.tty == "/dev/" + f[2], "pid \(pid)")
            checked += 1
        }
        #expect(checked > 0)
    }

    @Test func ttysOfChildren() {
        let procs = [
            TTYScan.Proc(pid: 10, ppid: 1, name: "ghostty", tty: nil),
            TTYScan.Proc(pid: 11, ppid: 10, name: "login", tty: "/dev/ttys001"),
            TTYScan.Proc(pid: 12, ppid: 10, name: "login", tty: "/dev/ttys002"),
            TTYScan.Proc(pid: 13, ppid: 10, name: "helper", tty: nil),
            TTYScan.Proc(pid: 14, ppid: 11, name: "zsh", tty: "/dev/ttys001"),
            TTYScan.Proc(pid: 20, ppid: 1, name: "Terminal", tty: nil),
            TTYScan.Proc(pid: 21, ppid: 20, name: "login", tty: "/dev/ttys009"),
        ]
        let r = TTYScan.ttys(childrenOf: "ghostty", in: procs)
        #expect(r.pids == [10])
        #expect(r.ttys == ["/dev/ttys001", "/dev/ttys002"])
        #expect(TTYScan.ttys(childrenOf: "nope", in: procs).ttys.isEmpty)
    }
}
