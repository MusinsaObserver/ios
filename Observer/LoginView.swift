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
    @State private var isShowingSignUpView = false
    @State private var isLoggedIn = false
    @State private var showAgreementsView = false  // 신규 사용자 약관 동의 화면 표시 상태 추가
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Constants.Colors.backgroundDarkGrey
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    Spacer().frame(height: navigationBarHeight)
                    
                    contentView
                        .navigationDestination(isPresented: $isShowingSignUpView) {
                            SignUpView()
                        }
                        .navigationDestination(isPresented: $isLoggedIn) {
                            HomeView()
                        }
                        .navigationDestination(isPresented: $showAgreementsView) {  // 약관 동의 화면으로 이동
                            AgreementView()
                        }
                        .navigationDestination(isPresented: $isHomeView) {  // 홈 화면으로 이동
                            HomeView()
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
                
                Button(action: {
                    isShowingSignUpView = true
                }) {
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
                Task {
                    do {
                        let sessionResponse = try await authViewModel.authClient.appleSignIn(idToken: idTokenString)
                        if let session = sessionResponse.session {
                            await MainActor.run {
                                authViewModel.saveSession(session)
                                authViewModel.user = sessionResponse.user
                                authViewModel.isLoggedIn = true
                            }

                            if sessionResponse.isNewUser ?? false {
                                // 신규 사용자라면 약관 동의 화면으로 이동
                                await MainActor.run {
                                    showAgreementsView = true  // 약관 동의 화면으로 이동
                                }
                            } else {
                                // 기존 사용자라면 홈 화면으로 이동
                                await MainActor.run {
                                    isHomeView = true
                                }
                            }
                        } else {
                            await MainActor.run {
                                self.loginError = sessionResponse.errorMessage ?? "인증 실패"
                            }
                        }
                    } catch {
                        await MainActor.run {
                            self.loginError = error.localizedDescription
                        }
                    }
                }
            } else {
                loginError = "ID 토큰을 받지 못했습니다."
            }
        case .failure(let error):
            loginError = "로그인 오류: \(error.localizedDescription)"
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        let mockAuthViewModel = AuthViewModel(
            authClient: MockAuthAPIClient(),
            sessionService: MockSessionService()
        )
        return LoginView()
            .environmentObject(mockAuthViewModel)
    }
}
