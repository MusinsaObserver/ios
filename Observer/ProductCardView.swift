//
//  ProductCardView.swift
//  Observer
//
//  Created by Jiwon Kim on 9/10/24.
//

import SwiftUI

struct ProductCardView: View {
    let product: ProductResponseDto
    @StateObject private var viewModel: ProductCardViewModel
    @State private var showLoginAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @EnvironmentObject private var navigationState: NavigationState

    init(product: ProductResponseDto,
         tokenService: TokenServiceProtocol = TokenService(),
         favoriteService: FavoriteServiceProtocol) {
        self.product = product
        self._viewModel = StateObject(wrappedValue: ProductCardViewModel(
            product: product,
            tokenService: tokenService,
            favoriteService: favoriteService
        ))
    }
    
    var body: some View {
        NavigationLink(destination: ProductDetailView(product: product)) {
            VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                productImage
                productInfo
            }
            .padding()
            .background(Constants.Colors.cardBackground)
            .cornerRadius(Constants.CornerRadius.medium)
        }
        .alert(isPresented: $showLoginAlert) {
            loginAlert
        }
        .alert(isPresented: $showErrorAlert) {
            errorAlert
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
                Text("\(product.discountRate) \(viewModel.formattedPrice)")
                    .font(.custom(Constants.Fonts.pretendard, size: Constants.FontSize.small).weight(.bold))
                    .foregroundColor(.white)
                Spacer()
                favoriteButton
            }
        }
    }
    
    private var favoriteButton: some View {
        Button(action: toggleFavorite) {
            Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                .foregroundColor(viewModel.isFavorite ? .red : .white)
        }
        .accessibilityLabel(viewModel.isFavorite ? "Remove from favorites" : "Add to favorites")
    }
    
    private func toggleFavorite() {
        if viewModel.isLoggedIn {
            Task {
                do {
                    let isFavorite = try await viewModel.toggleFavorite()
                    print("Favorite status updated: \(isFavorite)")
                } catch {
                    await MainActor.run {
                        self.errorMessage = error.localizedDescription
                        self.showErrorAlert = true
                    }
                }
            }
        } else {
            showLoginAlert = true
        }
    }
    
    private var loginAlert: Alert {
        Alert(
            title: Text("로그인 필요"),
            message: Text("즐겨찾기 기능을 사용하려면 로그인이 필요합니다."),
            primaryButton: .default(Text("로그인")) {
                navigationState.navigateToLogin = true
            },
            secondaryButton: .cancel()
        )
    }
    
    private var errorAlert: Alert {
        Alert(
            title: Text("오류"),
            message: Text(errorMessage),
            dismissButton: .default(Text("확인"))
        )
    }
}

@MainActor
class ProductCardViewModel: ObservableObject {
    let product: ProductResponseDto
    @Published var isFavorite: Bool = false
    
    private let tokenService: TokenServiceProtocol
    private let favoriteService: FavoriteServiceProtocol
    
    init(product: ProductResponseDto,
         tokenService: TokenServiceProtocol = TokenService(),
         favoriteService: FavoriteServiceProtocol) {
        self.product = product
        self.tokenService = tokenService
        self.favoriteService = favoriteService
        Task {
            await checkFavoriteStatus()
        }
    }
    
    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: NSNumber(value: product.price)) ?? "\(product.price)"
    }
    
    var isLoggedIn: Bool {
        return tokenService.getToken() != nil
    }
    
    func toggleFavorite() async throws -> Bool {
        isFavorite.toggle()
        do {
            let serverIsFavorite = try await favoriteService.toggleFavorite(for: product.id)
            isFavorite = serverIsFavorite
            return serverIsFavorite
        } catch {
            isFavorite.toggle()
            throw error
        }
    }
    
    private func checkFavoriteStatus() async {
        do {
            let isFavorite = try await favoriteService.checkFavoriteStatus(for: product.id)
            self.isFavorite = isFavorite
        } catch {
            print("Error checking favorite status: \(error)")
        }
    }
}

class NavigationState: ObservableObject {
    @Published var navigateToLogin = false
}
