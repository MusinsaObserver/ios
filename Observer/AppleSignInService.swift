//
//  AppleSignInService.swift
//  Observer
//
//  Created by Jiwon Kim on 9/15/24.
//

import CryptoKit
import Foundation
import AuthenticationServices

protocol AppleSignInServiceProtocol: AuthenticationService {
    func startSignInWithAppleFlow()
}

class AppleSignInService: NSObject, AppleSignInServiceProtocol, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private var currentNonce: String?
    private var signInCompletion: ((Result<String, Error>) -> Void)?
    private var backendURL: String

    init(backendURL: String) {
        self.backendURL = backendURL
    }

    func signIn(presenting: UIViewController, completion: @escaping (Result<String, Error>) -> Void) {
        signInCompletion = completion
        startSignInWithAppleFlow()
    }

    func startSignInWithAppleFlow() {
        let nonce = randomNonceString()
        currentNonce = nonce

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName]
        request.nonce = sha256(nonce)

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }

    // MARK: - ASAuthorizationControllerDelegate
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
           let idTokenData = appleIDCredential.identityToken,
           let idTokenString = String(data: idTokenData, encoding: .utf8) {
            authenticateWithBackend(idToken: idTokenString)
        } else {
            signInCompletion?(.failure(OAuth2Error.noIDToken))
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        signInCompletion?(.failure(error))
    }

    // MARK: - Authenticate with Backend
    private func authenticateWithBackend(idToken: String) {
        guard let url = URL(string: "\(backendURL)/api/auth/apple/login") else {
            signInCompletion?(.failure(OAuth2Error.invalidBackendURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = ["idToken": idToken]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            // 에러가 있는지 먼저 확인
            if let error = error {
                print("Network error: \(error.localizedDescription)")  // 네트워크 에러 출력
                self.signInCompletion?(.failure(error))
                return
            }

            // 서버 응답 상태 코드 확인
            if let httpResponse = response as? HTTPURLResponse {
                print("Status Code: \(httpResponse.statusCode)")  // 상태 코드 출력
            } else {
                print("No HTTP response received")
            }

            // 받은 데이터가 있는지 확인하고 출력
            if let data = data {
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Received response: \(jsonString)")  // 응답 데이터 출력
                } else {
                    print("Unable to decode data to string")
                }
            } else {
                print("No data received from server")
            }

            // 응답 파싱 및 에러 처리
            do {
                let session = try self.parseSessionFromResponse(data: data)
                DispatchQueue.main.async {
                    self.signInCompletion?(.success(session))
                }
            } catch {
                print("Error parsing session: \(error.localizedDescription)")  // 파싱 에러 출력
                self.signInCompletion?(.failure(error))
            }
        }.resume()
    }


    private func parseSessionFromResponse(data: Data?) throws -> String {
        guard let data = data else {
            print("No data to parse")  // 데이터가 없을 경우 로그 출력
            throw OAuth2Error.invalidServerResponse
        }

        // 데이터가 JSON 형식인지 확인 후 파싱
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                print("Parsed JSON: \(json)")  // 파싱된 JSON 출력
                if let sessionId = json["sessionId"] as? String {
                    return sessionId
                } else {
                    print("sessionId not found in JSON response")
                    throw OAuth2Error.invalidServerResponse
                }
            } else {
                print("Response is not in JSON format")
                throw OAuth2Error.invalidServerResponse
            }
        } catch {
            print("Failed to parse JSON: \(error.localizedDescription)")  // 파싱 실패 로그 출력
            throw error
        }
    }


    // MARK: - ASAuthorizationControllerPresentationContextProviding
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }!
    }

    // MARK: - Helper Functions
    private func randomNonceString(length: Int = 32) -> String {
        let charset: [Character] = Array("0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
        var nonce = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in UInt8.random(in: 0...255) }
            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    nonce.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return nonce
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}
