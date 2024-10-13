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
    @State private var showAgreementsView = false
    @State private var loginError: String? = nil
    @EnvironmentObject var authViewModel: AuthViewModel // authViewModel 추가
    
    private let backendURL = "https://cea9-141-223-234-170.ngrok-free.app"
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Constants.Colors.backgroundDarkGrey
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    Spacer().frame(height: navigationBarHeight)
                    
                    contentView
                        .navigationDestination(isPresented: $isHomeView) {
                            HomeView()
                        }
                        .navigationDestination(isPresented: $showAgreementsView) {
                            AgreementView()
                        }
                }
                
                navigationBar
            }
        }
        .navigationBarHidden(true)
    }
    
    private var navigationBarHeight: CGFloat {
        44
    }
    
    private var navigationBar: some View {
        NavigationBarView(
            title: "MUSINSA ⦁ OBSERVER",
            isHomeView: $isHomeView,
            isShowingLikesView: .constant(false),
            isShowingLoginView: .constant(false)
        )
    }
    
    private var contentView: some View {
        VStack {
            Spacer()
            
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
            
            if let loginError = loginError {
                Text(loginError)
                    .foregroundColor(.red)
                    .padding()
            }
            
            Spacer()
            
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
    }
    
    private func handleAuthorization(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
               let identityToken = appleIDCredential.identityToken,
               let idTokenString = String(data: identityToken, encoding: .utf8) {

                // 백엔드 인증 요청
                authenticateWithBackend(idToken: idTokenString)
            } else {
                loginError = "ID 토큰을 받지 못했습니다."
            }
        case .failure(let error):
            loginError = "로그인 오류: \(error.localizedDescription)"
        }
    }
    private func authenticateWithBackend(idToken: String) {
        guard let url = URL(string: "\(backendURL)/api/auth/apple/login") else {
            print("Invalid backend URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: String] = ["idToken": idToken]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("Response status code: \(httpResponse.statusCode)")
            }

            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("Response from server: \(responseString)")

                // 서버 응답을 JSON으로 변환하여 처리
                if let jsonData = try? JSONSerialization.jsonObject(with: data, options: []),
                   let jsonDict = jsonData as? [String: Any],
                   let sessionToken = jsonDict["sessionToken"] as? String {
                    DispatchQueue.main.async {
                        // 세션 저장 로직을 sessionService를 통해 처리
                        self.authViewModel.sessionService.saveSession(sessionToken)
                        self.isHomeView = true  // 홈 화면으로 이동
                    }
                } else {
                    print("Failed to parse JSON response")
                }
            } else {
                print("No data received from server")
            }
        }.resume()
    }
}
