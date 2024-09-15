//
//  Constants.swift
//  Observer
//
//  Created by Jiwon Kim on 9/10/24.
//

import SwiftUI

enum Constants {
    enum Colors {
        static let backgroundDarkGrey = Color(red: 0.21, green: 0.21, blue: 0.21)
        static let searchBarText = Color.white
        static let searchBarBackground = Color.white.opacity(0.1)
        static let cardBackground = Color.white.opacity(0.1)
    }
    
    enum Spacing {
        static let xSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
    }
    
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 25
    }
    
    enum IconName {
        static let search = "magnifyingglass"
    }
    
    enum AccessibilityLabel {
        static let searchField = "상품 검색"
        static let searchButton = "검색"
    }
    
    enum PlaceholderText {
        static let search = "원하는 상품을 검색해보세요!"
    }
    
    enum FontSize {
        static let small: CGFloat = 14
    }
    
    enum Fonts {
        static let pretendard = "Pretendard"
    }
    
    enum ImageSize {
        static let height: CGFloat = 180
    }
}
