//
//  ProductCardView.swift
//  Observer
//
//  Created by Jiwon Kim on 9/10/24.
//

import SwiftUI

struct ProductCardView: View {
    let product: ProductResponseDto
    @State private var isLiked = false
    @State private var showLoginAlert = false
    @State private var isShowingLoginView = false
    @EnvironmentObject private var authViewModel: AuthViewModel
    let favoriteService: FavoriteServiceProtocol
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            productImage
            productInfo
        }
        .padding()
        .background(Constants.Colors.cardBackground)
        .cornerRadius(Constants.CornerRadius.medium)
        .alert(isPresented: $showLoginAlert) {
            Alert(
                title: Text("로그인 필요"),
                message: Text("로그인 후 사용 가능한 기능입니다."),
                primaryButton: .default(Text("로그인"), action: {
                    isShowingLoginView = true
                }),
                secondaryButton: .cancel()
            )
        }
        .sheet(isPresented: $isShowingLoginView) {
            LoginView() // Login screen is shown in a modal view
        }
        .onAppear {
            // Check if the product is already liked when the view appears
            Task {
                do {
                    isLiked = try await favoriteService.checkFavoriteStatus(for: product.id)
                } catch {
                    print("Error checking favorite status: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private var productImage: some View {
        AsyncImage(url: product.imageUrl) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(height: Constants.ImageSize.height)
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
                    .frame(height: Constants.ImageSize.height)
                    .cornerRadius(Constants.CornerRadius.small)
                    .transition(.opacity)
            case .failure:
                Image(systemName: "xmark.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(height: Constants.ImageSize.height)
            @unknown default:
                EmptyView()
            }
        }
        .accessibilityLabel("Product Image")
    }
    
    private var productInfo: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.xSmall) {
            Text(product.name)
                .font(.custom(Constants.Fonts.pretendard, size: Constants.FontSize.small))
                .foregroundColor(.white)
                .lineLimit(1)
            
            HStack {
                Text("\(product.discountRate) \(formattedPrice)")
                    .font(.custom(Constants.Fonts.pretendard, size: Constants.FontSize.small).weight(.bold))
                    .foregroundColor(.white)
                Spacer()
                favoriteButton
            }
        }
    }
    
    private var favoriteButton: some View {
        Button(action: {
            if authViewModel.isLoggedIn {
                // Toggle the like status and update the backend
                Task {
                    do {
                        let newStatus = try await favoriteService.toggleFavorite(for: product.id)
                        isLiked = newStatus
                    } catch {
                        print("Error toggling favorite: \(error.localizedDescription)")
                    }
                }
            } else {
                showLoginAlert = true // Show login alert if not logged in
            }
        }) {
            Image(systemName: isLiked ? "heart.fill" : "heart")
                .foregroundColor(isLiked ? .red : .white)
        }
        .accessibilityLabel(isLiked ? "Remove from favorites" : "Add to favorites")
    }
    
    private var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: NSNumber(value: product.price)) ?? "\(product.price)"
    }
}
