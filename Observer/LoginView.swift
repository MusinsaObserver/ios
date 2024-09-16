//
//  LoginView.swift
//  Observer
//
//  Created by Jiwon Kim on 9/10/24.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @State private var isHomeView = false
    @State private var loginError: String? = nil

    // Create an instance of AuthAPIClient
    private let authAPIClient = AuthAPIClient(baseUrl: "https://your-backend-url.com")

    var body: some View {
        NavigationView {
            ZStack {
                Constants.Colors.backgroundDarkGrey
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    // 네비게이션 바
                    NavigationBarView(title: "MUSINSA ⦁ OBSERVER", isHomeView: $isHomeView)
                    
                    Spacer()
                    
                    // 로그인 텍스트 및 설명
                    VStack(spacing: Constants.Spacing.small) {
                        Text("로그인")
                            .font(Font.custom("Pretendard", size: 24).weight(.bold))
                            .foregroundColor(.white)
                        
                        Text("로그인 시 관심 상품 모아보기 및\n가격 변동 알림 수신이 가능합니다.")
                            .font(Font.custom("Pretendard", size: 14))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.bottom, Constants.Spacing.medium)
                    
                    // Apple Sign-In 버튼
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            // Customize request if needed
                        },
                        onCompletion: handleAuthorization
                    )
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .padding(.horizontal, Constants.Spacing.medium)
                    
                    Spacer()
                    
                    // 회원가입 링크
                    HStack {
                        Text("계정이 없으신가요?")
                            .font(Font.custom("Pretendard", size: 12).weight(.semibold))
                            .foregroundColor(.white.opacity(0.4))
                        
                        NavigationLink(destination: SignUpView()) {
                            Text("회원가입")
                                .font(Font.custom("Pretendard", size: 14).weight(.semibold))
                                .underline()
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.bottom, Constants.Spacing.medium)
                }
                
                // 로그인 실패 시 오류 메시지 표시
                if let loginError = loginError {
                    Text(loginError)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationBarHidden(true) // 네비게이션 바 숨김
        }
    }
    
    // Handle Apple Sign-In result
    private func handleAuthorization(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
               let identityToken = appleIDCredential.identityToken,
               let idTokenString = String(data: identityToken, encoding: .utf8) {
                // Perform backend authentication with idTokenString
                authenticateWithBackend(idToken: idTokenString)
            } else {
                // Handle error
                print("No ID token received")
            }
        case .failure(let error):
            print("Error signing in: \(error.localizedDescription)")
        }
    }
    
    private func authenticateWithBackend(idToken: String) {
        // Add your backend authentication logic here
        print("Received ID Token: \(idToken)")
        // Example: Use SessionService to start a session
    }
}

#Preview {
    LoginView()
}
