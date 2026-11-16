import Foundation

/// Device-local observations. A successful upload is not proof that another device downloaded it.
struct CloudSyncState {
    enum Operation: String, Codable { case setup, download, upload }
    struct Failure: Codable, Equatable {
        let date: Date
        let domain: String
        let code: Int
    }
    var active: [UUID: Operation] = [:]
    var failures: [Operation: Failure] = [:]
    var lastUpload: Date?
    var lastDownload: Date?

    var isSyncing: Bool { !active.isEmpty }
    var latestFailure: Failure? { failures.values.max { $0.date < $1.date } }
    var lastSuccess: Date? { [lastUpload, lastDownload].compactMap { $0 }.max() }

    mutating func receive(id: UUID, operation: Operation, endedAt: Date?, succeeded: Bool, failure: Failure?) {
        guard let endedAt else {
            active[id] = operation
            return
        }
        active.removeValue(forKey: id)
        if succeeded {
            // A successful import must not hide an outstanding export failure (or vice versa).
            if failures[operation].map({ $0.date <= endedAt }) ?? true {
                failures.removeValue(forKey: operation)
            }
            switch operation {
            case .upload: lastUpload = max(lastUpload ?? .distantPast, endedAt)
            case .download: lastDownload = max(lastDownload ?? .distantPast, endedAt)
            case .setup: break
            }
        } else {
            let latestSuccess = operation == .upload ? lastUpload : operation == .download ? lastDownload : nil
            if let latestSuccess, endedAt <= latestSuccess { return }
            let value = failure ?? Failure(date: endedAt, domain: "CloudKit", code: 0)
            if failures[operation].map({ $0.date <= value.date }) ?? true {
                failures[operation] = value
            }
        }
    }
}
