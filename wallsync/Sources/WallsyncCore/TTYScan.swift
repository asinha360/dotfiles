import Darwin
import Foundation

/// Process table lookups: terminal pids by name and the ttys of their child processes.
public enum TTYScan {
    public struct Proc: Equatable, Sendable {
        public let pid: pid_t
        public let ppid: pid_t
        public let name: String
        /// `/dev/ttysNNN`, or nil without a controlling terminal.
        public let tty: String?
    }

    /// Every process, read with sysctl(KERN_PROC_ALL). Unlike proc_pidinfo this also covers processes of
    /// other users, such as the setuid-root /usr/bin/login that Ghostty starts each surface through.
    public static func processes() -> [Proc] {
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0]
        var table: [kinfo_proc] = []
        for _ in 0..<4 {
            var size = 0
            guard sysctl(&mib, u_int(mib.count), nil, &size, nil, 0) == 0 else { return [] }
            table = [kinfo_proc](repeating: kinfo_proc(), count: size / MemoryLayout<kinfo_proc>.stride + 32)
            size = table.count * MemoryLayout<kinfo_proc>.stride
            if sysctl(&mib, u_int(mib.count), &table, &size, nil, 0) == 0 {
                table.removeLast(table.count - size / MemoryLayout<kinfo_proc>.stride)
                break
            }
            table = []
            guard errno == ENOMEM else { return [] }
        }
        return table.compactMap { kp in
            let pid = kp.kp_proc.p_pid
            guard pid > 0 else { return nil }
            let name = withUnsafeBytes(of: kp.kp_proc.p_comm) { String(decoding: $0.prefix { $0 != 0 }, as: UTF8.self) }
            var tty: String?
            if kp.kp_eproc.e_tdev != -1 /* NODEV */, let dev = devname(kp.kp_eproc.e_tdev, S_IFCHR) {
                tty = "/dev/" + String(cString: dev)
            }
            return Proc(pid: pid, ppid: kp.kp_eproc.e_ppid, name: name, tty: tty)
        }
    }

    /// Pids of processes named `name` and the distinct ttys of their direct children.
    public static func ttys(childrenOf name: String, in procs: [Proc] = processes()) -> (pids: [pid_t], ttys: [String]) {
        let parents = Set(procs.filter { $0.name == name }.map(\.pid))
        var seen = Set<String>(), ttys: [String] = []
        for p in procs where parents.contains(p.ppid) {
            if let t = p.tty, seen.insert(t).inserted { ttys.append(t) }
        }
        return (parents.sorted(), ttys)
    }
}
