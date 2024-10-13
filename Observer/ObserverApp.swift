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
            authClient: AuthAPIClient(baseUrl: "https://cea9-141-223-234-170.ngrok-free.app"),
            sessionService: SessionService()
        )
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(authViewModel)
        }
    }
}
