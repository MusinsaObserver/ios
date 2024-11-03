import Foundation

struct SearchResponse: Codable {
    let message: String
    let data: [ProductResponseDto]
    let pagination: Pagination
}

struct Pagination: Codable {
    let currentPage: Int
    let totalPages: Int
    let pageSize: Int
    let totalElements: Int
    let last: Bool
}
