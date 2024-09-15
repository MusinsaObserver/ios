//
//  AppDelegate.swift
//  Observer
//
//  Created by Jiwon Kim on 9/10/24.
//

import UIKit
import GoogleSignIn

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    private let tokenService: TokenServiceProtocol
    private let googleSignInService: GoogleSignInServiceProtocol

    // 기본 초기화 메서드
    override init() {
        self.tokenService = TokenService()
        self.googleSignInService = GoogleSignInService()
        super.init()
    }

    // 테스트를 위한 의존성 주입 초기화 메서드
    init(tokenService: TokenServiceProtocol, googleSignInService: GoogleSignInServiceProtocol) {
        self.tokenService = tokenService
        self.googleSignInService = googleSignInService
        super.init()
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        restoreGoogleSignIn()
        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        return googleSignInService.handle(url)
    }
    
    private func restoreGoogleSignIn() {
        googleSignInService.restorePreviousSignIn { [weak self] result in
            switch result {
            case .success(let idToken):
                self?.tokenService.saveToken(idToken)
            case .failure(let error):
                self?.handleSignInError(error)
            }
        }
    }

    private func handleSignInError(_ error: Error) {
        print("Failed to restore previous sign-in: \(error.localizedDescription)")
        // 여기에 추가적인 오류 처리 로직을 구현하세요.
        // 예: 사용자에게 알림 표시, 로그아웃 처리 등
    }
}
