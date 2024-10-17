//
//  AuthViewModel.swift
//  Observer
//
//  Created by Jiwon Kim on 9/10/24.
//

import Foundation
import Combine

// MARK: - Auth API Endpoints
private enum AuthAPIEndpoints {
    static let login = "/api/auth/login"
    static let validateSession = "/api/auth/validate"
    static let refreshSession = "/api/auth/refresh"
    static let appleSignIn = "/api/auth/apple/login"
    static let logout = "/api/auth/logout"
}

// MARK: - Auth API Client Protocol
protocol AuthAPIClientProtocol {
    func login(username: String, password: String) async throws -> LoginResponse
    func validateSession(session: String) async throws -> Bool
    func refreshSession(session: String) async throws -> String
    func appleSignIn(idToken: String) async throws -> SessionResponse
    func logout() async throws -> LogoutResponse
}

// MARK: - Auth API Client Implementation
class AuthAPIClient: AuthAPIClientProtocol {
    private let apiClient: APIClient
    private let baseUrl: String

    init(baseUrl: String) {
        self.baseUrl = baseUrl
        self.apiClient = APIClient(baseUrl: baseUrl)
    }

    func appleSignIn(idToken: String) async throws -> SessionResponse {
        let endpoint = AuthAPIEndpoints.appleSignIn
        let url = URL(string: "\(baseUrl)\(endpoint)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["idToken": idToken]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }

        let sessionResponse = try JSONDecoder().decode(SessionResponse.self, from: data)
        return sessionResponse
    }

    func login(username: String, password: String) async throws -> LoginResponse {
        return try await apiClient.sendRequest(
            endpoint: AuthAPIEndpoints.login,
            method: "POST",
            body: ["username": username, "password": password]
        )
    }
    
    func validateSession(session: String) async throws -> Bool {
        return try await apiClient.sendRequest(
            endpoint: AuthAPIEndpoints.validateSession,
            method: "POST",
            body: ["session": session]
        )
    }
    
    func refreshSession(session: String) async throws -> String {
        let response: RefreshSessionResponse = try await apiClient.sendRequest(
            endpoint: AuthAPIEndpoints.refreshSession,
            method: "POST",
            body: ["session": session]
        )
        return response.newSession
    }

    func logout() async throws -> LogoutResponse {
        let endpoint = AuthAPIEndpoints.logout
        let url = URL(string: "\(baseUrl)\(endpoint)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }

        let logoutResponse = try JSONDecoder().decode(LogoutResponse.self, from: data)
        return logoutResponse
    }
}

// MARK: - Auth View Model
class AuthViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var user: User?
    @Published var errorMessage: String?
    
    let authClient: AuthAPIClientProtocol
    let sessionService: SessionServiceProtocol
    
    init(authClient: AuthAPIClientProtocol, sessionService: SessionServiceProtocol) {
        self.authClient = authClient
        self.sessionService = sessionService
        checkLoginStatus()
    }

    func getSessionId() -> String? {
        return sessionService.getSession()
    }
    
    func checkLoginStatus() {
        Task {
            if let session = sessionService.getSession(), !session.isEmpty {
                await MainActor.run {
                    self.isLoggedIn = true
                }
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
                await handleSuccessfulLogin(session: response.session, user: response.user)
            } catch {
                await handleError(error)
            }
        }
    }
    
    func appleSignIn(idToken: String) {
        Task {
            do {
                let response = try await authClient.appleSignIn(idToken: idToken)
                if let sessionToken = response.session, let user = response.user {
                    await handleSuccessfulLogin(session: sessionToken, user: user)
                } else {
                    await handleError(APIError.invalidResponse)
                }
            } catch {
                await handleError(error)
            }
        }
    }
    
    func logout() {
        Task {
            do {
                let response = try await authClient.logout()

                if response.message == "Successfully logged out" {
                    await MainActor.run {
                        sessionService.clearSession()
                        isLoggedIn = false
                        user = nil
                    }
                } else {
                    await MainActor.run {
                        errorMessage = "로그아웃 실패: 예상치 못한 응답입니다."
                    }
                }
            } catch {
                await handleError(error)
            }
        }
    }

    func refreshSession() {
        Task {
            guard let session = sessionService.getSession() else {
                await MainActor.run { self.logout() }
                return
            }
            
            do {
                let newSession = try await authClient.refreshSession(session: session)
                sessionService.saveSession(newSession)
                await MainActor.run {
                    self.isLoggedIn = true
                }
            } catch {
                await handleError(error)
            }
        }
    }
    
    @MainActor
    private func handleSuccessfulLogin(session: String, user: User) {
        sessionService.saveSession(session)
        self.user = user
        self.isLoggedIn = true
        self.errorMessage = nil
    }
    
    @MainActor
    private func handleError(_ error: Error) {
        self.errorMessage = error.localizedDescription
        self.isLoggedIn = false
        self.user = nil
    }
}

// MARK: - Supporting Types
struct User: Codable {
    let id: String
    let username: String
}

struct LoginResponse: Codable {
    let session: String
    let user: User
}

struct RefreshSessionResponse: Codable {
    let newSession: String
}

struct LogoutResponse: Codable {
    let message: String
}
