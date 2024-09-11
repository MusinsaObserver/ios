//
//  NavigationBarView.swift
//  Observer
//
//  Created by Jiwon Kim on 9/10/24.
//

import SwiftUI

struct NavigationBarView: View {
    var title: String
    var isHomeView: Bool = false // 현재 화면이 HomeView인지 여부를 나타내는 플래그
    
    // 상태 변수를 추가하여 NavigationLink의 활성 상태를 관리
    @State private var isShowingLogin = false
    @State private var isShowingLikes = false
    @State private var isShowingHome = false

    var body: some View {
        HStack {
            // HomeView에서만 버튼이 눌리지 않도록 제어
            if isHomeView {
                Image(systemName: "house")
                    .foregroundColor(.white)
                    .font(.system(size: 24))
            } else {
                Button(action: {
                    isShowingHome = true
                }) {
                    Image(systemName: "house")
                        .foregroundColor(.white)
                        .font(.system(size: 24))
                }
                .background(
                    NavigationLink("", destination: HomeView(), isActive: $isShowingHome)
                        .hidden()
                )
            }
            Spacer()
            Text(title)
                .foregroundColor(.white)
                .font(.system(size: 16))
                .bold()
            Spacer()
            Button(action: {
                handlePersonIconTap()
            }) {
                Image(systemName: "person")
                    .foregroundColor(.white)
                    .font(.system(size: 24))
            }
        }
        .padding(.horizontal, Constants.Spacing.medium)
        .padding(.vertical, 16)
        .padding(.top, safeAreaTop() - 75) // SafeArea를 고려하여 위치 조정
        .background(Constants.Colors.backgroundDarkGrey) // 배경색 일관성 유지
        .zIndex(1) // 네비게이션 바를 다른 요소보다 앞에 배치
        .navigationDestination(isPresented: $isShowingLogin) {
            LoginView() // 로그인 페이지로 이동
        }
        .navigationDestination(isPresented: $isShowingLikes) {
            LikesView() // 찜 목록 페이지로 이동
        }
    }
    
    // SafeArea의 top inset을 반환하는 함수
    private func safeAreaTop() -> CGFloat {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .windows
            .first { $0.isKeyWindow }?
            .safeAreaInsets.top ?? 0
    }

    // 사람 아이콘이 눌렸을 때의 행동을 처리하는 함수
    private func handlePersonIconTap() {
        if isLoggedIn() {
            isShowingLikes = true
        } else {
            isShowingLogin = true
        }
    }

    // JWT 토큰이 있는지 확인하여 로그인 상태를 반환하는 함수
    private func isLoggedIn() -> Bool {
        return UserDefaults.standard.string(forKey: "jwtToken") != nil
    }
}
