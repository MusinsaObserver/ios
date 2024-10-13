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
    @Binding var isShowingLikesView: Bool
    @Binding var isShowingLoginView: Bool

    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        GeometryReader { geometry in
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
                .padding(.top, geometry.safeAreaInsets.top)
                .frame(height: 44 + geometry.safeAreaInsets.top)
                .background(Constants.Colors.backgroundDarkGrey)
            }
            .frame(height: 44 + geometry.safeAreaInsets.top, alignment: .top)
        }
        .frame(height: 44)
    }

    private var leftButton: some View {
        Button(action: {
            if !isHomeView {
                presentationMode.wrappedValue.dismiss()
            }
        }) {
            Image(systemName: "chevron.left")
                .foregroundColor(.white)
                .font(.system(size: 24))
        }
        .disabled(isHomeView)
        .opacity(isHomeView ? 0.5 : 1)
    }

    private var rightButton: some View {
        Button(action: {
            if authViewModel.isLoggedIn {
                isShowingLikesView = true
            } else {
                isShowingLoginView = true
            }
        }) {
            Image(systemName: "person")
                .foregroundColor(.white)
                .font(.system(size: 24))
        }
    }
}
