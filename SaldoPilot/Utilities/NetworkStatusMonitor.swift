//
//  NetworkStatusMonitor.swift
//  SaldoPilot
//

import CloudKit
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
    private(set) var isOffline = false
    private(set) var isICloudUnavailable = false

    @ObservationIgnored private let monitor = NWPathMonitor()
    @ObservationIgnored private let queue = DispatchQueue(label: "com.terjemoe.SaldoPilot.network-monitor")
    @ObservationIgnored private var isStarted = false
    @ObservationIgnored private var cloudContainer: CKContainer?
    @ObservationIgnored private var accountObserver: NSObjectProtocol?

    func start(cloudContainerIdentifier: String?, simulatesICloudUnavailable: Bool) {
        guard !isStarted else { return }
        isStarted = true
        let owner = WeakReference(self)
        monitor.pathUpdateHandler = { path in
            let isOffline = path.status != .satisfied
            Task { @MainActor in
                owner.value?.isOffline = isOffline
            }
        }
        monitor.start(queue: queue)

        guard let cloudContainerIdentifier else { return }
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
        if let accountObserver {
            NotificationCenter.default.removeObserver(accountObserver)
        }
    }
}
