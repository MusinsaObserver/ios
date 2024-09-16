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
    static let validateSession = "/api/auth/validate"
    static let refreshSession = "/api/auth/refresh"
    static let appleSignIn = "/api/auth/apple/login" // Added for Apple Sign-In
}

// MARK: - Auth API Client Protocol
protocol AuthAPIClientProtocol {
    func login(username: String, password: String) async throws -> LoginResponse
    func validateSession(session: String) async throws -> Bool
    func refreshSession(session: String) async throws -> String
    func appleSignIn(idToken: String) async throws -> SessionResponse
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
}

// MARK: - Auth View Model
class AuthViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var user: User?
    @Published var errorMessage: String?
    
    let authClient: AuthAPIClientProtocol
    private let sessionService: SessionServiceProtocol
    
    init(authClient: AuthAPIClientProtocol, sessionService: SessionServiceProtocol) {
        self.authClient = authClient
        self.sessionService = sessionService
        checkLoginStatus()
    }
    
    func checkLoginStatus() {
        Task {
            if let session = sessionService.getSession(), !session.isEmpty {
                await validateSession(session)
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
    
    func logout() {
        sessionService.clearSession()
        isLoggedIn = false
        user = nil
    }
    
    func getSessionId() -> String? {
        return sessionService.getSession()
    }
    
    func saveSession(_ session: String) {
        sessionService.saveSession(session)
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
            } catch {
                await handleError(error)
            }
        }
    }
    
    private func validateSession(_ session: String) async {
        do {
            let isValid = try await authClient.validateSession(session: session)
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
    private func handleSuccessfulLogin(session: String, user: User?) {
        sessionService.saveSession(session)
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
    let session: String
    let user: User
}

struct RefreshSessionResponse: Codable {
    let newSession: String
}

// MARK: - Mock Implementations for Preview
#if DEBUG
class MockAuthAPIClient: AuthAPIClientProtocol {
    func login(username: String, password: String) async throws -> LoginResponse {
        return LoginResponse(session: "mock_session", user: User(id: "1", username: username, email: "\(username)@example.com"))
    }
    
    func validateSession(session: String) async throws -> Bool {
        return true
    }
    
    func refreshSession(session: String) async throws -> String {
        return "new_mock_session"
    }
    
    func appleSignIn(idToken: String) async throws -> SessionResponse {
        // Mock implementation with isNewUser added
        return SessionResponse(session: "mock_session", user: User(id: "1", username: "MockUser", email: "mock@example.com"), isNewUser: true, errorMessage: nil)
    }
}
#endif
