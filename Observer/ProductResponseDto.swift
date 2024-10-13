//
//  ProductResponseDto.swift
//  Observer
//
//  Created by Jiwon Kim on 9/10/24.
//

import Foundation

struct ProductResponseDto: Identifiable, Codable {
    let id: Int
    let brand: String
    let name: String
    let price: Double
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

struct PriceHistory: Identifiable, Codable {
    let id: Int
    let date: String
    let price: Double
    
    var parsedDate: Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.date(from: date)
    }
}

extension ProductResponseDto {
    var discountRateValue: Double? {
        Double(discountRate.replacingOccurrences(of: "%", with: ""))
    }
    
    var priceDifference: Int {
        originalPrice - Int(price)
    }
}
