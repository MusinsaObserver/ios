//
//  ObserverApp.swift
//  Observer
//
//  Created by Jiwon Kim on 9/15/24.
//

import SwiftUI

@main
struct ObserverApp: App {
    
    let authViewModel = AuthViewModel(
            authClient: AuthAPIClient(baseUrl: "https://your-api-url.com"),
            sessionService: SessionService()
        )
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(authViewModel)  // Inject AuthViewModel into the environment
        }
    }
}
