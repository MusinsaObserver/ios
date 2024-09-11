//
//  ProductCardView.swift
//  Observer
//
//  Created by Jiwon Kim on 9/10/24.
//

import SwiftUI

struct ProductCardView: View {
    var product: ProductResponseDto
    @State private var isFavorite = false
    @State private var showLoginAlert = false

    var isLoggedIn: Bool {
        return UserDefaults.standard.string(forKey: "jwtToken") != nil
    }
    
    var body: some View {
        NavigationLink(destination: ProductDetailView(product: product)) {
            VStack(alignment: .leading) {
                AsyncImage(url: URL(string: product.imageURL)) { phase in
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
                            .transition(.opacity) // Fade-in animation
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
                    Button(action: {
                        if isLoggedIn {
                            isFavorite.toggle()
                            // Here, you could optimistically update the UI
                        } else {
                            showLoginAlert.toggle()
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
                                // Navigate to login view
                            }),
                            secondaryButton: .cancel()
                        )
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private func formatPrice(_ price: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: NSNumber(value: price)) ?? "\(price)"
    }
}
