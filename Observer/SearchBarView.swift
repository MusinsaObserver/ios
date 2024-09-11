//
//  SearchBarView.swift
//  Observer
//
//  Created by Jiwon Kim on 9/10/24.
//

import SwiftUI

struct SearchBarView: View {
    @Binding var searchQuery: String
    var onSearchButtonClicked: () -> Void
    
    var body: some View {
        HStack {
            TextField("원하는 상품을 검색해보세요!", text: $searchQuery)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(25)
                .foregroundColor(.white)
            
            Button(action: {
                onSearchButtonClicked()
            }) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white)
                    .padding(.trailing, 16)
            }
        }
        .padding(.horizontal, Constants.Spacing.medium)
    }
}

struct SearchBarView_Previews: PreviewProvider {
    static var previews: some View {
        SearchBarView(searchQuery: .constant("")) {
            print("Search button clicked")
        }
    }
}
