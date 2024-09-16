//
//  SessionService.swift
//  Observer
//
//  Created by Jiwon Kim on 9/15/24.
//

import Foundation

// MARK: - SessionService Protocol

protocol SessionServiceProtocol {
    func saveSession(_ session: String)
    func getSession() -> String?
    func clearSession()
}

// MARK: - Session Response Structure

struct SessionResponse: Codable {
    let session: String?
    let user: User?
    let isNewUser: Bool? // 신규 사용자 여부를 나타내는 필드
    let errorMessage: String?
}

// MARK: - Session Service Implementation

class SessionService: SessionServiceProtocol {
    private let userDefaults: UserDefaults
    private let sessionKey = "authSession"
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    // 세션 저장
    func saveSession(_ session: String) {
        userDefaults.set(session, forKey: sessionKey)
    }
    
    // 세션 조회
    func getSession() -> String? {
        return userDefaults.string(forKey: sessionKey)
    }
    
    // 세션 삭제
    func clearSession() {
        userDefaults.removeObject(forKey: sessionKey)
    }
}

// MARK: - Mock Implementation for Testing

#if DEBUG
class MockSessionService: SessionServiceProtocol {
    private var session: String?
    
    // 세션 저장 (모의 구현)
    func saveSession(_ session: String) {
        self.session = session
    }
    
    // 세션 조회 (모의 구현)
    func getSession() -> String? {
        return session
    }
    
    // 세션 삭제 (모의 구현)
    func clearSession() {
        session = nil
    }
}
#endif
