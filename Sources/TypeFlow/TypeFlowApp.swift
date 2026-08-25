import SwiftUI

@main
struct TypeFlowApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuContentView(model: model)
        } label: {
            Label("TypeFlow · \(model.state.title)", systemImage: model.state.symbol)
        }
        .menuBarExtraStyle(.window)
    }
}
