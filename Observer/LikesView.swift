//
//  LikesView.swift
//  Observer
//
//  Created by Jiwon Kim on 9/10/24.
//

import SwiftUI

struct LikesView: View {
    @State private var likedProducts: [ProductResponseDto] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showAlert = false
    @State private var navigateToLogin = false
    @State private var showPrivacyPolicy = false
    
    let apiClient: APIClientProtocol
    let userId: String

    init(apiClient: APIClientProtocol, userId: String) {
        self.apiClient = apiClient
        self.userId = userId
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Text("찜 목록")
                    .font(.title)
                    .bold()
                    .padding(.top, 50)

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
                    List(likedProducts) { product in
                        NavigationLink(destination: ProductDetailView(product: product, favoriteService: FavoriteService(baseURL: URL(string: "https://your-api-base-url.com")!))) {
                            ProductRowView(product: product)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                Task {
                                    await toggleLike(for: product)
                                }
                            } label: {
                                Label("찜 취소", systemImage: "heart.slash")
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }

                Button(action: {
                    showAlert.toggle()
                }) {
                    Text("회원 탈퇴")
                        .foregroundColor(.red)
                }
                .padding()
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("정말로 탈퇴하시겠습니까?"),
                        message: Text("모든 데이터가 삭제되며 복구할 수 없습니다."),
                        primaryButton: .destructive(Text("탈퇴"), action: {
                            Task {
                                await handleAccountDeletion()
                            }
                        }),
                        secondaryButton: .cancel(Text("취소"))
                    )
                }

                Button("개인정보 처리방침") {
                    showPrivacyPolicy.toggle()
                }
                .font(.footnote)
                .padding(.bottom)
                .sheet(isPresented: $showPrivacyPolicy) {
                    PrivacyPolicyView()
                }
            }
            .navigationBarItems(trailing: Button("로그아웃", action: handleLogout))
        }
        .navigationDestination(isPresented: $navigateToLogin) {
            LoginView()
        }
        .onAppear {
            Task {
                await fetchLikedProducts()
            }
        }
        .navigationBarHidden(true) // Navigation bar 숨기기
    }

    private func fetchLikedProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            likedProducts = try await apiClient.getLikedProducts(userId: userId)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "찜한 상품을 가져오는 데 실패했습니다: \(error.localizedDescription)"
        }
    }

    private func toggleLike(for product: ProductResponseDto) async {
        do {
            _ = try await apiClient.toggleProductLike(userId: userId, productId: product.id, like: false)
            await fetchLikedProducts()  // Refresh the list after toggling
        } catch {
            errorMessage = "찜 취소에 실패했습니다: \(error.localizedDescription)"
        }
    }

    private func handleAccountDeletion() async {
        do {
            let success = try await apiClient.deleteAccount(userId: userId)
            if success {
                navigateToLogin = true
            } else {
                errorMessage = "회원 탈퇴에 실패했습니다. 다시 시도해 주세요."
            }
        } catch {
            errorMessage = "회원 탈퇴 중 오류가 발생했습니다: \(error.localizedDescription)"
        }
    }

    private func handleLogout() {
        Task {
            do {
                // 1. 서버에 로그아웃 요청 보내기
                try await apiClient.logout()
                
                // 2. 로컬 세션 데이터 제거
                UserDefaults.standard.removeObject(forKey: "userId")
                UserDefaults.standard.removeObject(forKey: "sessionToken")
                
                // 3. KeyChain에 저장된 데이터가 있다면 제거
                // KeyChain.delete("userCredentials")  // KeyChain 헬퍼 클래스가 있다고 가정
                
                // 4. 앱 내 다른 저장 데이터 초기화 (필요한 경우)
                // AppState.shared.reset()  // 앱 상태를 관리하는 클래스가 있다고 가정
                
                // 5. 로그인 화면으로 이동
                DispatchQueue.main.async {
                    navigateToLogin = true
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = "로그아웃 중 오류가 발생했습니다: \(error.localizedDescription)"
                }
            }
        }
    }
}


struct ProductRowView: View {
    let product: ProductResponseDto

    var body: some View {
        HStack {
            AsyncImage(url: product.imageUrl) { image in
                image.resizable()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 50, height: 50)
            .cornerRadius(8)

            VStack(alignment: .leading) {
                Text(product.name)
                    .font(.headline)
                Text(product.brand)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Spacer()

            Text("\(product.price)원")
                .font(.headline)
        }
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            Text("개인정보 처리방침")
                .font(.title)
                .padding()
            
            Text("여기에 개인정보 처리방침 내용을 넣으세요.")
                .padding()
        }
    }
}

// Preview
struct LikesView_Previews: PreviewProvider {
    static var previews: some View {
        LikesView(apiClient: MockAPIClient(), userId: "previewUser")
    }
}

class MockAPIClient: APIClientProtocol {
    func searchProducts(query: String) async throws -> [ProductResponseDto] {
        return []  // Implement if needed for preview
    }
    
    func getProductDetails(productId: Int) async throws -> ProductResponseDto {
        return ProductResponseDto(id: productId, brand: "Brand", name: "Product", price: 10000, discountRate: "10%", originalPrice: 11000, url: URL(string: "https://example.com")!, imageUrl: URL(string: "https://example.com/image.jpg")!, priceHistory: [], category: "Category")
    }
    
    func getLikedProducts(userId: String) async throws -> [ProductResponseDto] {
        return [
            ProductResponseDto(id: 1, brand: "Brand A", name: "Product A", price: 10000, discountRate: "10%", originalPrice: 11000, url: URL(string: "https://example.com")!, imageUrl: URL(string: "https://example.com/imageA.jpg")!, priceHistory: [], category: "Category A"),
            ProductResponseDto(id: 2, brand: "Brand B", name: "Product B", price: 20000, discountRate: "20%", originalPrice: 25000, url: URL(string: "https://example.com")!, imageUrl: URL(string: "https://example.com/imageB.jpg")!, priceHistory: [], category: "Category B")
        ]
    }
    
    func toggleProductLike(userId: String, productId: Int, like: Bool) async throws -> String {
        return "Success"  // Simulate successful toggle
    }
    
    func deleteAccount(userId: String) async throws -> Bool {
        return true  // Simulate successful account deletion
    }
    
    func appleSignIn(idToken: String) async throws -> String {
        return "mockUserId"  // Simulate successful sign in
    }
    
    func logout() async throws {
        // Simulate successful logout
        return
    }
}
