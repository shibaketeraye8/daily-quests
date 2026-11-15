import SwiftUI

@main
struct DailyQuestsApp: App {
    @StateObject private var game = GameState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(game)
                .preferredColorScheme(.dark)
                .tint(Theme.gold)
        }
    }
}
