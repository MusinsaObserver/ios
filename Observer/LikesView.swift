//
//  LikesView.swift
//  Observer
//
//  Created by Jiwon Kim on 9/10/24.
//

import SwiftUI

struct LikesView: View {
    @State var likedProducts: [ProductResponseDto] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showAlert = false
    @State private var navigateToLogin = false
    @State private var navigateToSignUp = false
    @State private var showPrivacyPolicy = false
    
    let apiClient = APIClient(baseUrl: "https://your-api-base-url.com")
    let favoriteService: FavoriteServiceProtocol

    init(favoriteService: FavoriteServiceProtocol = FavoriteService(baseURL: URL(string: "https://your-api-base-url.com")!)) {
        self.favoriteService = favoriteService
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                // "마이페이지" 글씨
                Text("마이페이지")
                    .font(.title)
                    .bold()
                    .foregroundColor(.white)
                    .padding(.top, 50) // 위치를 조정

                // "하트 이모지 + 찜목록" 노란 글씨
                HStack {
                    Text("💛")
                        .font(.largeTitle)
                    Text("찜 목록")
                        .font(.title3)
                        .bold()
                        .foregroundColor(Color.yellow)
                }
            }
            .padding(.bottom, 20) // 추가적인 아래 여백

            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // 찜한 상품 목록을 가로로 스크롤 가능하게 표시
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(likedProducts) { product in
                            NavigationLink(destination: ProductDetailView(product: product)) {
                                ProductCardView(product: product, favoriteService: favoriteService)
                                    .frame(width: 200) // 카드뷰의 너비를 지정
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .background(Color.black.opacity(0.85)) // 배경색을 어둡게
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Spacer()

            // 로그아웃 및 회원 탈퇴 버튼
            HStack {
                Button(action: {
                    handleLogout()
                }) {
                    Text("로그아웃")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.8))
                        .cornerRadius(10)
                }

                Button(action: {
                    showAlert.toggle()
                }) {
                    Text("회원 탈퇴")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(10)
                }
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("정말로 탈퇴하시겠습니까?"),
                        message: Text("사용자 데이터가 즉시 삭제되며 복구할 수 없습니다."),
                        primaryButton: .destructive(Text("예"), action: {
                            Task {
                                await handleAccountDeletion()
                            }
                        }),
                        secondaryButton: .cancel(Text("아니오"))
                    )
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            // 개인정보 처리방침 버튼
            Button(action: {
                showPrivacyPolicy.toggle()
            }) {
                Text("개인정보 처리방침")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.top, 8)
            }
            .alert(isPresented: $showPrivacyPolicy) {
                Alert(
                    title: Text("개인정보 처리방침"),
                    message: Text("여기에 개인정보 처리방침 내용을 적어주세요.\n\n개인정보 처리방침은 고객의 데이터를 안전하게 관리하기 위한 조치를 포함하며, 모든 관련 법규를 준수합니다."),
                    dismissButton: .default(Text("확인"))
                )
            }

            .navigationDestination(isPresented: $navigateToLogin) {
                    LoginView()
                }
            .navigationDestination(isPresented: $navigateToSignUp) {
                SignUpView()
            }
        }
        .background(Color.black.opacity(0.85)) // 배경색을 어둡게
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            #if DEBUG
            if likedProducts.isEmpty {
                likedProducts = sampleProducts
            }
            #else
            fetchLikedProducts()
            #endif
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await fetchLikedProducts()
        }
    }

    private func handleLogout() {
        // 로그아웃 로직: JWT 토큰 삭제
        UserDefaults.standard.removeObject(forKey: "jwtToken")
        // 로그인 화면으로 이동
        navigateToLogin = true
    }
    
    private func fetchLikedProducts() async {
        isLoading = true
        errorMessage = nil

        guard let userId = getUserId() else {
            isLoading = false
            errorMessage = "사용자 정보를 가져올 수 없습니다."
            return
        }

        do {
            likedProducts = try await apiClient.getLikedProducts(userId: userId)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "찜한 상품을 가져오는 데 실패했습니다: \(error.localizedDescription)"
        }
    }

    private func handleAccountDeletion() async {
        guard let userId = getUserId() else {
            errorMessage = "사용자 정보를 가져올 수 없습니다."
            return
        }

        do {
            let success = try await apiClient.deleteAccount(userId: userId)
            if success {
                UserDefaults.standard.removeObject(forKey: "jwtToken")
                navigateToSignUp = true
            } else {
                errorMessage = "회원 탈퇴에 실패했습니다. 다시 시도해 주세요."
            }
        } catch {
            errorMessage = "회원 탈퇴 중 오류가 발생했습니다: \(error.localizedDescription)"
        }
    }
    
    private func getUserId() -> String? {
        guard let jwtToken = UserDefaults.standard.string(forKey: "jwtToken") else {
            return nil
        }
        return parseJWTToken(jwtToken)
    }

    private func parseJWTToken(_ token: String) -> String? {
        let segments = token.split(separator: ".")
        guard segments.count == 3, let payloadData = base64UrlDecode(String(segments[1])) else {
            return nil
        }
        if let json = try? JSONSerialization.jsonObject(with: payloadData, options: []),
           let payload = json as? [String: Any],
           let userId = payload["user_id"] as? String {
            return userId
        }
        return nil
    }

    private func base64UrlDecode(_ value: String) -> Data? {
        var base64 = value.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        let length = base64.lengthOfBytes(using: .utf8)
        let paddedLength = ((length + 3) / 4) * 4
        base64 = base64.padding(toLength: paddedLength, withPad: "=", startingAt: 0)
        return Data(base64Encoded: base64)
    }
}

// 예제 프리뷰 데이터
let sampleProducts: [ProductResponseDto] = [
    ProductResponseDto(id: 1, brand: "브랜드A", name: "상품A", price: 14900, discountRate: "70%", originalPrice: 49600, url: URL(string: "https://example.com")!, imageUrl: URL(string: "https://via.placeholder.com/200")!, priceHistory: [], category: "카테고리A"),
    ProductResponseDto(id: 2, brand: "브랜드B", name: "상품B", price: 19900, discountRate: "60%", originalPrice: 49800, url: URL(string: "https://example.com")!, imageUrl: URL(string: "https://via.placeholder.com/200")!, priceHistory: [], category: "카테고리B"),
    ProductResponseDto(id: 3, brand: "브랜드C", name: "상품C", price: 24900, discountRate: "50%", originalPrice: 49800, url: URL(string: "https://example.com")!, imageUrl: URL(string: "https://via.placeholder.com/200")!, priceHistory: [], category: "카테고리C")
]

// 미리보기
struct LikesView_Previews: PreviewProvider {
    static var previews: some View {
        LikesView(favoriteService: MockFavoriteService())
    }
}

// Mock 서비스 (프리뷰용)
class MockFavoriteService: FavoriteServiceProtocol {
    func toggleFavorite(for productId: Int) async throws -> Bool { true }
    func getFavorites() async throws -> [Int] { [1, 2, 3] }
    func checkFavoriteStatus(for productId: Int) async throws -> Bool { true }
}
