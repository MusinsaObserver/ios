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
    case invalidResponse

    static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.noData, .noData),
             (.decodingError, .decodingError),
             (.invalidResponse, .invalidResponse):
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
    static let deleteAccount = "/api/auth/delete"
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
    func getLikedProducts(offset: Int, limit: Int) async throws -> [ProductResponseDto]
    func toggleProductLike(productId: Int, like: Bool) async throws -> String
    func logout() async throws
    func deleteAccount() async throws -> Bool
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

    func searchProducts(query: String) async throws -> [ProductResponseDto] {
        let endpoint = "\(APIEndpoints.search)?query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        return try await sendRequest(endpoint: endpoint, method: "GET", body: nil)
    }

    func getProductDetails(productId: Int) async throws -> ProductResponseDto {
        let endpoint = "\(APIEndpoints.productDetails)\(productId)"
        return try await sendRequest(endpoint: endpoint, method: "GET", body: nil)
    }

    func getLikedProducts(offset: Int, limit: Int) async throws -> [ProductResponseDto] {
        let endpoint = "\(APIEndpoints.likedProducts)?offset=\(offset)&limit=\(limit)"
        return try await sendRequest(endpoint: endpoint, method: "GET", body: nil)
    }

    func toggleProductLike(productId: Int, like: Bool) async throws -> String {
        let endpoint = "\(APIEndpoints.likeProduct)/product/\(productId)"
        if like {
            return try await sendRequest(endpoint: endpoint, method: "POST", body: nil)
        } else {
            return try await sendRequest(endpoint: endpoint, method: "DELETE", body: nil)
        }
    }

    func deleteAccount() async throws -> Bool {
        let endpoint = APIEndpoints.deleteAccount
        var request = URLRequest(url: URL(string: baseUrl + endpoint)!)
        request.httpMethod = "DELETE"
        
        // 인증 토큰을 헤더에 추가
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        return httpResponse.statusCode == 200
    }

    func appleSignIn(idToken: String) async throws -> String {
        let endpoint = APIEndpoints.appleSignIn
        
        // Define a local struct to decode the response
        struct AppleSignInResponse: Codable {
            let sessionId: String?
            let session: String?
            let userId: String?
        }
        
        let response: AppleSignInResponse = try await sendRequest(endpoint: endpoint, method: "POST", body: ["idToken": idToken])
        
        // Check for different possible keys in the response
        if let sessionId = response.sessionId {
            return sessionId
        } else if let session = response.session {
            return session
        } else if let userId = response.userId {
            return userId
        } else {
            print("Unexpected response structure: \(response)")
            throw APIError.decodingError
        }
    }
    
    func logout() async throws {
        let endpoint = APIEndpoints.logout
        let response: LogoutResponse = try await sendRequest(endpoint: endpoint, method: "POST", body: nil)
        print(response.message)
    }

    func sendRequest<T: Codable>(endpoint: String, method: String, body: [String: Any]? = nil) async throws -> T {
        guard let url = URL(string: "\(baseUrl)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        do {
            let (data, response) = try await urlSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
            }

            // Log response details
            print("Response status code: \(httpResponse.statusCode)")
            print("Response headers: \(httpResponse.allHeaderFields)")

            if let responseString = String(data: data, encoding: .utf8) {
                print("Response body: \(responseString)")
            }

            guard 200...299 ~= httpResponse.statusCode else {
                throw APIError.serverError(httpResponse.statusCode)
            }

            do {
                let decoder = JSONDecoder()
                return try decoder.decode(T.self, from: data)
            } catch {
                print("Decoding error: \(error)")
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .dataCorrupted(let context):
                        print("Data corrupted: \(context)")
                    case .keyNotFound(let key, let context):
                        print("Key '\(key)' not found: \(context.debugDescription)")
                    case .typeMismatch(let type, let context):
                        print("Type mismatch for type \(type): \(context.debugDescription)")
                    case .valueNotFound(let type, let context):
                        print("Value of type \(type) not found: \(context.debugDescription)")
                    @unknown default:
                        print("Unknown decoding error")
                    }
                }
                throw APIError.decodingError
            }
        } catch {
            print("Network error: \(error)")
            throw APIError.networkError(error)
        }
    }
}

// MARK: - Helper Structures
struct EmptyResponse: Codable {}
