import SwiftUI

@main
struct ObserverApp: App {
    
    let authViewModel = AuthViewModel(
            authClient: AuthAPIClient(baseUrl: "https://6817-169-211-217-48.ngrok-free.app"),
            sessionService: SessionService()
        )
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(authViewModel)
        }
    }
}
