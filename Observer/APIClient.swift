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
    func getLikedProducts(userId: String) async throws -> [ProductResponseDto]
    func toggleProductLike(userId: String, productId: Int, like: Bool) async throws -> String
    func logout() async throws
    func deleteAccount(userId: String) async throws -> Bool
    func appleSignIn(idToken: String) async throws -> String
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
        return try await performRequest(endpoint: endpoint, method: .GET)
    }

    func getProductDetails(productId: Int) async throws -> ProductResponseDto {
        let endpoint = "\(APIEndpoints.productDetails)\(productId)"
        return try await performRequest(endpoint: endpoint, method: .GET)
    }

    func getLikedProducts(userId: String) async throws -> [ProductResponseDto] {
        let endpoint = "\(APIEndpoints.likedProducts)\(userId)"
        return try await performRequest(endpoint: endpoint, method: .GET)
    }

    func toggleProductLike(userId: String, productId: Int, like: Bool) async throws -> String {
        let endpoint = String(format: APIEndpoints.likeProduct, userId, productId)
        return try await performRequest(endpoint: endpoint, method: .POST, body: ["like": like])
    }

    func deleteAccount(userId: String) async throws -> Bool {
        let endpoint = "\(APIEndpoints.deleteAccount)\(userId)"
        let _: EmptyResponse = try await performRequest(endpoint: endpoint, method: .DELETE)
        return true
    }

    func appleSignIn(idToken: String) async throws -> String {
        let endpoint = APIEndpoints.appleSignIn
        return try await performRequest(endpoint: endpoint, method: .POST, body: ["idToken": idToken])
    }

    func logout() async throws {
        let endpoint = APIEndpoints.logout
        _ = try await performRequest(endpoint: endpoint, method: .POST, body: nil) as EmptyResponse
        sessionId = nil
    }

    private func performRequest<T: Codable>(endpoint: String, method: HTTPMethod, body: [String: Any]? = nil) async throws -> T {
        guard let url = URL(string: "\(baseUrl)\(endpoint)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        if let sessionId = sessionId {
            request.setValue("Session-ID \(sessionId)", forHTTPHeaderField: "Authorization")
        }

        if method == .GET, let cachedResponse = cache.cachedResponse(for: request) {
            return try JSONDecoder().decode(T.self, from: cachedResponse.data)
        }

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }

        let decodedResponse = try JSONDecoder().decode(T.self, from: data)

        if method == .GET {
            let cachedData = CachedURLResponse(response: httpResponse, data: data)
            cache.storeCachedResponse(cachedData, for: request)
        }

        return decodedResponse
    }

    private func log(request: URLRequest) {
        print("Request: \(request.httpMethod ?? "") \(request.url?.absoluteString ?? "")")
        print("Headers: \(request.allHTTPHeaderFields ?? [:])")
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("Body: \(bodyString)")
        }
    }

    private func log(response: HTTPURLResponse, data: Data?) {
        print("Response: \(response.statusCode) \(response.url?.absoluteString ?? "")")
        if let data = data, let bodyString = String(data: data, encoding: .utf8) {
            print("Body: \(bodyString)")
        }
    }

    func sendRequest<T: Codable>(endpoint: String, method: String, body: [String: Any]? = nil) async throws -> T {
        return try await performRequest(endpoint: endpoint, method: HTTPMethod(rawValue: method) ?? .GET, body: body)
    }
}

// MARK: - Helper Structures
struct EmptyResponse: Codable {}
