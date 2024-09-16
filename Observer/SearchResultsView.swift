//
//  SearchResultsView.swift
//  Observer
//
//  Created by Jiwon Kim on 9/10/24.
//

import SwiftUI

struct SearchResultsView: View {
    var searchQuery: String
    @State private var products: [ProductResponseDto] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var isHomeView = false
    @State private var isShowingLikesView = false
    @State private var isShowingLoginView = false
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    let apiClient = APIClient(baseUrl: "https://your-api-base-url.com")
    let favoriteService: FavoriteServiceProtocol

    init(searchQuery: String, favoriteService: FavoriteServiceProtocol = FavoriteService(baseURL: URL(string: "https://your-api-base-url.com")!)) {
        self.searchQuery = searchQuery
        self.favoriteService = favoriteService
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Constants.Colors.backgroundDarkGrey
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: Constants.Spacing.medium) {
                    Spacer().frame(height: navigationBarHeight)
                    
                    if isLoading {
                        ProgressView("검색 중...")
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding(.top, Constants.Spacing.medium)
                    } else if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding(.top, Constants.Spacing.medium)
                    } else {
                        Text("검색된 상품 \(products.count)개")
                            .font(.custom("Pretendard", size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, Constants.Spacing.medium)
                            .padding(.top, Constants.Spacing.small)
                        
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Constants.Spacing.medium) {
                                ForEach(products) { product in
                                    NavigationLink(destination: ProductDetailView(product: product, favoriteService: favoriteService)) {
                                        ProductCardView(product: product, favoriteService: favoriteService)
                                    }
                                }
                            }
                            .padding(.horizontal, Constants.Spacing.medium)
                        }
                    }
                    
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
                
                navigationBar
            }
            .navigationBarHidden(true)
            .onAppear {
                searchProducts()
            }
            .navigationDestination(isPresented: $isShowingLoginView) {
                LoginView()
            }
            .navigationDestination(isPresented: $isShowingLikesView) {
                LikesView(apiClient: apiClient, userId: authViewModel.user?.id ?? "")
            }
        }
    }
    
    private var navigationBarHeight: CGFloat {
        44
    }
    
    private var navigationBar: some View {
        NavigationBarView(
            title: "MUSINSA ⦁ OBSERVER",
            isHomeView: $isHomeView,
            isShowingLikesView: $isShowingLikesView,
            isShowingLoginView: $isShowingLoginView
        )
    }
    
    private func searchProducts() {
        isLoading = true
        errorMessage = nil
        
        // Replace this with your actual API call
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            // Simulate API response
            let sampleProducts = [
                ProductResponseDto(
                    id: 1,
                    brand: "브랜드1",
                    name: "오버사이즈 셔츠",
                    price: 14700,
                    discountRate: "70%",
                    originalPrice: 49000,
                    url: URL(string: "https://example.com/product1")!,
                    imageUrl: URL(string: "https://example.com/sample-product-image.jpg")!,
                    priceHistory: samplePriceHistory,
                    category: "셔츠"
                ),
                ProductResponseDto(
                    id: 2,
                    brand: "브랜드2",
                    name: "린넨 셔츠",
                    price: 31500,
                    discountRate: "50%",
                    originalPrice: 63000,
                    url: URL(string: "https://example.com/product2")!,
                    imageUrl: URL(string: "https://example.com/sample-product-image.jpg")!,
                    priceHistory: samplePriceHistory,
                    category: "셔츠"
                )
            ]
            
            DispatchQueue.main.async {
                self.products = sampleProducts
                self.isLoading = false
            }
        }
    }
}

// 프리뷰
struct SearchResultsView_Previews: PreviewProvider {
    static var previews: some View {
        SearchResultsView(searchQuery: "오버사이즈 셔츠", favoriteService: MockFavoriteService())
            .environmentObject(AuthViewModel(authClient: MockAuthAPIClient(), sessionService: MockSessionService()))
    }
}
