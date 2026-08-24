import Foundation

/// Represents an individual browser tab.
struct TabModel: Identifiable, Codable, Equatable {
    let id: UUID
    var urlString: String
    var title: String
    var isLoading: Bool
    var estimatedProgress: Double
    var canGoBack: Bool
    var canGoForward: Bool
    var errorMessage: String?

    init(
        id: UUID = UUID(),
        urlString: String = "about:blank",
        title: String = "New Tab",
        isLoading: Bool = false,
        estimatedProgress: Double = 0.0,
        canGoBack: Bool = false,
        canGoForward: Bool = false,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.urlString = urlString
        self.title = title
        self.isLoading = isLoading
        self.estimatedProgress = estimatedProgress
        self.canGoBack = canGoBack
        self.canGoForward = canGoForward
        self.errorMessage = errorMessage
    }

    enum CodingKeys: String, CodingKey {
        case id
        case urlString
        case title
    }
}
