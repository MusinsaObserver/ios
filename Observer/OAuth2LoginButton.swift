//
//  OAuth2LoginButton.swift
//  Observer
//
//  Created by Jiwon Kim on 9/10/24.
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift

struct OAuth2LoginButton: View {
    private let viewModel: OAuth2LoginViewModel
    
    init(clientID: String, backendURL: String, buttonText: String, onSuccess: @escaping (String) -> Void, onError: @escaping (Error) -> Void) {
        self.viewModel = OAuth2LoginViewModel(clientID: clientID, backendURL: backendURL, onSuccess: onSuccess, onError: onError)
    }
    
    var body: some View {
        GoogleSignInButton(action: viewModel.signInWithGoogle)
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
    
    init(clientID: String, backendURL: String, onSuccess: @escaping (String) -> Void, onError: @escaping (Error) -> Void, authService: AuthenticationService = GoogleAuthService()) {
        self.clientID = clientID
        self.backendURL = backendURL
        self.onSuccess = onSuccess
        self.onError = onError
        self.authService = authService
    }
    
    func signInWithGoogle() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let presentingViewController = windowScene.windows.first?.rootViewController else {
            onError(OAuth2Error.noPresentingViewController)
            return
        }
        
        authService.signIn(presenting: presentingViewController) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let idToken):
                self.authenticateWithBackend(idToken: idToken)
            case .failure(let error):
                self.onError(error)
            }
        }
    }
    
    private func authenticateWithBackend(idToken: String) {
        guard let url = URL(string: "\(backendURL)/api/auth/google/login") else {
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
                let jwt = try self.parseJWTFromResponse(data: data)
                DispatchQueue.main.async {
                    self.onSuccess(jwt)
                }
            } catch {
                self.onError(error)
            }
        }.resume()
    }
    
    private func parseJWTFromResponse(data: Data?) throws -> String {
        guard let data = data,
              let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let jwt = json["jwtToken"] as? String else {
            throw OAuth2Error.invalidServerResponse
        }
        return jwt
    }
}

protocol AuthenticationService {
    func signIn(presenting: UIViewController, completion: @escaping (Result<String, Error>) -> Void)
}

struct GoogleAuthService: AuthenticationService {
    func signIn(presenting: UIViewController, completion: @escaping (Result<String, Error>) -> Void) {
        GIDSignIn.sharedInstance.signIn(withPresenting: presenting) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                completion(.failure(OAuth2Error.noIDToken))
                return
            }
            
            completion(.success(idToken))
        }
    }
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
            clientID: "YOUR_GOOGLE_CLIENT_ID",
            backendURL: "https://your-backend-url.com",
            buttonText: "Google로 계속하기",
            onSuccess: { jwt in
                print("Received JWT: \(jwt)")
            },
            onError: { error in
                print("Error signing in: \(error.localizedDescription)")
            }
        )
    }
}
