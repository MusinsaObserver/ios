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
    
    let apiClient = APIClient(baseUrl: "https://your-api-base-url.com")

    init(searchQuery: String, products: [ProductResponseDto] = []) {
        self.searchQuery = searchQuery
        _products = State(initialValue: products)
    }

    var body: some View {
        ZStack {
            Constants.Colors.backgroundDarkGrey
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: Constants.Spacing.medium) {
                NavigationBarView(title: "검색 결과")
                    .padding(.top, safeAreaTop() - 50)
                
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
                                ProductCardView(product: product)
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
            .onAppear {
                // searchProducts() 호출을 막아 Preview에서 문제가 생기지 않도록 처리
                #if !DEBUG
                searchProducts()
                #endif
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
        NavigationStack {
            let sampleProducts = [
                ProductResponseDto(
                    id: 1,
                    brand: "브랜드1",
                    productName: "오버사이즈 셔츠",
                    price: 14700,
                    discountRate: "70%",
                    originalPrice: 49000,
                    productURL: "https://example.com/product1",
                    imageURL: "https://example.com/sample-product-image.jpg",
                    priceHistoryList: samplePriceHistory,
                    category: "셔츠"
                ),
                ProductResponseDto(
                    id: 2,
                    brand: "브랜드2",
                    productName: "린넨 셔츠",
                    price: 31500,
                    discountRate: "50%",
                    originalPrice: 63000,
                    productURL: "https://example.com/product2",
                    imageURL: "https://example.com/sample-product-image.jpg",
                    priceHistoryList: samplePriceHistory,
                    category: "셔츠"
                )
            ]
            
            SearchResultsView(searchQuery: "오버사이즈 셔츠", products: sampleProducts)
        }
    }
}
