import Foundation
import Observation

/// One atomic selection per device avoids partial values and concurrent writes to the same iCloud key.
struct ForecastSalaryChoice: Codable, Equatable {
    var version = 1
    let value: String
    let writer: String
    let revision: Int64
    let explicit: Bool
    let modifiedAt: Date

    var isValid: Bool {
        version == 1 && (value == "none" || UUID(uuidString: value) != nil)
            && UUID(uuidString: writer) != nil && revision >= 0
            && modifiedAt.timeIntervalSinceReferenceDate.isFinite
    }
    static func preferred(_ lhs: Self, _ rhs: Self) -> Self {
        if lhs.explicit != rhs.explicit { return lhs.explicit ? lhs : rhs }
        if lhs.revision != rhs.revision { return lhs.revision > rhs.revision ? lhs : rhs }
        if lhs.modifiedAt != rhs.modifiedAt { return lhs.modifiedAt > rhs.modifiedAt ? lhs : rhs }
        return lhs.writer > rhs.writer ? lhs : rhs
    }
}

@MainActor
protocol ForecastChoiceCloud: AnyObject {
    var values: [String: Any] { get }
    func set(_ data: Data, forKey key: String)
    func synchronize() -> Bool
}

@MainActor
final class UbiquitousForecastChoiceCloud: ForecastChoiceCloud {
    private let store = NSUbiquitousKeyValueStore.default
    var values: [String: Any] { store.dictionaryRepresentation }
    func set(_ data: Data, forKey key: String) { store.set(data, forKey: key) }
    func synchronize() -> Bool { store.synchronize() }
}

@MainActor
@Observable
final class ForecastSalarySelection {
    static let prefix = "forecast.salary.v1.device."
    private(set) var value: String
    private(set) var cloudUnavailable = false
    private(set) var accountChanged = false
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let cloud: (any ForecastChoiceCloud)?
    @ObservationIgnored private let namespace: String
    @ObservationIgnored private let writer: String
    @ObservationIgnored private var current: ForecastSalaryChoice?
    @ObservationIgnored private var observer: NSObjectProtocol?
    @ObservationIgnored private var started = false
    @ObservationIgnored private var identity: (() -> Data?)?

    init(defaults: UserDefaults = .standard, cloud: (any ForecastChoiceCloud)? = nil, namespace: String = "forecast.salary.sync") {
        self.defaults = defaults
        self.cloud = cloud
        self.namespace = namespace
        self.value = defaults.string(forKey: AppSettingsKey.forecastSalaryID) ?? ""
        if let existing = defaults.string(forKey: namespace + ".writer"), UUID(uuidString: existing) != nil {
            writer = existing
        } else {
            writer = UUID().uuidString
            defaults.set(writer, forKey: namespace + ".writer")
        }
        if let data = defaults.data(forKey: namespace + ".current"),
           let saved = try? JSONDecoder().decode(ForecastSalaryChoice.self, from: data), saved.isValid {
            current = saved
            value = saved.value
        }
        accountChanged = defaults.bool(forKey: namespace + ".accountChanged")
    }

