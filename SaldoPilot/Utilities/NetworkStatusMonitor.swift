//
//  NetworkStatusMonitor.swift
//  SaldoPilot
//

import CloudKit
import CoreData
import Network
import Observation

private final class WeakReference<Value: AnyObject>: @unchecked Sendable {
    weak var value: Value?

    init(_ value: Value) {
        self.value = value
    }
}

@MainActor
@Observable
final class NetworkStatusMonitor: @unchecked Sendable {
    private(set) var sync = CloudSyncState()
    private(set) var isCloudEnabled = false
    private(set) var isLocalFallback = false
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var syncObserver: NSObjectProtocol?
    @ObservationIgnored private var persistenceKey: String?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let owner = WeakReference(self)
        // Subscribe before ModelContainer starts, so initial setup/import events are not missed.
        syncObserver = NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil, queue: .main
        ) { notification in
            guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                as? NSPersistentCloudKitContainer.Event else { return }
            let operation: CloudSyncState.Operation
            switch event.type {
            case .setup: operation = .setup
            case .import: operation = .download
            case .export: operation = .upload
            @unknown default: return
            }
            let id = event.identifier
            let end = event.endDate
            let succeeded = event.succeeded
            let failure = event.error.map { error in
                let error = error as NSError
                return CloudSyncState.Failure(date: end ?? .now, domain: error.domain, code: error.code)
            }
            Task { @MainActor in
                guard let monitor = owner.value else { return }
                monitor.sync.receive(id: id, operation: operation, endedAt: end, succeeded: succeeded, failure: failure)
                monitor.persistSyncHistory()
            }
        }
    }

    private(set) var isOffline = false
    private(set) var isICloudUnavailable = false

    @ObservationIgnored private let monitor = NWPathMonitor()
    @ObservationIgnored private let queue = DispatchQueue(label: "com.terjemoe.SaldoPilot.network-monitor")
    @ObservationIgnored private var isStarted = false
    @ObservationIgnored private var cloudContainer: CKContainer?
    @ObservationIgnored private var accountObserver: NSObjectProtocol?

    func start(cloudContainerIdentifier: String?, simulatesICloudUnavailable: Bool, localFallback: Bool = false) {
        guard !isStarted else { return }
        isStarted = true
        isLocalFallback = localFallback
        isCloudEnabled = cloudContainerIdentifier != nil && !localFallback
        if let cloudContainerIdentifier, !localFallback {
            persistenceKey = "SaldoPilot.syncHistory." + cloudContainerIdentifier
            restoreSyncHistory()
        }
        let owner = WeakReference(self)
        monitor.pathUpdateHandler = { path in
            let isOffline = path.status != .satisfied
            Task { @MainActor in
                owner.value?.isOffline = isOffline
            }
        }
        monitor.start(queue: queue)

        guard let cloudContainerIdentifier, !localFallback else { return }
        if simulatesICloudUnavailable {
            isICloudUnavailable = true
            return
        }

        let cloudContainer = CKContainer(identifier: cloudContainerIdentifier)
        self.cloudContainer = cloudContainer
        refreshAccountStatus()
        accountObserver = NotificationCenter.default.addObserver(
            forName: .CKAccountChanged,
            object: cloudContainer,
            queue: .main
        ) { _ in
            Task { @MainActor in
                owner.value?.refreshAccountStatus()
            }
        }
    }

    func checkAccountStatus() { refreshAccountStatus() }

    private struct History: Codable {
        let upload: Date?
        let download: Date?
        let failures: [CloudSyncState.Operation: CloudSyncState.Failure]
    }

    private func restoreSyncHistory() {
        guard let persistenceKey, let data = defaults.data(forKey: persistenceKey),
              let history = try? JSONDecoder().decode(History.self, from: data) else { return }
        sync.lastUpload = [sync.lastUpload, history.upload].compactMap { $0 }.max()
        sync.lastDownload = [sync.lastDownload, history.download].compactMap { $0 }.max()
        for (operation, failure) in history.failures where sync.failures[operation] == nil {
            // Do not restore failures that a successful current-session event already resolved.
            let success = operation == .upload ? sync.lastUpload : operation == .download ? sync.lastDownload : nil
            if success.map({ $0 < failure.date }) ?? true { sync.failures[operation] = failure }
        }
    }

    private func persistSyncHistory() {
        guard let persistenceKey,
              let data = try? JSONEncoder().encode(History(upload: sync.lastUpload, download: sync.lastDownload, failures: sync.failures)) else { return }
        defaults.set(data, forKey: persistenceKey)
    }

    private func refreshAccountStatus() {
        let owner = WeakReference(self)
        cloudContainer?.accountStatus { status, error in
            let isUnavailable = error != nil || status != .available
            Task { @MainActor in
                owner.value?.isICloudUnavailable = isUnavailable
            }
        }
    }

    deinit {
        monitor.cancel()
        if let syncObserver { NotificationCenter.default.removeObserver(syncObserver) }
        if let accountObserver {
            NotificationCenter.default.removeObserver(accountObserver)
        }
    }
}
