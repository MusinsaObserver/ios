//
//  SessionService.swift
//  Observer
//
//  Created by Jiwon Kim on 9/15/24.
//

import Foundation

protocol SessionServiceProtocol {
    func startSession(with userId: String)
    func getSession() -> String?
    func endSession()
}

struct SessionResponse: Codable {
    let success: Bool
    let errorMessage: String?
}

class SessionService: SessionServiceProtocol {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func startSession(with userId: String) {
        userDefaults.set(userId, forKey: "session")
    }

    func getSession() -> String? {
        return userDefaults.string(forKey: "session")
    }

    func endSession() {
        userDefaults.removeObject(forKey: "session")
    }
}
