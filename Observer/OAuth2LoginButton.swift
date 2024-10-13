//
//  OAuth2LoginButton.swift
//  Observer
//
//  Created by Jiwon Kim on 9/10/24.
//

import CryptoKit
import SwiftUI
import AuthenticationServices

struct OAuth2LoginButton: View {
    private let viewModel: OAuth2LoginViewModel
    
    init(clientID: String, backendURL: String, onSuccess: @escaping (String) -> Void, onError: @escaping (Error) -> Void) {
        self.viewModel = OAuth2LoginViewModel(clientID: clientID, backendURL: backendURL, onSuccess: onSuccess, onError: onError)
    }
    
    var body: some View {
        SignInWithAppleButton(.signIn, onRequest: viewModel.handleAuthorizationRequest, onCompletion: viewModel.handleAuthorizationCompletion)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Constants.Spacing.medium)
    }
}

class OAuth2LoginViewModel: ObservableObject {
    private let clientID: String
    private let backendURL: String
    private let onSuccess: (String) -> Void
    private let onError: (Error) -> Void
    private let authService: AuthenticationService
    private var currentNonce: String?
    
    init(clientID: String, backendURL: String, onSuccess: @escaping (String) -> Void, onError: @escaping (Error) -> Void) {
        self.clientID = clientID
        self.backendURL = backendURL
        self.onSuccess = onSuccess
        self.onError = onError
        self.authService = AppleSignInService(backendURL: backendURL)
        self.currentNonce = nil
    }
    
    func handleAuthorizationRequest(request: ASAuthorizationAppleIDRequest) {
        // 생체 인증 활성화
        request.requestedScopes = [.fullName]

        // nonce가 제대로 생성되어 있지 않으면 다시 생성
        if currentNonce == nil {
            currentNonce = randomNonceString()
        }

        // nonce 해시 생성
        request.nonce = sha256(currentNonce!)
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
            // 생체 인증 실패 또는 사용자 취소 등 구체적인 오류 처리
            if let authError = error as? ASAuthorizationError {
                switch authError.code {
                    case .canceled:
                        print("사용자가 생체 인증을 취소했습니다.")
                    case .failed:
                        print("생체 인증이 실패했습니다.")
                    case .invalidResponse:
                        print("Apple에서 유효하지 않은 응답을 받았습니다.")
                    case .notHandled:
                        print("Apple에서 요청을 처리하지 않았습니다.")
                    case .unknown:
                        print("알 수 없는 오류가 발생했습니다.")
                    default:
                        print("미처리 오류: \(error.localizedDescription)")
                }
            }
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
    
    private func randomNonceString(length: Int = 32) -> String {
        let charset: [Character] = Array("0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in UInt8.random(in: 0...255) }
            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }
    
    private func sha256(_ input: String) -> String {
            let inputData = Data(input.utf8)
            let hashedData = SHA256.hash(data: inputData)
            return hashedData.map { String(format: "%02x", $0) }.joined()
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
            clientID: "Apple_id",
            backendURL: "https://cea9-141-223-234-170.ngrok-free.app",
            onSuccess: { session in
                print("Received session: \(session)")
            },
            onError: { error in
                print("Error signing in: \(error.localizedDescription)")
            }
        )
    }
}
