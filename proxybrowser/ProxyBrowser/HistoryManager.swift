import Foundation
import Combine

struct HistoryItem: Identifiable, Codable, Equatable {
    let id: UUID
    let urlString: String
    let title: String
    let dateVisited: Date

    init(id: UUID = UUID(), urlString: String, title: String, dateVisited: Date = Date()) {
        self.id = id
        self.urlString = urlString
        self.title = title
        self.dateVisited = dateVisited
    }
}

/// Manages browsing history storage, searching, and clearing.
final class HistoryManager: ObservableObject {
    static let shared = HistoryManager()

    @Published private(set) var historyItems: [HistoryItem] = []

    private let storageKey = "proxybrowser_history_items"

    private init() {
        loadHistory()
    }

    func addEntry(urlString: String, title: String) {
        guard !urlString.isEmpty, urlString != "about:blank" else { return }

        let itemTitle = title.isEmpty ? urlString : title
        let newItem = HistoryItem(urlString: urlString, title: itemTitle)

        // Avoid exact duplicate at the top
        if let first = historyItems.first, first.urlString == urlString {
            return
        }

        historyItems.insert(newItem, at: 0)
        saveHistory()
    }

    func removeEntry(_ item: HistoryItem) {
        historyItems.removeAll { $0.id == item.id }
        saveHistory()
    }

    func clearAllHistory() {
        historyItems.removeAll()
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(historyItems) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let items = try? JSONDecoder().decode([HistoryItem].self, from: data) else {
            return
        }
        self.historyItems = items
    }
}
