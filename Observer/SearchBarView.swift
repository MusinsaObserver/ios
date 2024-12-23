import SwiftUI

struct SearchBarView: View {
    @Binding var searchQuery: String
    var onSearchButtonClicked: () -> Void
    
    var body: some View {
        HStack {
            TextField("원하는 상품을 검색해보세요!", text: $searchQuery)
                .padding()
                .background(Constants.Colors.searchBarBackground)
                .cornerRadius(Constants.CornerRadius.large)
                .foregroundColor(.white)
                .accessibilityLabel("상품 검색")
                .onSubmit {
                    onSearchButtonClicked()
                }
            
            Button(action: onSearchButtonClicked) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white)
                    .padding(.trailing, Constants.Spacing.medium)
            }
            .accessibilityLabel("검색")
        }
        .padding(.horizontal, Constants.Spacing.medium)
    }
}
