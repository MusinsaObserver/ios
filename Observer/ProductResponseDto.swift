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
    let productName: String
    let price: Int
    let discountRate: String
    let originalPrice: Int
    let productURL: String
    let imageURL: String
    let priceHistoryList: [PriceHistory]
    let category: String

    // Identifiable 프로토콜을 준수하기 위해 'id'를 사용합니다.
    enum CodingKeys: String, CodingKey {
        case id
        case brand
        case productName
        case price
        case discountRate
        case originalPrice
        case productURL
        case imageURL
        case priceHistoryList
        case category
    }
}

struct PriceHistory: Identifiable, Codable {
    let id: Int
    let date: Date
    let price: Double

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case price
    }
}
