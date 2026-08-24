import Foundation
import Combine

/// Main ViewModel managing browser tabs, navigation, persistent tabs, and current tab state.
final class BrowserViewModel: ObservableObject {
    @Published var tabs: [TabModel] = []
    @Published var activeTabId: UUID?
    @Published var isShowingTabSwitcher: Bool = false
    @Published var isShowingHistory: Bool = false
    @Published var isShowingSettings: Bool = false

    private let tabStorageKey = "proxybrowser_saved_tabs"
    private var cancellables = Set<AnyCancellable>()

    var activeTab: TabModel? {
        get {
            guard let id = activeTabId else { return nil }
            return tabs.first(where: { $0.id == id })
        }
        set {
            if let newValue = newValue, let index = tabs.firstIndex(where: { $0.id == newValue.id }) {
                tabs[index] = newValue
            }
        }
    }

    init() {
        restoreOrInitializeTabs()
    }

    func restoreOrInitializeTabs() {
        let settings = AppSettings.shared
        if settings.restoreOpenTabs,
           let data = UserDefaults.standard.data(forKey: tabStorageKey),
           let savedTabs = try? JSONDecoder().decode([TabModel].self, from: data),
           !savedTabs.isEmpty {
            self.tabs = savedTabs
            self.activeTabId = savedTabs.first?.id
        } else {
            createNewTab()
        }
    }

    func createNewTab(withURL customURL: String? = nil) {
        let settings = AppSettings.shared
        let initialURL: String

        if let custom = customURL {
            initialURL = custom
        } else {
            switch settings.newTabBehavior {
            case .blank:
                initialURL = "about:blank"
            case .customURL:
                initialURL = settings.customHomepageURL.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        let newTab = TabModel(urlString: initialURL)
        tabs.append(newTab)
        activeTabId = newTab.id
        saveTabs()
    }

    func closeTab(id: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        tabs.remove(at: index)

        if tabs.isEmpty {
            createNewTab()
        } else if activeTabId == id {
            let nextIndex = max(0, index - 1)
            activeTabId = tabs[nextIndex].id
        }
        saveTabs()
    }

    func selectTab(id: UUID) {
        if tabs.contains(where: { $0.id == id }) {
            activeTabId = id
        }
    }

    func updateActiveTab(urlString: String? = nil, title: String? = nil, isLoading: Bool? = nil, progress: Double? = nil, canGoBack: Bool? = nil, canGoForward: Bool? = nil, errorMessage: String? = nil) {
        guard let activeId = activeTabId, let index = tabs.firstIndex(where: { $0.id == activeId }) else { return }

        if let urlString = urlString { tabs[index].urlString = urlString }
        if let title = title { tabs[index].title = title }
        if let isLoading = isLoading { tabs[index].isLoading = isLoading }
        if let progress = progress { tabs[index].estimatedProgress = progress }
        if let canGoBack = canGoBack { tabs[index].canGoBack = canGoBack }
        if let canGoForward = canGoForward { tabs[index].canGoForward = canGoForward }
        tabs[index].errorMessage = errorMessage

        saveTabs()
    }

    func saveTabs() {
        guard AppSettings.shared.restoreOpenTabs else {
            UserDefaults.standard.removeObject(forKey: tabStorageKey)
            return
        }
        if let encoded = try? JSONEncoder().encode(tabs) {
            UserDefaults.standard.set(encoded, forKey: tabStorageKey)
        }
    }
}
