//
//  ProductResponseDto.swift
//  Observer
//
//  Created by Jiwon Kim on 9/10/24.
//

import Foundation

/// 제품 정보를 나타내는 데이터 전송 객체
struct ProductResponseDto: Identifiable, Codable {
    let id: Int
    let brand: String
    let name: String
    let price: Int
    let discountRate: String
    let originalPrice: Int
    let url: URL
    let imageUrl: URL
    let priceHistory: [PriceHistory]
    let category: String
    
    static func ==(lhs: ProductResponseDto, rhs: ProductResponseDto) -> Bool {
        return lhs.id == rhs.id
    }

    enum CodingKeys: String, CodingKey {
        case id
        case brand
        case name = "productName"
        case price
        case discountRate
        case originalPrice
        case url = "productURL"
        case imageUrl = "imageURL"
        case priceHistory = "priceHistoryList"
        case category
    }
}

/// 제품 가격 기록을 나타내는 구조체
struct PriceHistory: Identifiable, Codable {
    let id: Int
    let date: Date
    let price: Double
}

extension ProductResponseDto {
    /// 할인율을 Double 타입으로 변환
    var discountRateValue: Double? {
        Double(discountRate.replacingOccurrences(of: "%", with: ""))
    }
    
    /// 현재 가격과 원래 가격의 차이
    var priceDifference: Int {
        originalPrice - price
    }
}
