import Foundation

struct ProductResponseDto: Identifiable, Codable {
    let id: Int
    let brand: String
    let productName: String
    let price: Int
    let discountRate: String
    let originalPrice: Int
    let productURL: URL
    let imageURL: URL
    let priceHistoryList: [PriceHistory]
    let category: String
    let favoriteDate: Date?
    let highestPrice: Int?
    let lowestPrice: Int?
    let currentPrice: Int?

    static func ==(lhs: ProductResponseDto, rhs: ProductResponseDto) -> Bool {
        return lhs.id == rhs.id
    }
}

struct PriceHistory: Identifiable, Codable {
    let id: Int
    let date: String
    let price: Int
    
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

struct ProductResponseWrapper: Codable {
    let message: String
    let data: ProductResponseDto
}
