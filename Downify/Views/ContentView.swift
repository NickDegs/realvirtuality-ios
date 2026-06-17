import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authState: AuthState

    var body: some View {
        Group {
            if authState.isLoading {
                ProgressView()
                    .tint(Theme.accent)
            } else if authState.isAuthenticated {
                HomeView()
            } else {
                AuthView()
            }
        }
        .animation(.easeInOut, value: authState.isAuthenticated)
    }
}
