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
    @State private var currentIndex = 0
    @State private var isFetchingMore   = false
    
    let apiClient: APIClientProtocol
    let userId: String

    init(apiClient: APIClientProtocol, userId: String) {
        self.apiClient = apiClient
        self.userId = userId
    }

    var body: some View {
        VStack(spacing: 0) {
            // Navigation Bar
            HStack {
                Button(action: {
                    // Home action
                }) {
                    Image(systemName: "house.fill")
                        .foregroundColor(.white)
                        .font(.title2)
                }
                Spacer()
                Text("MUSINSA ⦁ OBSERVER")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    // Profile action
                }) {
                    Image(systemName: "person.circle")
                        .foregroundColor(.white)
                        .font(.title2)
                }
            }
            .padding()
            .background(Constants.Colors.backgroundDarkGrey)
            
            Spacer().frame(height: 100)
            
            // Title "마이페이지" in the center
            Text("마이페이지")
                .font(.title)
                .bold()
                .foregroundColor(.white)
                .padding(.bottom, 20)
            
            // 찜 목록 Section
            HStack {
                Text("찜 목록")
                    .font(.headline)
                    .foregroundColor(.yellow)
                    .padding(.leading)
                
                Spacer()
            }
            .padding(.bottom, 50)
            
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
                ScrollView(.horizontal) {
                    HStack(spacing: 16) {
                        ForEach(Array(likedProducts.prefix(currentIndex + 10)), id: \.id) { product in
                            productCard(for: product)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 200)
            }
            
            Spacer()
            
            // Bottom Buttons
            VStack(spacing: 20) {
                Button(action: handleLogout) {
                    Text("로그아웃")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 10).stroke(Color.blue, lineWidth: 2))
                }
                
                Button(action: {
                    showAlert.toggle()
                }) {
                    Text("회원 탈퇴")
                        .font(.headline)
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 10).stroke(Color.red, lineWidth: 2))
                }
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
                .foregroundColor(.white)
                .padding(.bottom)
                .sheet(isPresented: $showPrivacyPolicy) {
                    PrivacyPolicyView(isPresented: $showPrivacyPolicy)
                }
            }
            .padding(.horizontal)
        }
        .background(Constants.Colors.backgroundDarkGrey)
        .edgesIgnoringSafeArea(.top)
        .onAppear {
            Task {
                await fetchLikedProducts()
            }
        }
    }

    private func fetchLikedProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            likedProducts = try await apiClient.getLikedProducts(userId: userId, offset: 0, limit: 10)
            currentIndex = 10
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "찜한 상품을 가져오는 데 실패했습니다: \(error.localizedDescription)"
        }
    }

    private func fetchMoreLikedProducts() async {
        guard !isFetchingMore else { return }
        isFetchingMore = true
        do {
            let moreLikedProducts = try await apiClient.getLikedProducts(userId: userId, offset: likedProducts.count, limit: 10)
            likedProducts.append(contentsOf: moreLikedProducts)
            isFetchingMore = false
        } catch {
            isFetchingMore = false
            print("Error fetching more liked products: \(error.localizedDescription)")
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
                try await apiClient.logout()
                navigateToLogin = true
            } catch {
                errorMessage = "로그아웃 중 오류가 발생했습니다: \(error.localizedDescription)"
            }
        }
    }
    
    private func productCard(for product: ProductResponseDto?) -> some View {
            Group {
                if let product = product {
                    NavigationLink(destination: ProductDetailView(product: product, favoriteService: FavoriteService(baseURL: URL(string: "https://your-api-base-url.com")!))) {
                        ProductCardView(product: product, favoriteService: FavoriteService(baseURL: URL(string: "https://your-api-base-url.com")!))
                            .frame(width: 150)
                            .onAppear {
                                if product.id == likedProducts.last?.id && !isFetchingMore {
                                    Task {
                                        await fetchMoreLikedProducts()
                                    }
                                }
                            }
                    }
                } else {
                    EmptyView()
                }
            }
        }
}

struct PrivacyPolicyView: View {
    @Binding var isPresented: Bool

    var body: some View {
        VStack {
            Text("개인정보 처리방침")
                .font(.title)
                .padding()

            ScrollView {
                Text("""
                여기에 개인정보 처리방침 내용을 넣으세요.
                1. 개인정보의 처리 목적
                2. 개인정보의 처리 및 보유 기간
                3. 개인정보의 제3자 제공에 관한 사항
                """)
                .padding()
            }

            Button("닫기") {
                isPresented = false
            }
            .padding()
        }
    }
}

// Helper extension to erase view type and return as AnyView
extension View {
    func eraseToAnyView() -> AnyView {
        return AnyView(self)
    }
}

struct LikesView_Previews: PreviewProvider {
    static var previews: some View {
        LikesView(apiClient: MockAPIClient(), userId: "previewUser")
    }
}
