//
//  APIClient.swift
//  Observer
//
//  Created by Jiwon Kim on 9/10/24.
//

import Foundation

// MARK: - Error Handling
enum APIError: Error {
    case invalidURL
    case noData
    case decodingError
    case networkError(Error)
    case serverError(Int)
}

// MARK: - API Endpoints
private enum APIEndpoints {
    static let search = "/api/product/search"
    static let productDetails = "/api/product/search/"
    static let likedProducts = "/api/likes/"
    static let likeProduct = "/api/likes/%@/product/%d"
    static let deleteAccount = "/api/users/"
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
    func deleteAccount(userId: String) async throws -> Bool
}

// MARK: - API Client Implementation
class APIClient: APIClientProtocol {
    private let urlSession: URLSession
    private let baseUrl: String
    
    init(baseUrl: String, urlSession: URLSession = .shared) {
        self.baseUrl = baseUrl
        self.urlSession = urlSession
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
    
    private func performRequest<T: Decodable>(endpoint: String, method: HTTPMethod, body: [String: Any]? = nil) async throws -> T {
        guard let url = URL(string: "\(baseUrl)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        log(request: request)
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }
        
        log(response: httpResponse, data: data)
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        do {
            let decodedResponse = try JSONDecoder().decode(T.self, from: data)
            return decodedResponse
        } catch {
            throw APIError.decodingError
        }
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
    
    public func sendRequest<T: Decodable>(endpoint: String, method: String, body: [String: Any]? = nil) async throws -> T {
        return try await performRequest(endpoint: endpoint, method: HTTPMethod(rawValue: method) ?? .GET, body: body)
    }
}

// MARK: - Helper Structures
struct EmptyResponse: Decodable {}
