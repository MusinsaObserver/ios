//
//  FavoriteService.swift
//  Observer
//
//  Created by Jiwon Kim on 9/11/24.
//

import Foundation

protocol FavoriteServiceProtocol {
    func toggleFavorite(for productId: Int) async throws -> Bool
    func getFavorites() async throws -> [Int]
    func checkFavoriteStatus(for productId: Int) async throws -> Bool
}

class FavoriteService: FavoriteServiceProtocol {
    private let baseURL: URL
    private let session: URLSession
    private let tokenService: TokenServiceProtocol
    
    init(baseURL: URL, session: URLSession = .shared, tokenService: TokenServiceProtocol = TokenService()) {
        self.baseURL = baseURL
        self.session = session
        self.tokenService = tokenService
    }
    
    func toggleFavorite(for productId: Int) async throws -> Bool {
        let url = baseURL.appendingPathComponent("favorites/toggle/\(productId)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = tokenService.getToken() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
            throw FavoriteServiceError.invalidResponse
        }
        
        let result = try JSONDecoder().decode(ToggleFavoriteResponse.self, from: data)
        return result.isFavorite
    }
    
    func getFavorites() async throws -> [Int] {
        let url = baseURL.appendingPathComponent("favorites")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = tokenService.getToken() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
            throw FavoriteServiceError.invalidResponse
        }
        
        let favorites = try JSONDecoder().decode([Int].self, from: data)
        return favorites
    }
    
    func checkFavoriteStatus(for productId: Int) async throws -> Bool {
        let url = baseURL.appendingPathComponent("favorites/status/\(productId)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = tokenService.getToken() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
            throw FavoriteServiceError.invalidResponse
        }
        
        let status = try JSONDecoder().decode(FavoriteStatus.self, from: data)
        return status.isFavorite
    }
}

enum FavoriteServiceError: Error {
    case invalidResponse
    case decodingError
}

struct ToggleFavoriteResponse: Codable {
    let isFavorite: Bool
}

struct FavoriteStatus: Codable {
    let isFavorite: Bool
}
