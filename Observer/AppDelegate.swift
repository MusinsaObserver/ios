//
//  AppDelegate.swift
//  Observer
//
//  Created by Jiwon Kim on 9/10/24.
//

import UIKit
import GoogleSignIn

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    private let tokenService = TokenService()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        restoreGoogleSignIn()
        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    private func restoreGoogleSignIn() {
        GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
            if let error = error {
                print("Failed to restore previous sign-in: \(error.localizedDescription)")
            } else if let user = user, let idToken = user.idToken?.tokenString {
                self?.tokenService.saveToken(idToken)
            }
        }
    }
}

// MARK: - Token Service
class TokenService {
    private let tokenKey = "jwtToken"
    private let userDefaults = UserDefaults.standard
    
    func saveToken(_ token: String) {
        userDefaults.set(token, forKey: tokenKey)
    }
    
    func getToken() -> String? {
        return userDefaults.string(forKey: tokenKey)
    }
    
    func deleteToken() {
        userDefaults.removeObject(forKey: tokenKey)
    }
}
