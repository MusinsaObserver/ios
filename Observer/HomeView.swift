//
//  HomeView.swift
//  Observer
//
//  Created by Jiwon Kim on 9/10/24.
//

import SwiftUI

struct HomeView: View {
    @State private var searchQuery = ""
    @State private var isShowingSearchResults = false
    @State private var isHomeView = true

    var body: some View {
        NavigationStack {
            ZStack {
                Constants.Colors.backgroundDarkGrey
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: Constants.Spacing.medium) {
                    navigationBar
                    searchBar
                    Spacer()
                    descriptionText
                    Spacer()
                    disclaimerText
                }
                .navigationDestination(isPresented: $isShowingSearchResults) {
                    SearchResultsView(searchQuery: searchQuery)
                }
            }
        }
        .navigationBarHidden(true) // Navigation bar 숨기기
    }
    
    private var navigationBar: some View {
        NavigationBarView(title: "MUSINSA ⦁ OBSERVER", isHomeView: $isHomeView)
    }
    
    private var searchBar: some View {
        SearchBarView(searchQuery: $searchQuery) {
            isShowingSearchResults = true
            performApiRequest()
        }
        .padding(.horizontal, Constants.Spacing.medium)
        .padding(.bottom, Constants.Spacing.large)
    }
    
    private var descriptionText: some View {
        VStack(alignment: .center, spacing: Constants.Spacing.small) {
            Text("로그인 시 찜하기 및 가격 변동 알림 받기가 가능합니다.")
                .font(.custom("Pretendard", size: 14))
                .foregroundColor(.white.opacity(0.8))
            
            Text("옷 살 때마다 항상 바뀌는 가격,\n편하게 비교해보세요!")
                .font(.custom("Pretendard", size: 18).weight(.bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("""
                무신사 스카우터는
                소비자들의 합리적인 구매를 위한
                목적으로 개발되었습니다.

                저희는 수익을 창출하지 않습니다.
                """)
                .font(.custom("Pretendard", size: 14))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Constants.Spacing.medium)
    }
    
    private var disclaimerText: some View {
        Text("""
            무신사스카우터에서 제공하는 제품 가격 정보는
            주기적으로 업데이트 되고 있습니다.
            업데이트 후 무신사에서 제품 가격이 변경될 수 있으므로,
            무신사스카우터에서 제공하는 제품 가격과 다르게 조회될 수 있습니다.
            """)
            .font(.custom("Pretendard", size: 12))
            .foregroundColor(.white.opacity(0.5))
            .multilineTextAlignment(.center)
            .padding(.horizontal, Constants.Spacing.medium)
            .padding(.bottom, Constants.Spacing.medium)
    }
    
    private func performApiRequest() {
        // Use session-based authentication
        guard let sessionId = getSessionId() else {
            print("No session ID found")
            return
        }
        
        var request = URLRequest(url: URL(string: "https://your-api-url.com")!)
        request.setValue("Session \(sessionId)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            // API 응답 처리
        }.resume()
    }
    
    private func getSessionId() -> String? {
        return UserDefaults.standard.string(forKey: "sessionId")
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