    static func live() -> ForecastSalarySelection {
        // Debug screenshots and isolated tests never read or write production iCloud settings.
        let selection = ForecastSalarySelection(
            cloud: AppLaunchConfiguration.usesIsolatedTestStore ? nil : UbiquitousForecastChoiceCloud(),
            namespace: AppLaunchConfiguration.usesIsolatedTestStore ? "forecast.salary.sync.test" : "forecast.salary.sync"
        )
        if !AppLaunchConfiguration.usesIsolatedTestStore {
            selection.identity = {
                guard let token = FileManager.default.ubiquityIdentityToken else { return nil }
                return try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: false)
            }
        }
        return selection
    }

    func start() {
        guard !started else { return }
        started = true
        if cloud != nil {
            observer = NotificationCenter.default.addObserver(forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: nil, queue: .main) { [weak self] notification in
                let reason = notification.userInfo?[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    if reason == NSUbiquitousKeyValueStoreAccountChange {
                        self.pauseForAccountChange()
                    } else if reason == NSUbiquitousKeyValueStoreQuotaViolationChange {
                        self.cloudUnavailable = true
                    } else { self.refresh() }
                }
            }
        }
        checkIdentity()
        migrateLegacyChoice()
        refresh()
    }

    func pauseForAccountChange() {
        accountChanged = true
        defaults.set(true, forKey: namespace + ".accountChanged")
        // Preserve the local value, but do not copy it into a different iCloud account automatically.
    }

    func refresh() {
        checkIdentity()
        guard !accountChanged, let cloud else { return }
        cloudUnavailable = !cloud.synchronize()
        let records = decodedRecords()
        let winner = records.reduce(current) { winner, candidate in
            winner.map { ForecastSalaryChoice.preferred($0, candidate) } ?? candidate
        }
        if let local = ownRecord(), !records.contains(local), !cloudUnavailable,
           let encoded = try? JSONEncoder().encode(local) {
            cloud.set(encoded, forKey: Self.prefix + writer)
        }
        // Read-only reconciliation never turns a remote choice into a new local edit.
        if let chosen = winner { apply(chosen) }
    }

    func select(_ newValue: String, now: Date = .now) {
        checkIdentity()
        guard newValue == "none" || UUID(uuidString: newValue) != nil else { return }
        if accountChanged {
            accountChanged = false
            defaults.set(false, forKey: namespace + ".accountChanged")
            current = nil
            if let token = identity?() { defaults.set(token, forKey: namespace + ".account") }
            defaults.removeObject(forKey: namespace + ".own")
        }
        let maximum = (decodedRecords() + [current].compactMap { $0 }).map(\.revision).max() ?? 0
        guard maximum < Int64.max else { cloudUnavailable = true; return }
        let record = ForecastSalaryChoice(value: newValue, writer: writer, revision: maximum + 1, explicit: true, modifiedAt: now)
        persistOwn(record)
        apply(record)
        refresh()
    }

    private func checkIdentity() {
        guard let identity else { return }
        let token = identity()
        if let previous = defaults.data(forKey: namespace + ".account") {
            if previous != token { pauseForAccountChange() }
        } else if let token { defaults.set(token, forKey: namespace + ".account") }
    }

    private func migrateLegacyChoice() {
        guard current == nil, !accountChanged,
              value == "none" || UUID(uuidString: value) != nil else { return }
        // Imports are always lower priority than an intentional selection, even on a newly upgraded device.
        let seed = ForecastSalaryChoice(value: value, writer: writer, revision: 0, explicit: false, modifiedAt: Date(timeIntervalSince1970: 0))
        persistOwn(seed)
        apply(seed)
    }

    private func decodedRecords() -> [ForecastSalaryChoice] {
        (cloud?.values ?? [:]).compactMap { key, value in
            guard key.hasPrefix(Self.prefix), let data = value as? Data,
                  let record = try? JSONDecoder().decode(ForecastSalaryChoice.self, from: data), record.isValid,
                  key == Self.prefix + record.writer else { return nil }
            return record
        }
    }
    private func ownRecord() -> ForecastSalaryChoice? {
        guard let data = defaults.data(forKey: namespace + ".own"),
              let record = try? JSONDecoder().decode(ForecastSalaryChoice.self, from: data), record.isValid else { return nil }
        return record
    }
    private func persistOwn(_ record: ForecastSalaryChoice) {
        if let data = try? JSONEncoder().encode(record) { defaults.set(data, forKey: namespace + ".own") }
    }
    private func apply(_ record: ForecastSalaryChoice) {
        guard current != record else { return }
        // Keep displaced choices locally. No transaction or model context is changed.
        if !value.isEmpty && value != record.value {
            var history = defaults.stringArray(forKey: namespace + ".previousChoices") ?? []
            if !history.contains(value) { history.append(value) }
            defaults.set(history, forKey: namespace + ".previousChoices")
        }
        current = record
        value = record.value
        defaults.set(record.value, forKey: AppSettingsKey.forecastSalaryID)
        if let data = try? JSONEncoder().encode(record) { defaults.set(data, forKey: namespace + ".current") }
    }
}
