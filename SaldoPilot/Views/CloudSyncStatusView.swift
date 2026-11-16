import SwiftUI

struct CloudSyncStatusView: View {
    @Environment(NetworkStatusMonitor.self) private var monitor
    @Environment(\.scenePhase) private var scenePhase
    @State private var showsDetails = false

    private var title: LocalizedStringKey {
        if monitor.isLocalFallback { return "Sync is unavailable on this device" }
        if !monitor.isCloudEnabled { return "Local test data" }
        if monitor.isOffline { return "Offline — sync is waiting" }
        if monitor.isICloudUnavailable { return "iCloud is unavailable" }
        if monitor.sync.latestFailure != nil { return "Sync needs attention" }
        if monitor.sync.isSyncing { return "Syncing with iCloud…" }
        return monitor.sync.lastSuccess == nil ? "Waiting for iCloud sync" : "iCloud sync is idle"
    }

    private var symbol: String {
        if monitor.isLocalFallback || monitor.isICloudUnavailable { return "icloud.slash" }
        if monitor.isOffline { return "wifi.slash" }
        if monitor.sync.latestFailure != nil { return "exclamationmark.icloud" }
        return monitor.sync.isSyncing ? "arrow.triangle.2.circlepath.icloud" : "icloud"
    }

    private var needsAttention: Bool {
        monitor.isLocalFallback || monitor.isOffline || monitor.isICloudUnavailable || monitor.sync.latestFailure != nil
    }

    var body: some View {
        Button { showsDetails = true } label: {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.caption.weight(.semibold))
                    if monitor.isCloudEnabled, let date = monitor.sync.lastSuccess {
                        (Text("Last successful sync activity: ") + Text(date, format: .dateTime.day().month().hour().minute()))
                            .font(.caption2)
                    }
                }
                Spacer(minLength: 0)
                if monitor.sync.isSyncing && monitor.isCloudEnabled && !monitor.isOffline {
                    ProgressView().controlSize(.mini).accessibilityLabel("Syncing with iCloud…")
                }
                Image(systemName: "chevron.right").font(.caption2)
            }
            .foregroundStyle(needsAttention ? Color.orange : Color.secondary)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.bar)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .fixedSize(horizontal: false, vertical: true)
        .sheet(isPresented: $showsDetails) { details }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { monitor.checkAccountStatus() }
        }
    }

    private var details: some View {
        NavigationStack {
            Form {
                Section("iCloud sync") {
                    Label(title, systemImage: symbol)
                    if monitor.isLocalFallback || !monitor.isCloudEnabled {
                        Text("This device uses local storage. iCloud sync is not running.")
                    } else {
                        timestamp("Last successful upload", date: monitor.sync.lastUpload)
                        timestamp("Last successful download", date: monitor.sync.lastDownload)
                        Text("These times describe this device. Other devices may receive changes later.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                if monitor.isCloudEnabled, let failure = monitor.sync.latestFailure {
                    Section("Latest sync error") {
                        Text("iCloud could not finish syncing. The app will retry automatically.")
                        Text(failure.date, format: .dateTime.day().month().year().hour().minute())
                        Text("Error code: \(failure.domain) (\(failure.code))")
                            .font(.caption).textSelection(.enabled)
                        Text("Keep the app open with an internet connection. Check iCloud sign-in and available iCloud storage in system settings.")
                    }
                }
                if monitor.isCloudEnabled {
                    Section {
                        Button("Check iCloud account") { monitor.checkAccountStatus() }
                        Text("This checks account availability. Uploads and downloads are managed automatically by iCloud.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Sync status")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showsDetails = false }
                }
            }
        }
    }

    private func timestamp(_ title: LocalizedStringKey, date: Date?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.subheadline)
            if let date {
                Text(date, format: .dateTime.day().month().year().hour().minute())
            } else {
                Text("Not recorded yet")
            }
        }
    }
}

/// Keep the status inside each navigation content area, below the tab/toolbar controls.
struct CloudSyncStatusInset: ViewModifier {
    @Environment(NetworkStatusMonitor.self) private var monitor: NetworkStatusMonitor?
    func body(content: Content) -> some View {
        content.safeAreaInset(edge: .top, spacing: 0) {
            if monitor != nil { CloudSyncStatusView() }
        }
    }
}
