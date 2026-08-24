import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = BrowserViewModel()

    var body: some View {
        BrowserView(viewModel: viewModel)
    }
}
