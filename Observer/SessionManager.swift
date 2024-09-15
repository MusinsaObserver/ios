//
//  SessionManager.swift
//  Observer
//
//  Created by Jiwon Kim on 9/15/24.
//

import Foundation

struct RefreshSessionResponse: Codable {
    let newSession: String
}

protocol SessionManagerProtocol {
    func saveSession(_ session: String)
    func getSession() -> String?
    func clearSession()
}

// MARK: - Session Manager Implementation
class SessionManager: SessionManagerProtocol {
    private let userDefaults: UserDefaults
    private let sessionKey = "authSession"
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func saveSession(_ session: String) {
        userDefaults.set(session, forKey: sessionKey)
    }
    
    func getSession() -> String? {
        return userDefaults.string(forKey: sessionKey)
    }
    
    func clearSession() {
        userDefaults.removeObject(forKey: sessionKey)
    }
}
