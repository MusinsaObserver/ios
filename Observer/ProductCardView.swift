import SwiftUI

struct ProductCardView: View {
    var product: ProductResponseDto
    @State private var isFavorite = false
    @State private var showLoginAlert = false
    @EnvironmentObject private var authViewModel: AuthViewModel
    let favoriteService: FavoriteServiceProtocol

    var body: some View {
        NavigationLink(destination: ProductDetailView(product: product)) {
            VStack(alignment: .leading) {
                AsyncImage(url: product.imageURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(height: 180)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(height: 180)
                            .cornerRadius(8)
                            .transition(.opacity)
                    case .failure:
                        Image(systemName: "xmark.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 180)
                    @unknown default:
                        EmptyView()
                    }
                }
                
                Text(product.productName)
                    .font(.custom("Pretendard", size: 14))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack {
                    Text("\(product.discountRate) \(formatPrice(product.price))")
                        .font(.custom("Pretendard", size: 14).weight(.bold))
                        .foregroundColor(.white)
                    Spacer()
                    favoriteButton
                }
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            Task {
                do {
                    isFavorite = try await favoriteService.checkFavoriteStatus(for: product.id)
                } catch {
                    print("Error checking favorite status: \(error.localizedDescription)")
                }
            }
        }
    }

    private var favoriteButton: some View {
        Button(action: {
            if authViewModel.isLoggedIn {
                Task {
                    do {
                        let newStatus = try await favoriteService.toggleFavorite(for: product.id)
                        isFavorite = newStatus
                    } catch {
                        print("Error toggling favorite: \(error.localizedDescription)")
                    }
                }
            } else {
                showLoginAlert = true
            }
        }) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .foregroundColor(isFavorite ? .red : .white)
        }
        .alert(isPresented: $showLoginAlert) {
            Alert(
                title: Text("로그인 필요"),
                message: Text("로그인 후 사용 가능한 기능입니다."),
                primaryButton: .default(Text("로그인"), action: {
                }),
                secondaryButton: .cancel()
            )
        }
        .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
    }

    private func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: NSNumber(value: price)) ?? "\(price)"
    }

    private func formatPrice(_ price: Int) -> String {
        formatPrice(Double(price))
    }
}
