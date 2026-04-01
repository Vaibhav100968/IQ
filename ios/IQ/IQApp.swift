import SwiftUI

@main
struct IQApp: App {
    @StateObject private var appVM = AppViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appVM)
        }
    }
}
