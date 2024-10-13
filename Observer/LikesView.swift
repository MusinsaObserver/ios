//
//  LikesView.swift
//  Observer
//
//  Created by Jiwon Kim on 9/10/24.
//

import SwiftUI

struct LikesView: View {
    @State private var isHomeView = false
    @State private var likedProducts: [ProductResponseDto] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showAlert = false
    @State private var navigateToLogin = false
    @State private var showPrivacyPolicy = false
    @State private var currentIndex = 0
    @State private var isFetchingMore = false
    
    @EnvironmentObject var authViewModel: AuthViewModel
    let apiClient: APIClientProtocol
    
    var body: some View {
        NavigationStack {
            ZStack {
                Constants.Colors.backgroundDarkGrey
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    navigationBar
                    
                    if isLoading && likedProducts.isEmpty {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(2)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if likedProducts.isEmpty {
                        emptyStateView
                    } else {
                        productList
                    }
                }
            }
            .navigationDestination(isPresented: $isHomeView) {
                HomeView()
            }
            .navigationDestination(isPresented: $navigateToLogin) {
                LoginView()
            }
            .navigationBarHidden(true)
            .onAppear {
                Task {
                    await fetchLikedProducts()
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("오류"),
                    message: Text(errorMessage ?? "알 수 없는 오류가 발생했습니다."),
                    dismissButton: .default(Text("확인"))
                )
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                privacyPolicyView
            }
        }
    }
    
    private var navigationBar: some View {
        HStack {
            Button(action: {
                isHomeView = true
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white)
                    .imageScale(.large)
            }
            .padding(.leading, Constants.Spacing.medium)
            
            Spacer()
            
            Text("찜")
                .font(.system(size: Constants.FontSize.large, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                showPrivacyPolicy = true
            }) {
                Image(systemName: "ellipsis")
                    .foregroundColor(.white)
                    .imageScale(.large)
                    .rotationEffect(.degrees(90))
            }
            .padding(.trailing, Constants.Spacing.medium)
        }
        .frame(height: Constants.Size.navigationBarHeight)
        .background(Constants.Colors.backgroundDarkGrey)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: Constants.Spacing.large) {
            Image(systemName: "heart.slash")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.gray)
            
            Text("찜한 상품이 없습니다")
                .font(.system(size: Constants.FontSize.medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var productList: some View {
        ScrollView {
            LazyVStack(spacing: Constants.Spacing.small) {
                ForEach(likedProducts, id: \.id) { product in
                    ProductCardView(product: product)
                        .onAppear {
                            if product == likedProducts.last && !isFetchingMore {
                                Task {
                                    await fetchMoreProducts()
                                }
                            }
                        }
                }
                
                if isFetchingMore {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .padding(.horizontal, Constants.Spacing.small)
        }
    }
    
    private var privacyPolicyView: some View {
        NavigationView {
            VStack {
                Text("개인정보 처리방침")
                    .font(.title)
                    .padding()
                
                Text("이 앱은 사용자의 개인정보를 수집하고 처리합니다...")
                    .padding()
                
                Spacer()
                
                Button("회원 탈퇴") {
                    Task {
                        await handleAccountDeletion()
                    }
                }
                .foregroundColor(.red)
                .padding()
            }
            .navigationBarItems(trailing: Button("닫기") {
                showPrivacyPolicy = false
            })
        }
    }
    
    private func fetchLikedProducts() async {
        isLoading = true
        do {
            likedProducts = try await apiClient.getLikedProducts(offset: 0, limit: 10)
            currentIndex = likedProducts.count
        } catch {
            errorMessage = error.localizedDescription
            showAlert = true
        }
        isLoading = false
    }
    
    private func fetchMoreProducts() async {
        guard !isFetchingMore else { return }
        
        isFetchingMore = true
        do {
            let newProducts = try await apiClient.getLikedProducts(offset: currentIndex, limit: 10)
            likedProducts.append(contentsOf: newProducts)
            currentIndex += newProducts.count
        } catch {
            errorMessage = error.localizedDescription
            showAlert = true
        }
        isFetchingMore = false
    }
    
    private func handleAccountDeletion() async {
        do {
            let success = try await apiClient.deleteAccount()
            if success {
                authViewModel.logout()
                navigateToLogin = true
            } else {
                errorMessage = "회원 탈퇴에 실패했습니다. 다시 시도해 주세요."
                showAlert = true
            }
        } catch {
            errorMessage = "회원 탈퇴 중 오류가 발생했습니다: \(error.localizedDescription)"
            showAlert = true
        }
    }
}

struct LikesView_Previews: PreviewProvider {
    static var previews: some View {
        let mockAPIClient = MockAPIClient()

        let mockAuthViewModel = AuthViewModel(authClient: MockAuthAPIClient(), sessionService: MockSessionService())
        mockAuthViewModel.isLoggedIn = true

        return LikesView(apiClient: mockAPIClient)
            .environmentObject(mockAuthViewModel)
            .previewDisplayName("Likes View Preview")
    }
}
