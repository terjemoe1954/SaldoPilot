import Foundation
#if canImport(SaldoPilot)
@testable import SaldoPilot
#endif

@MainActor
enum ForecastSalarySelectionVerification {
    struct Failure: Error { let message: String }
    final class Server { var values: [String: Any] = [:] }
    final class Cloud: ForecastChoiceCloud {
        let server: Server
        var online = true
        var pending: [String: Data] = [:]
        var cache: [String: Any] = [:]
        var values: [String: Any] { online ? server.values : cache }
        init(_ server: Server) { self.server = server }
        func set(_ data: Data, forKey key: String) { pending[key] = data; cache[key] = data }
        func synchronize() -> Bool {
            guard online else { return false }
            for (key, value) in pending { server.values[key] = value }
            pending = [:]
            cache = server.values
            return true
        }
    }
    static func run() throws {
        func check(_ value: Bool, _ message: String) throws { if !value { throw Failure(message: message) } }
        let suites = (0..<3).map { "ForecastChoiceTests-" + UUID().uuidString + String($0) }
        let defaults = suites.map { UserDefaults(suiteName: $0)! }
        defer { for (suite, defaults) in zip(suites, defaults) { defaults.removePersistentDomain(forName: suite) } }
        let ids = (0..<5).map { _ in UUID().uuidString }
        for (index, store) in defaults.enumerated() {
            store.set(ids[index], forKey: AppSettingsKey.forecastSalaryID)
            store.set("unchanged", forKey: AppSettingsKey.openingBalanceAmount)
        }
        let server = Server()
        // Give all three devices one server, but independent queues and cached settings.
        let connections = (0..<3).map { _ in Cloud(server) }
        let devices = zip(defaults, connections).map { ForecastSalarySelection(defaults: $0, cloud: $1) }
        devices.forEach { $0.start() }
        func converge() { for _ in 0..<5 { for device in devices.reversed() { device.refresh() } } }
        converge()
        try check(Set(devices.map(\.value)).count == 1, "Conflicting legacy choices must converge")
        try check(server.values.count == 3, "Preserve each device's initial choice without colliding on one key")
        devices[0].select(ids[3], now: Date(timeIntervalSince1970: 100))
        converge()
        try check(devices.allSatisfy { $0.value == ids[3] }, "Intentional edit must sync to all three devices")
        devices[2].select("none", now: Date(timeIntervalSince1970: 101))
        converge()
        try check(devices.allSatisfy { $0.value == "none" }, "Clearing a choice must also sync")
        connections[1].online = false
        devices[1].select(ids[1], now: Date(timeIntervalSince1970: 102))
        try check(devices[1].value == ids[1] && devices[1].cloudUnavailable, "Offline edits remain saved locally")
        devices[0].select(ids[4], now: Date(timeIntervalSince1970: 103))
        connections[1].online = true
        converge()
        try check(devices.allSatisfy { $0.value == ids[4] }, "Concurrent edits converge in either delivery order")
        let reloaded = ForecastSalarySelection(defaults: defaults[0], cloud: connections[0])
        reloaded.start()
        try check(reloaded.value == ids[4], "Latest choice must survive reopen")
        let invalid = ForecastSalaryChoice(value: "invalid", writer: UUID().uuidString, revision: 999, explicit: true, modifiedAt: .now)
        server.values[ForecastSalarySelection.prefix + invalid.writer] = try JSONEncoder().encode(invalid)
        converge()
        try check(devices.allSatisfy { $0.value == ids[4] }, "Malformed remote value cannot replace a valid choice")
        devices[1].pauseForAccountChange()
        devices[0].select(ids[0], now: Date(timeIntervalSince1970: 104))
        converge()
        try check(devices[1].value == ids[4] && devices[1].accountChanged, "Account change preserves local selection without automatic reupload")
        devices[1].select(ids[2], now: Date(timeIntervalSince1970: 105))
        converge()
        try check(devices.allSatisfy { $0.value == ids[2] }, "Explicit choice resumes sync after account change")
        try check(defaults.allSatisfy { $0.string(forKey: AppSettingsKey.openingBalanceAmount) == "unchanged" }, "Unrelated settings must not change")
        try check(defaults.allSatisfy { !($0.stringArray(forKey: "forecast.salary.sync.previousChoices") ?? []).isEmpty }, "Displaced choices remain locally preserved")
        let now = Date.now
        let suggested = Transaction(title: "Lønn", amount: 100, type: .income, dueDate: now)
        try check(PaydayForecast.selectedSalary(selection: ids[4], transactions: [suggested], now: now) == nil, "Do not substitute salary before selected transaction arrives")
        try check(PaydayForecast.selectedSalary(selection: suggested.id.uuidString, transactions: [suggested], now: now)?.id == suggested.id, "Resolve choice once transaction arrives")
        try check(PaydayForecast.selectedSalary(selection: "none", transactions: [suggested], now: now) == nil, "Explicitly cleared selection must not be guessed")
    }
}
