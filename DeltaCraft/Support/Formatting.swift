import Foundation

enum Format {
    static func compact(_ value: Double) -> String {
        let sign = value < 0 ? "-" : ""
        let v = abs(value)
        if v >= 1_000_000 {
            return sign + trim(v / 1_000_000) + "m"
        } else if v >= 1_000 {
            return sign + trim(v / 1_000) + "k"
        } else {
            return sign + (v == v.rounded() ? String(Int(v)) : trim(v))
        }
    }

    static func trim(_ n: Double) -> String {
        var out = String(format: "%.2f", n)
        while out.hasSuffix("0") { out.removeLast() }
        if out.hasSuffix(".") { out.removeLast() }
        return out
    }

    static func rawNumber(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int64(value))
        } else {
            return String(format: "%.2f", value)
        }
    }

    static func parseAmount(_ s: String) -> Double? {
        var t = s.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: "")
        guard !t.isEmpty else { return nil }
        let lower = t.lowercased()
        var multiplier: Double = 1
        if lower.hasSuffix("m") {
            multiplier = 1_000_000
            t.removeLast()
        } else if lower.hasSuffix("k") {
            multiplier = 1_000
            t.removeLast()
        }
        guard let n = Double(t.trimmingCharacters(in: .whitespaces)) else { return nil }
        return n * multiplier
    }

    static func duration(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return m > 0 ? "\(h)小时\(m)分" : "\(h)小时"
        } else if m > 0 {
            return s > 0 ? "\(m)分\(s)秒" : "\(m)分钟"
        } else {
            return "\(s)秒"
        }
    }
}
