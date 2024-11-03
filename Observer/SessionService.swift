import Foundation

protocol SessionServiceProtocol {
    func saveSession(_ session: String)
    func getSession() -> String?
    func clearSession()
}

// SessionResponse 구조체 추가
struct SessionResponse: Codable {
    let userId: Int
    let sessionToken: String
    let newUser: Bool
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
