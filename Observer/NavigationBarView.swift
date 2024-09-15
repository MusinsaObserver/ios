//
//  NavigationBarView.swift
//  Observer
//
//  Created by Jiwon Kim on 9/10/24.
//

import SwiftUI

struct NavigationBarView: View {
    let title: String
    @Binding var isHomeView: Bool
    var rightAction: (() -> Void)?
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var navigationManager: NavigationManager
    
    var body: some View {
        ZStack {
            HStack {
                leftButton
                Spacer()
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                rightButton
            }
            .padding(.horizontal, Constants.Spacing.medium)
        }
        .frame(height: 44)
        .background(Constants.Colors.backgroundDarkGrey)
        .padding(.top, getSafeAreaTop())
    }
    
    private var leftButton: some View {
        Button(action: {
            if !isHomeView {
                navigationManager.navigateToHome()
            }
        }) {
            Image(systemName: "house")
                .foregroundColor(.white)
                .font(.system(size: 24))
        }
        .disabled(isHomeView)
        .opacity(isHomeView ? 0.5 : 1)
    }
    
    private var rightButton: some View {
        Button(action: {
            rightAction?()
        }) {
            Image(systemName: "person")
                .foregroundColor(.white)
                .font(.system(size: 24))
        }
        .disabled(rightAction == nil)
    }
    
    private func getSafeAreaTop() -> CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first
        else {
            return 0
        }
        return window.safeAreaInsets.top
    }
}

class NavigationManager: ObservableObject {
    @Published var currentView: AnyView?
    
    func navigateToHome() {
        currentView = AnyView(HomeView())
    }
}
