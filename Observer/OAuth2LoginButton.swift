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
    var clientID: String
    var backendURL: String
    var buttonText: String
    var onSuccess: (String) -> Void
    var onError: (Error) -> Void
    
    var body: some View {
        GoogleSignInButton {
            signInWithGoogle()
        }
        .frame(height: 50)
        .padding(.horizontal, Constants.Spacing.medium)
    }
    
    private func signInWithGoogle() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }),
              let rootViewController = window.rootViewController else {
            print("Cannot find root view controller.")
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                onError(error)
                return
            }
            
            guard let user = result?.user,
            let idToken = user.idToken?.tokenString else {
                print("Failed to get ID token.")
                return
            }
            
            authenticateWithBackend(idToken: idToken)
        }
    }
    
private func authenticateWithBackend(idToken: String) {
        guard let url = URL(string: "\(backendURL)/api/auth/google/login") else {
            print("Invalid backend URL.")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["idToken": idToken])

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                onError(error)
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let jwt = json["jwtToken"] as? String else {
                print("Failed to parse response.")
                return
            }

            // 성공적으로 JWT 수신
            DispatchQueue.main.async {
                onSuccess(jwt)
            }
        }

        task.resume()
    }
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
