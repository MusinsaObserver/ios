//
//  OAuth2LoginButton.swift
//  Observer
//
//  Created by Jiwon Kim on 9/10/24.
//

import SwiftUI
import AuthenticationServices

struct OAuth2LoginButton: View {
    private let viewModel: OAuth2LoginViewModel
    
    init(clientID: String, backendURL: String, onSuccess: @escaping (String) -> Void, onError: @escaping (Error) -> Void) {
        self.viewModel = OAuth2LoginViewModel(clientID: clientID, backendURL: backendURL, onSuccess: onSuccess, onError: onError)
    }
    
    var body: some View {
        SignInWithAppleButton(.signIn, onRequest: viewModel.handleAuthorizationRequest, onCompletion: viewModel.handleAuthorizationCompletion)
            .frame(height: 50)
            .padding(.horizontal, Constants.Spacing.medium)
    }
}

class OAuth2LoginViewModel: ObservableObject {
    private let clientID: String
    private let backendURL: String
    private let onSuccess: (String) -> Void
    private let onError: (Error) -> Void
    private let authService: AuthenticationService
    
    init(clientID: String, backendURL: String, onSuccess: @escaping (String) -> Void, onError: @escaping (Error) -> Void) {
        self.clientID = clientID
        self.backendURL = backendURL
        self.onSuccess = onSuccess
        self.onError = onError
        self.authService = AppleSignInService(backendURL: backendURL)
    }
    
    func handleAuthorizationRequest(request: ASAuthorizationAppleIDRequest) {
        // Customize request if needed
    }
    
    func handleAuthorizationCompletion(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
               let identityToken = appleIDCredential.identityToken,
               let idTokenString = String(data: identityToken, encoding: .utf8) {
                self.authenticateWithBackend(idToken: idTokenString)
            } else {
                self.onError(OAuth2Error.noIDToken)
            }
        case .failure(let error):
            self.onError(error)
        }
    }
    
    private func authenticateWithBackend(idToken: String) {
        guard let url = URL(string: "\(backendURL)/api/auth/apple/login") else {
            onError(OAuth2Error.invalidBackendURL)
            return
        }

        let request = AuthenticationRequest(url: url, idToken: idToken)
        
        URLSession.shared.dataTask(with: request.urlRequest) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                self.onError(error)
                return
            }

            do {
                let session = try self.parseSessionFromResponse(data: data)
                DispatchQueue.main.async {
                    self.onSuccess(session)
                }
            } catch {
                self.onError(error)
            }
        }.resume()
    }
    
    private func parseSessionFromResponse(data: Data?) throws -> String {
        guard let data = data,
              let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let session = json["session"] as? String else {
            throw OAuth2Error.invalidServerResponse
        }
        return session
    }
}

protocol AuthenticationService {
    func signIn(presenting: UIViewController, completion: @escaping (Result<String, Error>) -> Void)
}

struct AuthenticationRequest {
    let urlRequest: URLRequest
    
    init(url: URL, idToken: String) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["idToken": idToken])
        self.urlRequest = request
    }
}

enum OAuth2Error: Error {
    case noPresentingViewController
    case invalidBackendURL
    case noIDToken
    case invalidServerResponse
}

struct OAuth2LoginButton_Previews: PreviewProvider {
    static var previews: some View {
        OAuth2LoginButton(
            clientID: "YOUR_APPLE_CLIENT_ID",
            backendURL: "https://your-backend-url.com",
            onSuccess: { session in
                print("Received session: \(session)")
            },
            onError: { error in
                print("Error signing in: \(error.localizedDescription)")
            }
        )
    }
}
