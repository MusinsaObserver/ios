//
//  APIClient.swift
//  Observer
//
//  Created by Jiwon Kim on 9/10/24.
//

import Foundation

// MARK: - Error Handling
enum APIError: Error, Equatable {
    case invalidURL
    case noData
    case decodingError
    case networkError(Error)
    case serverError(Int)

    static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.noData, .noData),
             (.decodingError, .decodingError):
            return true
        case (.serverError(let lhsCode), .serverError(let rhsCode)):
            return lhsCode == rhsCode
        case (.networkError(_), .networkError(_)):
            return true
        default:
            return false
        }
    }
}

// MARK: - API Endpoints
private enum APIEndpoints {
    static let search = "/api/product/search"
    static let productDetails = "/api/product/search/"
    static let likedProducts = "/api/likes/"
    static let likeProduct = "/api/likes/%@/product/%d"
    static let deleteAccount = "/api/users/"
    static let appleSignIn = "/api/auth/apple/login"
    static let logout = "/api/auth/logout"
}

// MARK: - HTTP Methods
private enum HTTPMethod: String {
    case GET, POST, DELETE
}

// MARK: - API Client Protocol
protocol APIClientProtocol {
    func searchProducts(query: String) async throws -> [ProductResponseDto]
    func getProductDetails(productId: Int) async throws -> ProductResponseDto
    func getLikedProducts(userId: String, offset: Int, limit: Int) async throws -> [ProductResponseDto]
    func toggleProductLike(userId: String, productId: Int, like: Bool) async throws -> String
    func logout() async throws
    func deleteAccount(userId: String) async throws -> Bool
    func appleSignIn(idToken: String) async throws -> String
    func sendRequest<T: Codable>(endpoint: String, method: String, body: [String: Any]?) async throws -> T
}

// MARK: - API Client Implementation
class APIClient: APIClientProtocol {
    private let urlSession: URLSession
    private let baseUrl: String
    private let cache = URLCache.shared

    init(baseUrl: String, urlSession: URLSession = .shared) {
        self.baseUrl = baseUrl
        self.urlSession = urlSession
    }

    private var sessionId: String? {
        get {
            return UserDefaults.standard.string(forKey: "sessionId")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "sessionId")
        }
    }

    func searchProducts(query: String) async throws -> [ProductResponseDto] {
        let endpoint = "\(APIEndpoints.search)?query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        return try await sendRequest(endpoint: endpoint, method: "GET", body: nil)
    }

    func getProductDetails(productId: Int) async throws -> ProductResponseDto {
        let endpoint = "\(APIEndpoints.productDetails)\(productId)"
        return try await sendRequest(endpoint: endpoint, method: "GET", body: nil)
    }

    func getLikedProducts(userId: String, offset: Int, limit: Int) async throws -> [ProductResponseDto] {
        let endpoint = "\(APIEndpoints.likedProducts)\(userId)?offset=\(offset)&limit=\(limit)"
        return try await sendRequest(endpoint: endpoint, method: "GET", body: nil)
    }

    func toggleProductLike(userId: String, productId: Int, like: Bool) async throws -> String {
        let endpoint = String(format: APIEndpoints.likeProduct, userId, productId)
        return try await sendRequest(endpoint: endpoint, method: "POST", body: ["like": like])
    }

    func deleteAccount(userId: String) async throws -> Bool {
        let endpoint = "\(APIEndpoints.deleteAccount)\(userId)"
        let _: EmptyResponse = try await sendRequest(endpoint: endpoint, method: "DELETE", body: nil)
        return true
    }

    func appleSignIn(idToken: String) async throws -> String {
        let endpoint = APIEndpoints.appleSignIn
        return try await sendRequest(endpoint: endpoint, method: "POST", body: ["idToken": idToken])
    }

    func logout() async throws {
        let endpoint = APIEndpoints.logout
        _ = try await sendRequest(endpoint: endpoint, method: "POST", body: nil) as EmptyResponse
        sessionId = nil
    }

    func sendRequest<T: Codable>(endpoint: String, method: String, body: [String: Any]? = nil) async throws -> T {
        guard let url = URL(string: "\(baseUrl)\(endpoint)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method

        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        if let sessionId = sessionId {
            request.setValue("Session-ID \(sessionId)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }

        return try JSONDecoder().decode(T.self, from: data)
    }
}

// MARK: - Helper Structures
struct EmptyResponse: Codable {}

class MockAPIClient: APIClientProtocol {
    func searchProducts(query: String) async throws -> [ProductResponseDto] {
        return []  // Mock implementation
    }
    
    func getProductDetails(productId: Int) async throws -> ProductResponseDto {
        return ProductResponseDto(
            id: productId,
            brand: "Brand",
            name: "Product",
            price: 10000,
            discountRate: "10%",
            originalPrice: 11000,
            url: URL(string: "https://example.com")!,
            imageUrl: URL(string: "https://example.com/image.jpg")!,
            priceHistory: [],
            category: "Category"
        )
    }
    
    func getLikedProducts(userId: String, offset: Int, limit: Int) async throws -> [ProductResponseDto] {
        return [
            ProductResponseDto(
                id: 1,
                brand: "Brand A",
                name: "Product A",
                price: 10000,
                discountRate: "10%",
                originalPrice: 11000,
                url: URL(string: "https://example.com")!,
                imageUrl: URL(string: "https://example.com/imageA.jpg")!,
                priceHistory: [],
                category: "Category A"
            ),
            ProductResponseDto(
                id: 2,
                brand: "Brand B",
                name: "Product B",
                price: 20000,
                discountRate: "20%",
                originalPrice: 25000,
                url: URL(string: "https://example.com")!,
                imageUrl: URL(string: "https://example.com/imageB.jpg")!,
                priceHistory: [],
                category: "Category B"
            )
        ]
    }
    
    func toggleProductLike(userId: String, productId: Int, like: Bool) async throws -> String {
        return "Success"  // Mock implementation
    }
    
    func deleteAccount(userId: String) async throws -> Bool {
        return true  // Simulate successful account deletion
    }
    
    func appleSignIn(idToken: String) async throws -> String {
        return "mockUserId"  // Simulate successful sign-in
    }
    
    func logout() async throws {
        // Simulate successful logout
    }
    
    func sendRequest<T: Codable>(endpoint: String, method: String, body: [String: Any]? = nil) async throws -> T {
        // Mocked sendRequest implementation
        throw APIError.invalidURL
    }
}
