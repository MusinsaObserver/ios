import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @State private var isHomeView = false
    @State private var showAgreementsView = false
    @State private var loginError: String? = nil
    @EnvironmentObject var authViewModel: AuthViewModel

    private let backendURL = "https://6817-169-211-217-48.ngrok-free.app"

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
    
    private func handleAuthorization(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
               let identityToken = appleIDCredential.identityToken,
               let idToken = String(data: identityToken, encoding: .utf8) {
                
                Task {
                    await authViewModel.appleSignIn(idToken: idToken)
                    
                    if authViewModel.isNewUser {
                        showAgreementsView = true
                    } else {
                        isHomeView = true
                    }
                }
            }
        case .failure(let error):
            print("Authorization failed: \(error.localizedDescription)")
            loginError = "인증 실패: \(error.localizedDescription)"
        }
    }
}
