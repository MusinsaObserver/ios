import SwiftUI

struct AgreementView: View {
    @State private var agreeAll = false
    @State private var agreeTerms = false
    @State private var agreePrivacy = false
    @State private var agreeThirdParty = false
    
    @State private var showTermsPopup = false
    @State private var showPrivacyPopup = false
    @State private var showThirdPartyPopup = false
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var navigateToHome = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Constants.Colors.backgroundDarkGrey
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: Constants.Spacing.medium) {
                    Spacer().frame(height: 150)
                    
                    Text("서비스 이용을 위해\n필수 약관에 동의해주세요.")
                        .font(Font.custom("Pretendard", size: 16).weight(.semibold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.top, Constants.Spacing.small)
                    
                    VStack(alignment: .leading, spacing: Constants.Spacing.medium) {
                        CheckBoxView(isChecked: $agreeAll, text: "전체 동의")
                            .onChange(of: agreeAll) {
                                agreeTerms = agreeAll
                                agreePrivacy = agreeAll
                                agreeThirdParty = agreeAll
                            }

                        HStack {
                            CheckBoxView(isChecked: $agreeTerms, text: "(필수) 서비스 이용 약관 동의")
                            Button(action: {
                                showTermsPopup = true
                            }) {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.white)
                                    .font(.system(size: 14))
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
                            }
                        }
                    }
                    .padding(.horizontal, Constants.Spacing.medium)
                    
                    Spacer()
                    
                    Button(action: completeSignUp) {
                        Text("동의하고 계속하기")
                            .font(Font.custom("Pretendard", size: 16).weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(allAgreementsAccepted ? Color.white : Color.gray)
                            .foregroundColor(allAgreementsAccepted ? .black : .white)
                            .cornerRadius(8)
                    }
                    .disabled(!allAgreementsAccepted)
                    .padding(.horizontal, Constants.Spacing.medium)
                    
                    Spacer().frame(height: 20)

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
                .navigationDestination(isPresented: $navigateToHome) {
                    HomeView()
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private var allAgreementsAccepted: Bool {
        agreeTerms && agreePrivacy && agreeThirdParty
    }
    
    private func completeSignUp() {
        let sessionToken = "yourSessionToken"
        authViewModel.sessionService.saveSession(sessionToken)
        authViewModel.isLoggedIn = true
        navigateToHome = true
    }

    func termsOfServiceContent() -> String {
        return "서비스 이용 약관 내용이 여기에 표시됩니다."
    }

    func privacyPolicyContent() -> String {
        return "개인정보 수집 및 이용 동의 내용이 여기에 표시됩니다."
    }

    func thirdPartyPolicyContent() -> String {
        return "개인정보 제3자 제공 동의 내용이 여기에 표시됩니다."
    }
}
