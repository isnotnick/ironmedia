import SwiftUI

struct TabSwitcherView: View {
    @ObservedObject var viewModel: BrowserViewModel
    @Environment(\.dismiss) private var dismiss

    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.tabs) { tab in
                        let isSelected = tab.id == viewModel.activeTabId

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(tab.title.isEmpty ? "New Tab" : tab.title)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)
                                    .foregroundColor(.primary)

                                Spacer()

                                Button(action: {
                                    viewModel.closeTab(id: tab.id)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }

                            Text(tab.urlString)
                                .font(.caption2)
                                .lineLimit(1)
                                .foregroundColor(.secondary)

                            Spacer()

                            HStack {
                                Image(systemName: "globe")
                                    .foregroundColor(.blue)
                                Spacer()
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding()
                        .frame(height: 120)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                        )
                        .onTapGesture {
                            viewModel.selectTab(id: tab.id)
                            dismiss()
                        }
                    }
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Tabs (\(viewModel.tabs.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        viewModel.createNewTab()
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("New Tab")
                        }
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
