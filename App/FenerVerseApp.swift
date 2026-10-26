import SwiftUI

@main
struct FenerVerseApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .tint(FVStyle.gold)
        }
    }
}
