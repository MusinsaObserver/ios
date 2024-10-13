//
//  SignUpView.swift
//  Observer
//
//  Created by Jiwon Kim on 9/10/24.
//

import SwiftUI
import AuthenticationServices

struct SignUpView: View {
    
    @State private var agreeAll = false
    @State private var agreeTerms = false
    @State private var agreePrivacy = false
    @State private var agreeThirdParty = false
    
    @State private var showTermsPopup = false
    @State private var showPrivacyPopup = false
    @State private var showThirdPartyPopup = false
    
    @State private var isHomeView = false
    @State private var showAgreementsView = false
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    private let backendURL = "https://dc08-141-223-234-184.ngrok-free.app"
    
    var body: some View {
        NavigationStack {
            ZStack {
                Constants.Colors.backgroundDarkGrey
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    navigationBar
                    
                    Spacer()
                    
                    Text("회원가입")
                        .font(Font.custom("Pretendard", size: 24).weight(.bold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                    
                    Text("서비스 이용을 위해\n가입 및 정보 제공에 동의해주세요.")
                        .font(Font.custom("Pretendard", size: 14))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.top, Constants.Spacing.small)
                    
                    VStack(alignment: .leading, spacing: Constants.Spacing.medium) {
                        CheckBoxView(isChecked: $agreeAll, text: "전체 동의")
                            .onChange(of: agreeAll) {
                                agreeTerms = agreeAll
                                agreePrivacy = agreeAll
                                agreeThirdParty = agreeAll
                            }
                        
                        HStack {
                            CheckBoxView(isChecked: $agreeTerms, text: "(필수) 서비스 이용 약관 관련 전체 동의")
                            Button(action: {
                                showTermsPopup = true
                            }) {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.white)
                                    .font(.system(size: 14))
                                    .padding(.leading, 4)
                            }
                        }
                        
                        HStack {
                            CheckBoxView(isChecked: $agreePrivacy, text: "(필수) 개인정보 수집 및 이용 동의")
                            Button(action: {
                                showPrivacyPopup = true
                            }) {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.white)
                                    .font(.system(size: 14))
                                    .padding(.leading, 4)
                            }
                        }
                        
                        HStack {
                            CheckBoxView(isChecked: $agreeThirdParty, text: "(필수) 개인정보 제3자 제공 동의")
                            Button(action: {
                                showThirdPartyPopup = true
                            }) {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.white)
                                    .font(.system(size: 14))
                                    .padding(.leading, 4)
                            }
                        }
                    }
                    .padding(.horizontal, Constants.Spacing.medium)
                    .padding(.top, Constants.Spacing.medium)
                    
                    Spacer()
                    
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                        },
                        onCompletion: handleAuthorization
                    )
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .padding(.horizontal, Constants.Spacing.medium)
                    .disabled(!allAgreementsAccepted)
                    .opacity(allAgreementsAccepted ? 1.0 : 0.5)
                    
                    Spacer()
                        .frame(height: 20)
                }
                
                if showTermsPopup {
                    TermsPopupView(
                        title: "서비스 이용 약관",
                        content: termsOfServiceContent(),
                        isChecked: $agreeTerms,
                        showPopup: $showTermsPopup
                    )
                }
                
                if showPrivacyPopup {
                    TermsPopupView(
                        title: "개인정보 수집 및 이용 동의",
                        content: privacyPolicyContent(),
                        isChecked: $agreePrivacy,
                        showPopup: $showPrivacyPopup
                    )
                }
                
                if showThirdPartyPopup {
                    TermsPopupView(
                        title: "개인정보 제3자 제공 동의",
                        content: thirdPartyPolicyContent(),
                        isChecked: $agreeThirdParty,
                        showPopup: $showThirdPartyPopup
                    )
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showAgreementsView) {
                AgreementView()
            }
            .navigationDestination(isPresented: $isHomeView) {
                HomeView()
            }
        }
    }
    
    private var allAgreementsAccepted: Bool {
        agreeTerms && agreePrivacy && agreeThirdParty
    }
    
    private var navigationBar: some View {
        NavigationBarView(
            title: "MUSINSA ⦁ OBSERVER",
            isHomeView: $isHomeView,
            isShowingLikesView: .constant(false),
            isShowingLoginView: .constant(false)
        )
    }
    
    private func handleAuthorization(result: Result<ASAuthorization, Error>) {
        if !allAgreementsAccepted {
            print("All agreements must be accepted before signing in.")
            return
        }

        switch result {
            case .success(let authorization):
                if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                   let identityTokenData = appleIDCredential.identityToken,
                   let idTokenString = String(data: identityTokenData, encoding: .utf8) {
                    print("ID Token: \(idTokenString)")
                    
                    authenticateWithBackend(idToken: idTokenString)
                    
                } else {
                    print("Failed to get identity token.")
                }
            case .failure(let error):
                print("Apple Sign-In failed: \(error.localizedDescription)")
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
                
                DispatchQueue.main.async {
                    self.isHomeView = true
                }
            } else {
                print("No data received from server")
            }
        }.resume()
    }
    
    func termsOfServiceContent() -> String {
        return """
        제 1 장 총칙
        제 1 조 (목적)
        본 약관은 무신사 옵저버에서 제공하는 모든 서비스의 이용조건 및 절차, 이용자와 당 사이트의 권리, 의무, 책임사항과 기타 필요한 사항을 규정함을 목적으로 합니다.
        """
    }

    func privacyPolicyContent() -> String {
        return """
        제 6 조 (회원정보 사용에 대한 동의)
        회원의 개인정보는 공공기관의 개인정보보호법에 의해 보호되며 당 사이트의 개인정보처리방침이 적용됩니다.
        """
    }

    func thirdPartyPolicyContent() -> String {
        return """
        제 7 조 (회원의 정보 보안)
        가입 신청자가 당 사이트 서비스 가입 절차를 완료하는 순간부터 회원은 입력한 정보의 비밀을 유지할 책임이 있으며,
        회원의 아이디와 비밀번호를 타인에게 제공하여 발생하는 모든 결과에 대한 책임은 회원 본인에게 있습니다.
        """
    }
}

struct CheckBoxView: View {
    @Binding var isChecked: Bool
    var text: String
    
    var body: some View {
        Button(action: {
            isChecked.toggle()
        }) {
            HStack {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(.white)
                    .font(.system(size: 20))
                Text(text)
                    .font(Font.custom("Pretendard", size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.vertical, Constants.Spacing.small)
        }
    }
}

struct TermsPopupView: View {
    var title: String
    var content: String
    @Binding var isChecked: Bool
    @Binding var showPopup: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(Font.custom("Pretendard", size: 18).weight(.bold))
                .padding(.top, 16)
            
            ScrollView {
                Text(content)
                    .font(Font.custom("Pretendard", size: 14))
                    .padding(.horizontal, 16)
            }
            
            HStack {
                Button("닫기") {
                    showPopup = false
                }
                .buttonStyle(BorderlessButtonStyle())
                .padding(.bottom, 16)
                
                Spacer()
                
                Button("동의") {
                    isChecked = true
                    showPopup = false
                }
                .buttonStyle(BorderlessButtonStyle())
                .padding(.bottom, 16)
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 10)
        .padding(16)
        .frame(maxWidth: .infinity)
    }
}
