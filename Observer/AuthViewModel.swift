import Foundation
import Combine

private enum AuthAPIEndpoints {
    static let login = "/api/auth/login"
    static let validateSession = "/api/auth/validate"
    static let refreshSession = "/api/auth/refresh"
    static let appleSignIn = "/api/auth/apple/login"
    static let logout = "/api/auth/logout"
}

protocol AuthAPIClientProtocol {
    func login(username: String, password: String) async throws -> LoginResponse
    func validateSession(session: String) async throws -> Bool
    func refreshSession(session: String) async throws -> String
    func appleSignIn(idToken: String) async throws -> SessionResponse
    func logout() async throws -> LogoutResponse
}

class AuthAPIClient: AuthAPIClientProtocol {
    private let apiClient: APIClient
    private let baseUrl: String

    init(baseUrl: String) {
        self.baseUrl = baseUrl
        self.apiClient = APIClient(baseUrl: baseUrl)
    }

    func appleSignIn(idToken: String) async throws -> SessionResponse {
        return try await apiClient.sendRequest(
            endpoint: AuthAPIEndpoints.appleSignIn,
            method: "POST",
            body: ["idToken": idToken]
        )
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

class AuthViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var user: User?
    @Published var errorMessage: String?
    @Published var isNewUser: Bool = false
    
    let authClient: AuthAPIClientProtocol
    let sessionService: SessionServiceProtocol
    
    private let hasAgreedToTermsKey = "hasAgreedToTerms"

    init(authClient: AuthAPIClientProtocol, sessionService: SessionServiceProtocol) {
        self.authClient = authClient
        self.sessionService = sessionService
        checkLoginStatus()
    }

    func checkLoginStatus() {
        Task {
            let sessionExists = sessionService.getSession() != nil
            await MainActor.run { self.isLoggedIn = sessionExists }
        }
    }
    
    var needsAgreement: Bool {
        !UserDefaults.standard.bool(forKey: hasAgreedToTermsKey)
    }
    
    func completeAgreement() {
        UserDefaults.standard.set(true, forKey: hasAgreedToTermsKey)
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
    
    func appleSignIn(idToken: String) async {
        do {
            let response = try await authClient.appleSignIn(idToken: idToken)
            print("Before saving session") // 디버깅용
            
            // User 객체 생성
            let user = User(id: String(response.userId), username: String(response.userId))
            
            await handleSuccessfulLogin(session: response.sessionToken, user: user)
            print("After saving session: \(sessionService.getSession() != nil)") // 디버깅용
            
            await MainActor.run {
                self.isNewUser = response.newUser
                self.isLoggedIn = true
            }
        } catch {
            await handleError(error)
        }
    }

    @MainActor
    private func handleSuccessfulLogin(session: String, user: User) {
        print("Saving session: \(session)") // 디버깅용
        sessionService.saveSession(session)
        self.user = user
        self.isLoggedIn = true
        self.errorMessage = nil
    }
    
    func logout() {
        Task {
            do {
                let response = try await authClient.logout()
                await handleLogoutResponse(response)
            } catch {
                await handleError(error)
            }
        }
    }

    func refreshSession() {
        Task {
            guard let session = sessionService.getSession() else {
                logout()
                return
            }
            
            do {
                let newSession = try await authClient.refreshSession(session: session)
                sessionService.saveSession(newSession)
                self.isLoggedIn = true
            } catch {
                await handleError(error)
            }
        }
    }

    @MainActor
    private func handleLogoutResponse(_ response: LogoutResponse) {
        if response.message == "Successfully logged out" {
            sessionService.clearSession()
            self.isLoggedIn = false
            self.user = nil
        } else {
            self.errorMessage = "로그아웃 실패: 예상치 못한 응답입니다."
        }
    }
    
    @MainActor
    private func handleError(_ error: Error) {
        self.errorMessage = error.localizedDescription
        self.isLoggedIn = false
        self.user = nil
    }
}

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
