//
//  AuthViewModel.swift
//  Observer
//
//  Created by Jiwon Kim on 9/12/24.
//

import Foundation
import Combine

// MARK: - Auth API Endpoints
private enum AuthAPIEndpoints {
    static let login = "/api/auth/login"
    static let validateToken = "/api/auth/validate"
    static let refreshToken = "/api/auth/refresh"
}

// MARK: - Auth API Client Protocol
protocol AuthAPIClientProtocol {
    func login(username: String, password: String) async throws -> LoginResponse
    func validateToken(token: String) async throws -> Bool
    func refreshToken(token: String) async throws -> String
}

// MARK: - Auth API Client Implementation
class AuthAPIClient: AuthAPIClientProtocol {
    private let apiClient: APIClient
    
    init(baseUrl: String) {
        self.apiClient = APIClient(baseUrl: baseUrl)
    }
    
    func login(username: String, password: String) async throws -> LoginResponse {
        return try await apiClient.sendRequest(
            endpoint: AuthAPIEndpoints.login,
            method: "POST",
            body: ["username": username, "password": password]
        )
    }
    
    func validateToken(token: String) async throws -> Bool {
        return try await apiClient.sendRequest(
            endpoint: AuthAPIEndpoints.validateToken,
            method: "POST",
            body: ["token": token]
        )
    }
    
    func refreshToken(token: String) async throws -> String {
        let response: RefreshTokenResponse = try await apiClient.sendRequest(
            endpoint: AuthAPIEndpoints.refreshToken,
            method: "POST",
            body: ["token": token]
        )
        return response.newToken
    }
}

// MARK: - Auth View Model
class AuthViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var user: User?
    @Published var errorMessage: String?
    
    private let authClient: AuthAPIClientProtocol
    private let tokenManager: TokenManagerProtocol
    
    init(authClient: AuthAPIClientProtocol, tokenManager: TokenManagerProtocol) {
        self.authClient = authClient
        self.tokenManager = tokenManager
        checkLoginStatus()
    }
    
    func checkLoginStatus() {
        Task {
            if let token = tokenManager.getToken(), !token.isEmpty {
                await validateToken(token)
            } else {
                await MainActor.run {
                    self.isLoggedIn = false
                }
            }
        }
    }
    
    func login(username: String, password: String) {
        Task {
            do {
                let response = try await authClient.login(username: username, password: password)
                await handleSuccessfulLogin(token: response.token, user: response.user)
            } catch {
                await handleError(error)
            }
        }
    }
    
    func logout() {
        tokenManager.clearToken()
        isLoggedIn = false
        user = nil
    }
    
    func refreshToken() {
        Task {
            guard let token = tokenManager.getToken() else {
                await MainActor.run { self.logout() }
                return
            }
            
            do {
                let newToken = try await authClient.refreshToken(token: token)
                tokenManager.saveToken(newToken)
            } catch {
                await handleError(error)
            }
        }
    }
    
    private func validateToken(_ token: String) async {
        do {
            let isValid = try await authClient.validateToken(token: token)
            await MainActor.run {
                self.isLoggedIn = isValid
                if !isValid {
                    self.logout()
                }
            }
        } catch {
            await handleError(error)
        }
    }
    
    @MainActor
    private func handleSuccessfulLogin(token: String, user: User) {
        tokenManager.saveToken(token)
        self.user = user
        isLoggedIn = true
        errorMessage = nil
    }
    
    @MainActor
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        isLoggedIn = false
        user = nil
    }
}

// MARK: - Supporting Types
struct User: Codable {
    let id: String
    let username: String
    let email: String
}

struct LoginResponse: Codable {
    let token: String
    let user: User
}

struct RefreshTokenResponse: Codable {
    let newToken: String
}

protocol TokenManagerProtocol {
    func saveToken(_ token: String)
    func getToken() -> String?
    func clearToken()
}

// MARK: - Token Manager Implementation
class TokenManager: TokenManagerProtocol {
    private let userDefaults: UserDefaults
    private let tokenKey = "authToken"
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func saveToken(_ token: String) {
        userDefaults.set(token, forKey: tokenKey)
    }
    
    func getToken() -> String? {
        return userDefaults.string(forKey: tokenKey)
    }
    
    func clearToken() {
        userDefaults.removeObject(forKey: tokenKey)
    }
}

// MARK: - Mock Implementations for Preview
#if DEBUG
class MockAuthAPIClient: AuthAPIClientProtocol {
    func login(username: String, password: String) async throws -> LoginResponse {
        return LoginResponse(token: "mock_token", user: User(id: "1", username: username, email: "\(username)@example.com"))
    }
    
    func validateToken(token: String) async throws -> Bool {
        return true
    }
    
    func refreshToken(token: String) async throws -> String {
        return "new_mock_token"
    }
}

class MockTokenManager: TokenManagerProtocol {
    private var token: String?
    
    func saveToken(_ token: String) {
        self.token = token
    }
    
    func getToken() -> String? {
        return token
    }
    
    func clearToken() {
        token = nil
    }
}
#endif
