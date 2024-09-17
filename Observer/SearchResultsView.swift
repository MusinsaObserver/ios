//
//  SearchResultsView.swift
//  Observer
//
//  Created by Jiwon Kim on 9/10/24.
//

import SwiftUI

struct SearchResultsView: View {
    var searchQuery: String
    @State private var products: [ProductResponseDto]
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var isHomeView = false
    @State private var isShowingLikesView = false
    @State private var isShowingLoginView = false
    @EnvironmentObject private var authViewModel: AuthViewModel

    let apiClient = APIClient(baseUrl: "https://your-api-base-url.com")
    let favoriteService: FavoriteServiceProtocol

    init(searchQuery: String, products: [ProductResponseDto] = [], favoriteService: FavoriteServiceProtocol = FavoriteService(baseURL: URL(string: "https://your-api-base-url.com")!)) {
        self.searchQuery = searchQuery
        _products = State(initialValue: products)
        self.favoriteService = favoriteService
    }

    var body: some View {
        ZStack {
            Constants.Colors.backgroundDarkGrey
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: Constants.Spacing.medium) {
                NavigationBarView(
                    title: "MUSINSA ⦁ OBSERVER",
                    isHomeView: $isHomeView,
                    isShowingLikesView: $isShowingLikesView,
                    isShowingLoginView: $isShowingLoginView
                )
                .padding(.top, safeAreaTop() - 50)
                
                if isLoading {
                    ProgressView("검색 중...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding(.top, Constants.Spacing.medium)
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.top, Constants.Spacing.medium)
                } else if products.isEmpty {
                    Text("검색 결과가 없습니다.")
                        .font(.custom("Pretendard", size: 14))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, Constants.Spacing.medium)
                        .padding(.top, Constants.Spacing.small)
                } else {
                    productGrid
                }
                
                footerText
            }
            .onAppear {
                fetchSearchResults()
            }
        }
    }
    
    private var productGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Constants.Spacing.medium) {
                ForEach(products) { product in
                    ProductCardView(product: product, favoriteService: favoriteService)
                        .environmentObject(authViewModel)
                }
            }
            .padding(.horizontal, Constants.Spacing.medium)
        }
    }

    private var footerText: some View {
        Text("""
            무신사스카우터에서 제공하는 제품 가격 정보는
            주기적으로 업데이트 되고 있습니다.
            업데이트 후 무신사에서 제품 가격이 변경될 수 있으므로,
            무신사스카우터에서 제공하는 제품 가격과 다르게 조회될 수 있습니다.
            """)
            .font(.custom("Pretendard", size: 12))
            .foregroundColor(.white.opacity(0.5))
            .multilineTextAlignment(.center)
            .padding(.horizontal, Constants.Spacing.medium)
            .padding(.bottom, Constants.Spacing.medium)
    }
    
    // 프리뷰에서는 샘플 데이터를 로드하고, 실제 앱에서는 API 호출
    private func fetchSearchResults() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            self.products = sampleProducts
            self.isLoading = false
            return
        }
        #endif

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let fetchedProducts = try await apiClient.searchProducts(query: searchQuery)
                products = fetchedProducts
                isLoading = false
            } catch {
                errorMessage = "검색 결과를 불러오는데 실패했습니다."
                isLoading = false
            }
        }
    }
    
    private func safeAreaTop() -> CGFloat {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .windows
            .first { $0.isKeyWindow }?
            .safeAreaInsets.top ?? 0
    }
}

// 프리뷰
struct SearchResultsView_Previews: PreviewProvider {
    static var previews: some View {
        let mockAuthViewModel = AuthViewModel(authClient: MockAuthAPIClient(), sessionService: MockSessionService())
        mockAuthViewModel.isLoggedIn = false

        return NavigationStack {
            SearchResultsView(searchQuery: "셔츠", products: sampleProducts, favoriteService: MockFavoriteService())
                .environmentObject(mockAuthViewModel)
        }
    }
}

