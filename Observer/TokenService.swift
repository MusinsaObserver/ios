//
//  TokenService.swift
//  Observer
//
//  Created by Jiwon Kim on 9/11/24.
//

import Foundation

protocol TokenServiceProtocol {
    func saveToken(_ token: String)
    func getToken() -> String?
    func deleteToken()
}

private enum UserDefaultsKeys {
    static let authToken = "com.observer.userAuthToken"
}

class TokenService: TokenServiceProtocol {
    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func saveToken(_ token: String) {
        userDefaults.set(token, forKey: UserDefaultsKeys.authToken)
    }
    
    func getToken() -> String? {
        return userDefaults.string(forKey: UserDefaultsKeys.authToken)
    }
    
    func deleteToken() {
        userDefaults.removeObject(forKey: UserDefaultsKeys.authToken)
    }
}
