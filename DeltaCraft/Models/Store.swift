import Foundation
import Observation

// 数据持久化接口：目前用本地 JSON 文件。
// 以后要做 iPhone / iPad 跨设备同步时，在这里换成一个云端实现即可，
// 界面层不需要改动。
protocol StorageService: AnyObject {
    func load() -> Snapshot?
    func save(_ snapshot: Snapshot)
}

final class LocalJSONStorage: StorageService {
    private let fileURL: URL

    init(fileName: String = "deltacraft-data.json") {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent(fileName)
    }

    func load() -> Snapshot? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(Snapshot.self, from: data)
    }

    func save(_ snapshot: Snapshot) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(snapshot) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }
}

@MainActor
@Observable
final class AppStore {
    static let shared = AppStore()

    var accounts: [Account] = []
    var craftItems: [CraftItem] = []
    var activeTimer: ActiveTimer?
    var history: [HistoryEntry] = []
    var settings: Settings = Settings()

    @ObservationIgnored private let storage: StorageService

    init(storage: StorageService = LocalJSONStorage()) {
        self.storage = storage
        if let snapshot = storage.load() {
            accounts = snapshot.accounts
            craftItems = snapshot.craftItems
            activeTimer = snapshot.activeTimer
            history = snapshot.history
            settings = snapshot.settings
        }
        if craftItems.isEmpty {
            craftItems = CraftItem.defaults
        }
    }

    func save() {
        storage.save(Snapshot(
            accounts: accounts,
            craftItems: craftItems,
            activeTimer: activeTimer,
            history: history,
            settings: settings
        ))
    }

    // MARK: - 账号

    func addAccount(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        accounts.append(Account(name: trimmed))
        save()
    }

    func renameAccount(id: UUID, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let i = accounts.firstIndex(where: { $0.id == id }) else { return }
        accounts[i].name = trimmed
        save()
    }

    func deleteAccount(id: UUID) {
        accounts.removeAll { $0.id == id }
        save()
    }

    // MARK: - 货币

    func addCurrency(accountID: UUID, name: String, amount: Double) {
        guard let i = accounts.firstIndex(where: { $0.id == accountID }) else { return }
        accounts[i].currencies.append(Currency(name: name, amount: amount))
        save()
    }

    func updateCurrency(accountID: UUID, currencyID: UUID, name: String, amount: Double) {
        guard let i = accounts.firstIndex(where: { $0.id == accountID }),
              let j = accounts[i].currencies.firstIndex(where: { $0.id == currencyID }) else { return }
        accounts[i].currencies[j].name = name
        accounts[i].currencies[j].amount = amount
        save()
    }

    func deleteCurrency(accountID: UUID, currencyID: UUID) {
        guard let i = accounts.firstIndex(where: { $0.id == accountID }) else { return }
        accounts[i].currencies.removeAll { $0.id == currencyID }
        save()
    }

    // MARK: - 出租记录

    func addRental(accountID: UUID, date: Date, havoc: Double, income: Double) {
        guard let i = accounts.firstIndex(where: { $0.id == accountID }) else { return }
        accounts[i].rentals.append(RentalRecord(rentDate: date, havocAtRent: havoc, rentalIncome: income))
        accounts[i].rentals.sort { $0.rentDate > $1.rentDate }
        save()
    }

    func updateRental(accountID: UUID, rentalID: UUID, date: Date, havoc: Double, income: Double) {
        guard let i = accounts.firstIndex(where: { $0.id == accountID }),
              let j = accounts[i].rentals.firstIndex(where: { $0.id == rentalID }) else { return }
        accounts[i].rentals[j].rentDate = date
        accounts[i].rentals[j].havocAtRent = havoc
        accounts[i].rentals[j].rentalIncome = income
        accounts[i].rentals.sort { $0.rentDate > $1.rentDate }
        save()
    }

    func deleteRental(accountID: UUID, rentalID: UUID) {
        guard let i = accounts.firstIndex(where: { $0.id == accountID }) else { return }
        accounts[i].rentals.removeAll { $0.id == rentalID }
        save()
    }

    // MARK: - 制造物品

    func addItem(name: String, hours: Int, minutes: Int) {
        let seconds = TimeInterval(hours * 3600 + minutes * 60)
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard seconds > 0, !trimmed.isEmpty else { return }
        craftItems.append(CraftItem(name: trimmed, durationSeconds: seconds))
        save()
    }

    func deleteItem(id: UUID) {
        craftItems.removeAll { $0.id == id }
        save()
    }

    // MARK: - 倒计时

    func startTimer(itemName: String, duration: TimeInterval) {
        let now = Date()
        let target = now.addingTimeInterval(duration)
        activeTimer = ActiveTimer(itemName: itemName, durationSeconds: duration, startDate: now, targetDate: target)
        NotificationManager.shared.schedule(itemName: itemName, duration: duration, target: target)
        save()
    }

    func cancelTimer() {
        activeTimer = nil
        NotificationManager.shared.cancel()
        save()
    }

    func completeTimer() {
        guard let timer = activeTimer else { return }
        history.insert(HistoryEntry(itemName: timer.itemName, completedAt: Date(), durationSeconds: timer.durationSeconds), at: 0)
        activeTimer = nil
        NotificationManager.shared.cancel()
        save()
    }

    func completeAndRestart() {
        guard let timer = activeTimer else { return }
        history.insert(HistoryEntry(itemName: timer.itemName, completedAt: Date(), durationSeconds: timer.durationSeconds), at: 0)
        startTimer(itemName: timer.itemName, duration: timer.durationSeconds)
    }

    func snoozeTimer() {
        guard var timer = activeTimer else { return }
        let newTarget = Date().addingTimeInterval(TimeInterval(settings.snoozeMinutes * 60))
        timer.targetDate = newTarget
        activeTimer = timer
        NotificationManager.shared.schedule(itemName: timer.itemName, duration: timer.durationSeconds, target: newTarget)
        save()
    }

    func countFor(itemName: String) -> Int {
        history.filter { $0.itemName == itemName }.count
    }

    func clearHistory() {
        history.removeAll()
        save()
    }

    // MARK: - 备份 / 恢复

    func exportData() -> Data? {
        let snapshot = Snapshot(
            accounts: accounts,
            craftItems: craftItems,
            activeTimer: activeTimer,
            history: history,
            settings: settings
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(snapshot)
    }

    func importData(from url: URL) -> Bool {
        let didStart = url.startAccessingSecurityScopedResource()
        defer {
            if didStart { url.stopAccessingSecurityScopedResource() }
        }

        guard let data = try? Data(contentsOf: url) else { return false }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let snapshot = try? decoder.decode(Snapshot.self, from: data) else { return false }

        accounts = snapshot.accounts
        craftItems = snapshot.craftItems
        activeTimer = snapshot.activeTimer
        history = snapshot.history
        settings = snapshot.settings
        if craftItems.isEmpty {
            craftItems = CraftItem.defaults
        }
        save()
        rescheduleActiveTimer()
        return true
    }

    private func rescheduleActiveTimer() {
        NotificationManager.shared.cancel()
        if let timer = activeTimer, timer.targetDate > Date() {
            NotificationManager.shared.schedule(itemName: timer.itemName, duration: timer.durationSeconds, target: timer.targetDate)
        }
    }
}
