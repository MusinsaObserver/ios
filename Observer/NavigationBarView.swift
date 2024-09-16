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
            // Ensure the ZStack takes the correct height
            .frame(height: 44 + geometry.safeAreaInsets.top, alignment: .top)
        }
        .frame(height: 44) // Set a fixed height to avoid expanding
    }

    private var leftButton: some View {
        Button(action: {
            if !isHomeView {
                presentationMode.wrappedValue.dismiss() // Go back to previous view
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
                isShowingLikesView = true // Trigger navigation to LikesView
            } else {
                isShowingLoginView = true // Trigger navigation to LoginView
            }
        }) {
            Image(systemName: "person")
                .foregroundColor(.white)
                .font(.system(size: 24))
        }
    }
}
