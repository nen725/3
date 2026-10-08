import Foundation

struct Account: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var createdAt: Date = Date()
    var currencies: [Currency] = []
    var rentals: [RentalRecord] = []
}

struct Currency: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var amount: Double
}

struct RentalRecord: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var rentDate: Date
    var havocAtRent: Double
    var rentalIncome: Double
}

struct CraftItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var durationSeconds: TimeInterval

    static let defaults: [CraftItem] = [
        CraftItem(name: "高级医疗包", durationSeconds: 8 * 3600),
        CraftItem(name: "装备箱", durationSeconds: 4 * 3600),
        CraftItem(name: "弹药", durationSeconds: 1800),
    ]
}

struct ActiveTimer: Codable, Hashable {
    var itemName: String
    var durationSeconds: TimeInterval
    var startDate: Date
    var targetDate: Date
}

struct HistoryEntry: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var itemName: String
    var completedAt: Date
    var durationSeconds: TimeInterval
}

struct Settings: Codable, Hashable {
    var apiURL: String = ""
    var webURL: String = ""
    var deltaAppScheme: String = ""
    var deltaAppStoreURL: String = "itms-apps://itunes.apple.com/WebObjects/MZSearch.woa/wa/search?media=software&term=%E4%B8%89%E8%A7%92%E6%B4%B2%E8%A1%8C%E5%8A%A8"
    var snoozeMinutes: Int = 10
}

struct Snapshot: Codable {
    var accounts: [Account] = []
    var craftItems: [CraftItem] = []
    var activeTimer: ActiveTimer?
    var history: [HistoryEntry] = []
    var settings: Settings = Settings()
}
