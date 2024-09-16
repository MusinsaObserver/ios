//
//  SessionService.swift
//  Observer
//
//  Created by Jiwon Kim on 9/15/24.
//

import Foundation

protocol SessionServiceProtocol {
    func saveSession(_ session: String)
    func getSession() -> String?
    func clearSession()
}

class SessionService: SessionServiceProtocol {
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

// MARK: - Mock Implementation for Testing

#if DEBUG
class MockSessionService: SessionServiceProtocol {
    private var session: String?
    
    func saveSession(_ session: String) {
        self.session = session
    }
    
    func getSession() -> String? {
        return session
    }
    
    func clearSession() {
        session = nil
    }
}
#endif
