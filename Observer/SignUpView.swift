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
    
    var body: some View {
        NavigationStack {
            ZStack {
                Constants.Colors.backgroundDarkGrey
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    NavigationBarView(title: "MUSINSA ⦁ OBSERVER", isHomeView: $isHomeView)
                    
                    Spacer()
                    
                    // 회원가입 제목
                    Text("회원가입")
                        .font(Font.custom("Pretendard", size: 24).weight(.bold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                    
                    // 설명 텍스트
                    Text("서비스 이용을 위해\n가입 및 정보 제공에 동의해주세요.")
                        .font(Font.custom("Pretendard", size: 14))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.top, Constants.Spacing.small)
                    
                    // 동의 항목들
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
                    
                    Spacer() // 홈 인디케이터 위에 위치하도록 여유 공간 추가
                        .frame(height: 20)
                }
                
                // 약관 팝업
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
    
    // 약관 내용들
    func termsOfServiceContent() -> String {
        return """
        제 1 장 총칙
        제 1 조 (목적)
        본 약관은 무신사 옵저버에서 제공하는 모든 서비스의 이용조건 및 절차, 이용자와 당 사이트의 권리, 의무, 책임사항과 기타 필요한 사항을 규정함을 목적으로 합니다.

        제 2 조 (약관의 효력과 변경)
        ① 당 사이트는 이용자가 본 약관 내용에 동의하는 것을 조건으로 이용자에게 서비스를 제공하며, 당 사이트의 서비스 제공 행위 및 이용자의 서비스 사용 행위에는 본 약관을 우선적으로 적용하겠습니다.
        ② 당 사이트는 본 약관을 사전 고지 없이 변경할 수 있으며, 변경된 약관은 당 사이트 내에 공지함으로써 이용자가 직접 확인하도록 할 것입니다. 이용자가 변경된 약관에 동의하지 아니하는 경우 본인의 회원등록을 취소(회원탈퇴)할 수 있으며, 계속 사용할 경우에는 약관 변경에 대한 암묵적 동의로 간주됩니다. 변경된 약관은 공지와 동시에 그 효력을 발휘합니다.
        
        (후략...)
        """
    }
    
    func privacyPolicyContent() -> String {
        return """
        제 6 조 (회원정보 사용에 대한 동의)
        ① 회원의 개인정보는 공공기관의 개인정보보호법에 의해 보호되며 당 사이트의 개인정보처리방침이 적용됩니다.
        ② 당 사이트의 회원 정보는 다음과 같이 수집, 사용, 관리, 보호됩니다.
        1. 개인정보의 수집 : 당 사이트는 회원 가입시 회원이 제공하는 정보를 수집합니다.
        2. 개인정보의 사용 : 당 사이트는 서비스 제공과 관련해서 수집된 회원정보를 본인의 승낙 없이 제3자에게 누설, 배포하지 않습니다.
        
        (후략...)
        """
    }
    
    func thirdPartyPolicyContent() -> String {
        return """
        제 7 조 (회원의 정보 보안)
        ① 가입 신청자가 당 사이트 서비스 가입 절차를 완료하는 순간부터 회원은 입력한 정보의 비밀을 유지할 책임이 있으며, 회원의 아이디와 비밀번호를 타인에게 제공하여 발생하는 모든 결과에 대한 책임은 회원 본인에게 있습니다.
        ② 아이디와 비밀번호에 관한 모든 관리의 책임은 회원에게 있으며, 회원의 아이디나 비밀번호가 부정하게 사용되었다는 사실을 발견한 경우에는 즉시 당 사이트에 신고하여야 합니다.
        
        (후략...)
        """
    }
}

// 체크박스 커스텀 뷰 (팝업 없이 사용하는 경우)
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

// 약관 팝업 뷰
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

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
