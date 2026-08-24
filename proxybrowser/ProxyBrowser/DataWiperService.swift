import Foundation
import WebKit

/// Service responsible for wiping web data, cookies, caches, local storage, and history.
final class DataWiperService {
    static let shared = DataWiperService()
    private init() {}

    /// Clears all WebKit browsing data (cookies, caches, storage, indexedDB, etc.) and history.
    func wipeAllBrowsingData(completion: @escaping () -> Void) {
        // Clear history
        HistoryManager.shared.clearAllHistory()

        // Clear WebKit Website Data Store
        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        let dateFrom = Date(timeIntervalSince1970: 0)

        WKWebsiteDataStore.default().removeData(ofTypes: dataTypes, modifiedSince: dateFrom) {
            DispatchQueue.main.async {
                completion()
            }
        }
    }
}
