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

    let apiClient = APIClient(baseUrl: "https://your-api-base-url.com")
    let favoriteService: FavoriteServiceProtocol

    init(product: ProductResponseDto, favoriteService: FavoriteServiceProtocol = FavoriteService(baseURL: URL(string: "https://your-api-base-url.com")!)) {
        self.product = product
        self.favoriteService = favoriteService
    }

    // 세션 기반 로그인 상태 확인
    private var isLoggedIn: Bool {
        // 세션이 존재하는지 확인하는 로직 (세션 쿠키나 상태를 확인)
        return URLSession.shared.configuration.httpCookieStorage?.cookies?.first(where: { $0.name == "session" }) != nil
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                NavigationBarView(title: "MUSINSA ⦁ OBSERVER", isHomeView: $isHomeView)
                ScrollView {
                    VStack(spacing: 8) {
                        // 상품 이미지
                        AsyncImage(url: product.imageUrl) { image in
                            image
                                .resizable()
                                .scaledToFit()
                        } placeholder: {
                            ProgressView()
                                .frame(height: 300)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            // 브랜드명
                            Text(product.brand)
                                .font(.caption)
                                .foregroundColor(.gray)

                            // 상품명
                            Text(product.name)
                                .font(.headline)
                                .foregroundColor(.white)

                            // 하트 버튼
                            HStack {
                                Button(action: {
                                    if isLoggedIn {
                                        isLiked.toggle()
                                        Task {
                                            await handleLikeAction()
                                        }
                                    } else {
                                        showLoginAlert = true
                                    }
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

                        // 무신사 구매 링크
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

                        // 할인 정보
                        Text("\(product.discountRate) \(formatPrice(product.price))원")
                            .font(.title2)
                            .foregroundColor(.red)
                            .padding(.horizontal, 16)
                            .padding(.top, 4)

                        // 가격 그래프 추가
                        VStack(alignment: .leading) {
                            Text("가격 그래프")
                                .font(.headline)
                                .foregroundColor(.white)
                            PriceHistoryChartView(priceHistory: product.priceHistory)
                                .frame(height: 250) // 그래프의 높이 설정
                        }
                        .padding(.horizontal, 16)

                        // 가격 정보
                        VStack(alignment: .leading, spacing: 4) {
                            Text("정가: \(formatPrice(24200))")
                            Text("최고 할인가: \(formatPrice(21900))")
                            Text("최저 할인가: \(formatPrice(12800))")
                            Text("평균 가격: \(formatPrice(17350))")
                        }
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 16)

                        // 로그인하지 않은 경우 표시할 추가 UI
                        if !isLoggedIn {
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

                        // 추천 유사 상품
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
                }
                .background(Constants.Colors.backgroundDarkGrey)
                .edgesIgnoringSafeArea(.all)
                .navigationDestination(isPresented: $isShowingLogin) {
                    LoginView() // 로그인 페이지로 이동
                }
            }
        }
        .navigationBarHidden(true) // Navigation bar 숨기기
    }

    private func handleLikeAction() async {
        do {
            isLiked = try await favoriteService.toggleFavorite(for: product.id)
            print(isLiked ? "찜 성공" : "찜 해제 성공")
        } catch {
            print("찜하기/해제 실패: \(error.localizedDescription)")
            isLiked.toggle() // 실패 시, 원래 상태로 되돌리기
        }
    }

    private func formatPrice(_ price: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: NSNumber(value: price)) ?? "\(price)원"
    }
}

let recommendedProducts: [ProductResponseDto] = [
    ProductResponseDto(id: 1, brand: "후크", name: "빈티지 워싱 네이비 체크셔츠", price: 43900, discountRate: "53%", originalPrice: 90000, url: URL(string: "https://example.com/product/1")!, imageUrl: URL(string: "https://example.com/image1.jpg")!, priceHistory: samplePriceHistory, category: "셔츠"),
    ProductResponseDto(id: 2, brand: "이즈", name: "린넨 셔츠 [오버사이즈 핏]_블랙_남성용", price: 31500, discountRate: "50%", originalPrice: 63000, url: URL(string: "https://example.com/product/2")!, imageUrl: URL(string: "https://example.com/image2.jpg")!, priceHistory: samplePriceHistory, category: "셔츠")
]

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

// Mock implementation of FavoriteServiceProtocol for testing
class MockFavoriteService: FavoriteServiceProtocol {
    private var favorites: Set<Int> = []
    
    func toggleFavorite(for productId: Int) async throws -> Bool {
        if favorites.contains(productId) {
            favorites.remove(productId)
            return false  // The product is no longer a favorite
        } else {
            favorites.insert(productId)
            return true   // The product is now a favorite
        }
    }
    
    func getFavorites() async throws -> [Int] {
        return Array(favorites)
    }
    
    func checkFavoriteStatus(for productId: Int) async throws -> Bool {
        return favorites.contains(productId)
    }
}
