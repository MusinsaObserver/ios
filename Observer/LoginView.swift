//
//  LoginView.swift
//  Observer
//
//  Created by Jiwon Kim on 9/10/24.
//

import SwiftUI

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
                    
                    // Apple 로그인 버튼 (Google 로그인을 대체)
                    Button(action: {
                        performAppleSignIn()
                    }) {
                        Text("Apple로 계속하기")
                            .font(Font.custom("Pretendard", size: 16).weight(.bold))
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.black)
                            .cornerRadius(8)
                    }
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
    
    func performAppleSignIn() {
        // Simulate getting the ID token from Apple Sign-In
        let idToken = "example_id_token"

        Task {
            do {
                let sessionResponse = try await AuthAPIClient.shared.appleSignIn(idToken: idToken)

                if sessionResponse.success {
                    print("로그인 성공, 세션 시작됨")
                    isHomeView = true
                } else {
                    loginError = "로그인 실패: \(sessionResponse.errorMessage ?? "알 수 없는 오류")"
                }
            } catch {
                loginError = "로그인 중 오류 발생: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    LoginView()
}