// MockFavoriteService 구현
class MockFavoriteService: FavoriteServiceProtocol {
    private var favoriteStatus: [Int: Bool] = [:]
    
    // 좋아요 상태를 확인하는 메서드 (비동기)
    func checkFavoriteStatus(for productId: Int) async throws -> Bool {
        // 주어진 productId에 해당하는 좋아요 상태를 반환, 없으면 기본값 false
        return favoriteStatus[productId] ?? false
    }
    
    // 좋아요 상태를 토글하는 메서드 (비동기)
    func toggleFavorite(for productId: Int) async throws -> Bool {
        // 현재 좋아요 상태를 가져와서 토글
        let currentStatus = favoriteStatus[productId] ?? false
        let newStatus = !currentStatus
        favoriteStatus[productId] = newStatus
        return newStatus
    }
    
    // 좋아요된 모든 제품의 ID 목록을 반환 (비동기)
    func getFavorites() async throws -> [Int] {
        // favoriteStatus 딕셔너리에서 좋아요 상태가 true인 제품의 ID를 반환
        return favoriteStatus.filter { $0.value == true }.map { $0.key }
    }
}

let sampleProducts: [ProductResponseDto] = [
    ProductResponseDto(id: 1, brand: "브랜드1", name: "오버사이즈 셔츠", price: 14700, discountRate: "70%", originalPrice: 49000, url: URL(string: "https://example.com/product1")!, imageUrl: URL(string: "https://example.com/sample-product-image1.jpg")!, priceHistory: samplePriceHistory, category: "셔츠"),
    ProductResponseDto(id: 2, brand: "브랜드2", name: "린넨 셔츠", price: 31500, discountRate: "50%", originalPrice: 63000, url: URL(string: "https://example.com/product2")!, imageUrl: URL(string: "https://example.com/sample-product-image2.jpg")!, priceHistory: samplePriceHistory, category: "셔츠"),
    ProductResponseDto(id: 3, brand: "브랜드3", name: "스트라이프 셔츠", price: 28900, discountRate: "30%", originalPrice: 41000, url: URL(string: "https://example.com/product3")!, imageUrl: URL(string: "https://example.com/sample-product-image3.jpg")!, priceHistory: samplePriceHistory, category: "셔츠"),
    ProductResponseDto(id: 4, brand: "브랜드4", name: "체크 셔츠", price: 19900, discountRate: "40%", originalPrice: 33000, url: URL(string: "https://example.com/product4")!, imageUrl: URL(string: "https://example.com/sample-product-image4.jpg")!, priceHistory: samplePriceHistory, category: "셔츠"),
    ProductResponseDto(id: 5, brand: "브랜드5", name: "에센셜 셔츠", price: 27500, discountRate: "25%", originalPrice: 37000, url: URL(string: "https://example.com/product5")!, imageUrl: URL(string: "https://example.com/sample-product-image5.jpg")!, priceHistory: samplePriceHistory, category: "셔츠"),
    ProductResponseDto(id: 6, brand: "브랜드6", name: "베이직 셔츠", price: 39900, discountRate: "15%", originalPrice: 47000, url: URL(string: "https://example.com/product6")!, imageUrl: URL(string: "https://example.com/sample-product-image6.jpg")!, priceHistory: samplePriceHistory, category: "셔츠"),
    ProductResponseDto(id: 7, brand: "브랜드7", name: "패턴 셔츠", price: 18900, discountRate: "50%", originalPrice: 38000, url: URL(string: "https://example.com/product7")!, imageUrl: URL(string: "https://example.com/sample-product-image7.jpg")!, priceHistory: samplePriceHistory, category: "셔츠"),
    ProductResponseDto(id: 8, brand: "브랜드8", name: "울 셔츠", price: 57000, discountRate: "10%", originalPrice: 63000, url: URL(string: "https://example.com/product8")!, imageUrl: URL(string: "https://example.com/sample-product-image8.jpg")!, priceHistory: samplePriceHistory, category: "셔츠")
]
