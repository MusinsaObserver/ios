import SwiftUI

struct ProductDetailView: View {
    var product: ProductResponseDto
    @State private var isLiked = false
    @State private var showLoginAlert = false
    @State private var isShowingLogin = false
    @State private var lowestPrice: Int = 0
    @State private var highestPrice: Int = 0

    let favoriteService: FavoriteServiceProtocol
    let productService: ProductServiceProtocol
    @EnvironmentObject var authViewModel: AuthViewModel

    init(product: ProductResponseDto,
         favoriteService: FavoriteServiceProtocol = FavoriteService(baseURL: URL(string: "https://6817-169-211-217-48.ngrok-free.app")!),
         productService: ProductServiceProtocol = ProductService(baseURL: URL(string: "https://6817-169-211-217-48.ngrok-free.app")!)) {
        self.product = product
        self.favoriteService = favoriteService
        self.productService = productService
    }

    var body: some View {
        VStack(spacing: Constants.Spacing.medium) {
            navigationBar
                .padding(.top, safeAreaTop() - 80)
            
            Spacer().frame(height: 10).background(Constants.Colors.backgroundDarkGrey)

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
            .edgesIgnoringSafeArea(.bottom)
        }
        .onAppear {
            Task {
                do {
                    // JSON 응답 확인용 코드
                    let productDetailsData = try await productService.getProductDetails(productId: product.id)
                    if let jsonString = String(data: productDetailsData, encoding: .utf8) {
                        print("Product Details JSON Response: \(jsonString)")
                    }

                    // JSON 데이터를 ProductResponseWrapper로 디코딩
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601 // 필요한 경우 Date 형식 지정
                    let productResponseWrapper = try decoder.decode(ProductResponseWrapper.self, from: productDetailsData)

                    // `data` 필드에서 ProductResponseDto 가져오기
                    let productDetails = productResponseWrapper.data

                    // 디코딩 후 사용
                    lowestPrice = productDetails.lowestPrice ?? 0
                    highestPrice = productDetails.highestPrice ?? 0
                    isLiked = try await favoriteService.checkFavoriteStatus(for: product.id)
                } catch {
                    print("Error fetching product details: \(error)")
                }
            }
        }
        .navigationBarHidden(true)
    }

    private var navigationBar: some View {
        NavigationBarView(
            title: "MUSINSA ⦁ OBSERVER",
            isHomeView: .constant(false),
            isShowingLikesView: .constant(false),
            isShowingLoginView: .constant(false)
        )
    }

    private var productImageSection: some View {
        AsyncImage(url: product.imageURL) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(height: 300)
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 300)
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
            HStack {
                VStack(alignment: .leading) {
                    Text(product.brand)
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text(product.productName)
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
            Button(action: {
                UIApplication.shared.open(product.productURL)
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

            VStack(alignment: .trailing) {
                Text(product.discountRate)
                    .font(.title3)
                    .foregroundColor(.red)

                Text(formatPrice(product.currentPrice ?? product.price))
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

            PriceHistoryChartView(
                priceHistory: product.priceHistoryList,
                favoriteDate: product.favoriteDate,
                maxPrice: highestPrice,
                minPrice: lowestPrice,
                currentPrice: product.currentPrice ?? product.price
            )
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
                Text(formatPrice(lowestPrice))
            }

            HStack {
                Text("최고가:")
                Spacer()
                Text(formatPrice(highestPrice))
            }
        }
        .font(.body)
        .foregroundColor(.white.opacity(0.8))
        .padding(.horizontal, 16)
    }

    private func handleLikeAction() {
        if authViewModel.isLoggedIn {
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

    private func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: NSNumber(value: price)) ?? "\(price)원"
    }

    private func formatPrice(_ price: Int) -> String {
        formatPrice(Double(price))
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
