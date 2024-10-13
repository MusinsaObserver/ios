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

struct SessionResponse: Codable {
    let session: String?
    let user: User?
    let isNewUser: Bool?
    let errorMessage: String?
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
