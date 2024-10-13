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

    let apiClient = APIClient(baseUrl: "https://cea9-141-223-234-170.ngrok-free.app")
    let favoriteService: FavoriteServiceProtocol

    init(searchQuery: String, products: [ProductResponseDto] = [], favoriteService: FavoriteServiceProtocol = FavoriteService(baseURL: URL(string: "https://cea9-141-223-234-170.ngrok-free.app")!)) {
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
        .navigationBarHidden(true)
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
