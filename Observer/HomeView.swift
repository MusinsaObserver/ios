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
    @State private var isShowingLikesView = false
    @State private var isShowingLoginView = false
    
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Constants.Colors.backgroundDarkGrey
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: Constants.Spacing.medium) {
                    Spacer().frame(height: navigationBarHeight)
                    searchBar
                    Spacer()
                    descriptionText
                    Spacer()
                    disclaimerText
                }
                .navigationDestination(isPresented: $isShowingSearchResults) {
                    SearchResultsView(searchQuery: searchQuery)
                }
                .navigationDestination(isPresented: $isShowingLikesView) {
                    if authViewModel.isLoggedIn {
                        LikesView(apiClient: APIClient(baseUrl: "https://cea9-141-223-234-170.ngrok-free.app"))
                    } else {
                        LoginView()
                    }
                }
                .navigationDestination(isPresented: $isShowingLoginView) {
                    LoginView()
                }
                
                navigationBar
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            handleOnAppear()
        }
        .onChange(of: isShowingLikesView) { newValue in
            if newValue {
                authViewModel.checkLoginStatus()
                if !authViewModel.isLoggedIn {
                    isShowingLoginView = true
                    isShowingLikesView = false
                }
            }
        }
    }
    
    private var navigationBarHeight: CGFloat {
        44
    }
    
    private var navigationBar: some View {
        NavigationBarView(
            title: "MUSINSA ⦁ OBSERVER",
            isHomeView: $isHomeView,
            isShowingLikesView: $isShowingLikesView,
            isShowingLoginView: $isShowingLoginView
        )
    }
    
    private var searchBar: some View {
        SearchBarView(searchQuery: $searchQuery) {
            isShowingSearchResults = true
            performSearchApiRequest()
        }
        .padding(.horizontal, Constants.Spacing.medium)
        .padding(.top, Constants.Spacing.large)
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
    
    private func handleOnAppear() {
        print("HomeView appeared")
        authViewModel.checkLoginStatus()
    }
    
    private func performSearchApiRequest() {
        guard let url = URL(string: "https://cea9-141-223-234-170.ngrok-free.app/api/product/search?query=\(searchQuery)&page=0&size=100") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("검색 결과를 불러오는데 실패했습니다: \(error.localizedDescription)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("서버 응답 상태 코드: \(httpResponse.statusCode)")
                if httpResponse.statusCode == 200 {
                    if let data = data, let jsonString = String(data: data, encoding: .utf8) {
                        print("응답 JSON: \(jsonString)")
                    }
                } else {
                    print("잘못된 응답이 수신되었습니다.")
                }
            }
        }.resume()
    }
    
    private func performSessionApiRequest() {
        guard let sessionId = authViewModel.getSessionId() else {
            print("No session ID found")
            return
        }
        
        guard let url = URL(string: "https://cea9-141-223-234-170.ngrok-free.app") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Session \(sessionId)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("API request failed: \(error.localizedDescription)")
                return
            }
            print("API request successful")
        }.resume()
    }
}
