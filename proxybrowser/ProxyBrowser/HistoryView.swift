import SwiftUI

struct HistoryView: View {
    @ObservedObject var historyManager = HistoryManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var onSelectURL: (String) -> Void

    var filteredItems: [HistoryItem] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return historyManager.historyItems
        } else {
            return historyManager.historyItems.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.urlString.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationView {
            List {
                if filteredItems.isEmpty {
                    VStack(alignment: .center, spacing: 8) {
                        Image(systemName: "clock.badge.exclamationmark")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text(searchText.isEmpty ? "No History Available" : "No Results Found")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                } else {
                    ForEach(filteredItems) { item in
                        Button(action: {
                            onSelectURL(item.urlString)
                            dismiss()
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                    .foregroundColor(.primary)

                                Text(item.urlString)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .foregroundColor(.blue)

                                Text(item.dateVisited, style: .time)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let item = filteredItems[index]
                            historyManager.removeEntry(item)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search History")
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !historyManager.historyItems.isEmpty {
                        Button("Clear") {
                            historyManager.clearAllHistory()
                        }
                        .foregroundColor(.red)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
