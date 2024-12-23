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
    @State private var showAccountDeletionAlert = false
    
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
                    
                    Spacer()
                    
                    logoutAndPrivacyPolicyButtons
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
            .alert(isPresented: $showAccountDeletionAlert) {
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
                    ProductCardView(product: product, favoriteService: FavoriteService(baseURL: URL(string: "https://6817-169-211-217-48.ngrok-free.app")!))
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
        .onAppear {
            Task {
                await fetchMoreProductsIfNeeded()
            }
        }
    }
    
    private var logoutAndPrivacyPolicyButtons: some View {
        VStack(spacing: 20) {
            Button(action: {
                Task {
                    await handleLogout()
                }
            }) {
                Text("로그아웃")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 10).stroke(Color.blue, lineWidth: 2))
            }
            
            Button(action: {
                showAccountDeletionAlert = true
            }) {
                Text("회원 탈퇴")
                    .font(.headline)
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 10).stroke(Color.red, lineWidth: 2))
            }
            
            Button("개인정보 처리방침") {
                showPrivacyPolicy.toggle()
            }
            .font(.footnote)
            .foregroundColor(.white)
            .padding(.bottom)
        }
        .padding(.horizontal)
    }
    
    private var privacyPolicyView: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("개인정보 처리방침")
                        .font(Font.custom("Pretendard", size: 20).weight(.bold))
                        .foregroundColor(.black)
                        .padding(.top, 16)
                    
                    ScrollView {
                        Text("이 앱은 사용자의 개인정보를 수집하고 처리합니다. 수집된 개인정보는 서비스 제공과 사용 경험을 개선하기 위해 사용됩니다. 개인정보 보호법에 따라 사용자의 정보는 철저히 보호되며, 사용자는 언제든지 정보 열람, 수정, 삭제를 요청할 수 있습니다. 자세한 내용은 아래의 정책을 참고해주세요.")
                            .font(Font.custom("Pretendard", size: 14))
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                    }
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(radius: 10)
                
                Button(action: {
                    showPrivacyPolicy = false
                }) {
                    Text("닫기")
                        .font(Font.custom("Pretendard", size: 16).weight(.bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .buttonStyle(BorderlessButtonStyle())
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .frame(maxWidth: 350)
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
    
    private func fetchMoreProductsIfNeeded() async {
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
    
    private func handleLogout() async {
        do {
            try await apiClient.logout()
            authViewModel.logout()
            navigateToLogin = true
        } catch {
            errorMessage = "로그아웃 중 오류가 발생했습니다: \(error.localizedDescription)"
            showAlert = true
        }
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
