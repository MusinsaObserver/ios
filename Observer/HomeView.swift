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
                    navigationBar
                        .padding(.top, safeAreaTop() - 80)
                    searchBar
                        .padding(.top, safeAreaTop() - 20)
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
                        LikesView(apiClient: APIClient(baseUrl: "https://6817-169-211-217-48.ngrok-free.app"))
                    } else {
                        LoginView()
                    }
                }
                .navigationDestination(isPresented: $isShowingLoginView) {
                    LoginView()
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            handleOnAppear()
        }
        .onChange(of: isShowingLikesView) { oldValue, newValue in
            authViewModel.checkLoginStatus()
            if !authViewModel.isLoggedIn {
                isShowingLoginView = true
                isShowingLikesView = false
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
        guard let url = URL(string: "https://6817-169-211-217-48.ngrok-free.app/api/product/search?query=\(searchQuery)&page=0&size=100") else {
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
                    if let data = data {
                        if let jsonString = String(data: data, encoding: .utf8) {
                            print("응답 JSON: \(jsonString)")
                        }
                        
                        do {
                            let decodedResponse = try JSONDecoder().decode(SearchResponse.self, from: data)

                            let products = decodedResponse.data
                            DispatchQueue.main.async {
                                print("검색된 제품: \(products)")
                            }
                            
                        } catch let DecodingError.dataCorrupted(context) {
                            print("디코딩 오류 발생: 데이터 손상 \(context.debugDescription)")
                        } catch let DecodingError.keyNotFound(key, context) {
                            print("디코딩 오류 발생: 키를 찾을 수 없음 '\(key.stringValue)' - \(context.debugDescription)")
                        } catch let DecodingError.typeMismatch(type, context) {
                            print("디코딩 오류 발생: 타입 불일치 \(type) - \(context.debugDescription)")
                            print("오류 발생 경로: \(context.codingPath)")
                        } catch let DecodingError.valueNotFound(value, context) {
                            print("디코딩 오류 발생: 값을 찾을 수 없음 '\(value)' - \(context.debugDescription)")
                        } catch {
                            print("디코딩 오류 발생: \(error.localizedDescription)")
                        }
                    }
                } else {
                    print("잘못된 응답이 수신되었습니다.")
                }
            }
        }
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
