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

    let favoriteService: FavoriteServiceProtocol

    init(product: ProductResponseDto, favoriteService: FavoriteServiceProtocol = FavoriteService(baseURL: URL(string: "https://your-api-base-url.com")!)) {
        self.product = product
        self.favoriteService = favoriteService
    }

    private var isLoggedIn: Bool {
        // 세션 확인 로직
        return SessionManager().getSession() != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            // 네비게이션 바 추가
            NavigationBarView(
                title: "MUSINSA ⦁ OBSERVER",
                isHomeView: .constant(false),
                isShowingLikesView: .constant(false),
                isShowingLoginView: .constant(false)
            )
            .padding(.top, safeAreaTop())
            
            ScrollView {
                VStack(spacing: 8) {
                    productImageSection
                    productDetailsSection
                    actionButtonsSection
                    priceGraphSection
                    priceInfoSection
                }
            }
            .background(Constants.Colors.backgroundDarkGrey)
            .edgesIgnoringSafeArea(.all)
        }
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
            // 브랜드 이름과 상품 이름, 오른쪽에 하트 버튼
            HStack {
                VStack(alignment: .leading) {
                    Text(product.brand)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(product.name)
                        .font(.headline)
                        .foregroundColor(.white)
                }

                Spacer()

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
            }
            .padding(.horizontal, 16)
        }
    }

    private var actionButtonsSection: some View {
        HStack {
            // 무신사 구매 링크 버튼
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
            
            Spacer()
            
            // 할인율과 가격
            VStack(alignment: .trailing) {
                Text("\(product.discountRate)")
                    .font(.title3)
                    .foregroundColor(.red)
                
                Text("\(formatPrice(product.price))원")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 16)
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
            HStack {
                Text("정가:")
                Spacer()
                Text(formatPrice(product.originalPrice))
            }
            
            HStack {
                Text("최저가:")
                Spacer()
                Text(formatPrice(12800))  // 예시 데이터
            }
            
            HStack {
                Text("최고가:")
                Spacer()
                Text(formatPrice(21900))  // 예시 데이터
            }
        }
        .font(.body)
        .foregroundColor(.white.opacity(0.8))
        .padding(.horizontal, 16)
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

    // iOS 15에서 윈도우 접근 방법 수정
    private func safeAreaTop() -> CGFloat {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .windows
            .first?
            .safeAreaInsets.top ?? 0
    }
}

// 프리뷰 설정
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
            imageUrl: URL(string: "https://example.com/sample-product-image.jpg")!,
            priceHistory: samplePriceHistory,
            category: "테스트 카테고리"
        ), favoriteService: MockFavoriteService())
    }
}
