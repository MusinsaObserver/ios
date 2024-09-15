//
//  LoginView.swift
//  Observer
//
//  Created by Jiwon Kim on 9/10/24.
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift

struct LoginView: View {
    @State private var isHomeView = false
    
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
                    
                    // Google 로그인 버튼
                    OAuth2LoginButton(
                        clientID: "216085716340-ep8bbvpviq346n7iornnj6posmoktu9g.apps.googleusercontent.com",
                        backendURL: "https://your-backend-url.com",
                        buttonText: "Google로 계속하기",
                        onSuccess: { jwt in
                            print("Received JWT: \(jwt)")
                            saveJwtToken(jwt) // JWT 저장
                        },
                        onError: { error in
                            print("Error signing in: \(error.localizedDescription)")
                        }
                    )
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
            }
            .navigationBarHidden(true) // 네비게이션 바 숨김
        }
    }
    
    // JWT 저장 함수
    func saveJwtToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: "jwtToken")
    }
}

#Preview {
    LoginView()
}
