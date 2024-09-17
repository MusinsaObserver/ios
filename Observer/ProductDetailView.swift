//
//  ProductDetailView.swift
//  Observer
//
//  Created by Jiwon Kim on 9/10/24.
//

import SwiftUI

struct ProductDetailView: View {
    var product: ProductResponseDto
    @State private var isLiked = false
    @State private var showLoginAlert = false
    @State private var isShowingLogin = false
    @State private var isHomeView = false
    @State private var isShowingLikesView = false
    @State private var isShowingLoginView = false
    
    let apiClient = APIClient(baseUrl: "https://your-api-base-url.com")
    let favoriteService: FavoriteServiceProtocol

    init(product: ProductResponseDto, favoriteService: FavoriteServiceProtocol = FavoriteService(baseURL: URL(string: "https://your-api-base-url.com")!)) {
        self.product = product
        self.favoriteService = favoriteService
    }

    private var isLoggedIn: Bool {
        // Replace with your session check logic to verify if the user is logged in
        return URLSession.shared.configuration.httpCookieStorage?.cookies?.first(where: { $0.name == "session" }) != nil
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Pass the missing arguments to NavigationBarView
                NavigationBarView(
                    title: "MUSINSA ⦁ OBSERVER",
                    isHomeView: $isHomeView,
                    isShowingLikesView: $isShowingLikesView,
                    isShowingLoginView: $isShowingLoginView
                )
                ScrollView {
                    VStack(spacing: 8) {
                        productImageSection
                        productDetailsSection
                        actionButtonsSection
                        priceGraphSection
                        priceInfoSection

                        if !isLoggedIn {
                            loginReminderSection
                        }

                        recommendedProductsSection
                    }
                }
                .background(Constants.Colors.backgroundDarkGrey)
                .edgesIgnoringSafeArea(.all)
                .navigationDestination(isPresented: $isShowingLogin) {
                    LoginView() // Navigate to login page
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                do {
                    isLiked = try await favoriteService.checkFavoriteStatus(for: product.id)
                } catch {
                    print("Error checking favorite status: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Subviews

    private var productImageSection: some View {
        AsyncImage(url: product.imageUrl) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(height: 300)
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
            case .failure:
                Image(systemName: "xmark.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
            @unknown default:
                EmptyView()
            }
        }
    }

    private var productDetailsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(product.brand)
                .font(.caption)
                .foregroundColor(.gray)

            Text(product.name)
                .font(.headline)
                .foregroundColor(.white)

            HStack {
                Button(action: {
                    handleLikeAction()
                }) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundColor(isLiked ? .red : .white)
                        .font(.system(size: 24))
                }
                .alert(isPresented: $showLoginAlert) {
                    Alert(
                        title: Text("로그인 필요"),
                        message: Text("로그인 후 사용 가능한 기능입니다."),
                        primaryButton: .default(Text("로그인"), action: {
                            isShowingLogin = true
                        }),
                        secondaryButton: .cancel()
                    )
                }

                Spacer()
            }
            .padding(.vertical, 8)
        }
        .padding(.horizontal, 16)
    }

    private var actionButtonsSection: some View {
        VStack(spacing: 8) {
            Button(action: {
                UIApplication.shared.open(product.url)
            }) {
                Text("무신사 구매 링크")
                    .font(.custom("Pretendard", size: 14))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 16)
            
            Text("\(product.discountRate) \(formatPrice(product.price))원")
                .font(.title2)
                .foregroundColor(.red)
                .padding(.horizontal, 16)
                .padding(.top, 4) // Correct usage of padding
        }
    }

    private var priceGraphSection: some View {
        VStack(alignment: .leading) {
            Text("가격 그래프")
                .font(.headline)
                .foregroundColor(.white)

            PriceHistoryChartView(priceHistory: product.priceHistory)
                .frame(height: 250)
        }
        .padding(.horizontal, 16)
    }

    private var priceInfoSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("정가: \(formatPrice(24200))")
            Text("최고 할인가: \(formatPrice(21900))")
            Text("최저 할인가: \(formatPrice(12800))")
            Text("평균 가격: \(formatPrice(17350))")
        }
        .font(.body)
        .foregroundColor(.white.opacity(0.8))
        .padding(.horizontal, 16)
    }

    private var loginReminderSection: some View {
        VStack(spacing: 8) {
            Text("로그인 시 찜하기 및 가격 변동 알림받기 기능을 사용할 수 있습니다.")
                .font(.custom("Pretendard", size: 14))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)

            Button(action: {
                isShowingLogin = true
            }) {
                Text("로그인")
                    .font(.custom("Pretendard", size: 14).weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private var recommendedProductsSection: some View {
        VStack(alignment: .leading) {
            Text("추천 유사 상품")
                .font(.headline)
                .foregroundColor(.white)

            ScrollView(.horizontal) {
                HStack {
                    ForEach(recommendedProducts) { product in
                        NavigationLink(destination: ProductDetailView(product: product, favoriteService: favoriteService)) {
                            ProductCardView(product: product, favoriteService: favoriteService)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Helper Functions

    private func handleLikeAction() {
        if isLoggedIn {
            Task {
                do {
                    isLiked = try await favoriteService.toggleFavorite(for: product.id)
                } catch {
                    print("찜하기/해제 실패: \(error.localizedDescription)")
                }
            }
        } else {
            showLoginAlert = true
        }
    }

    private func formatPrice(_ price: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: NSNumber(value: price)) ?? "\(price)원"
    }
}

// Mock recommended products for preview
let recommendedProducts: [ProductResponseDto] = [
    ProductResponseDto(id: 1, brand: "후크", name: "빈티지 워싱 네이비 체크셔츠", price: 43900, discountRate: "53%", originalPrice: 90000, url: URL(string: "https://example.com/product/1")!, imageUrl: URL(string: "https://example.com/image1.jpg")!, priceHistory: samplePriceHistory, category: "셔츠"),
    ProductResponseDto(id: 2, brand: "이즈", name: "린넨 셔츠 [오버사이즈 핏]_블랙_남성용", price: 31500, discountRate: "50%", originalPrice: 63000, url: URL(string: "https://example.com/product/2")!, imageUrl: URL(string: "https://example.com/image2.jpg")!, priceHistory: samplePriceHistory, category: "셔츠")
]

// Preview setup
struct ProductDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ProductDetailView(product: ProductResponseDto(
            id: 1,
            brand: "테스트 브랜드",
            name: "테스트 상품",
            price: 15000,
            discountRate: "50%",
            originalPrice: 30000,
            url: URL(string: "https://example.com/product/1")!,
            imageUrl: URL(string: "https://example.com/image.jpg")!,
            priceHistory: samplePriceHistory,
            category: "테스트 카테고리"
        ), favoriteService: MockFavoriteService())
    }
}
