import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appVM: AppViewModel

    var body: some View {
        if appVM.onboardingCompleted {
            MainTabView()
        } else {
            OnboardingView()
        }
    }
}
