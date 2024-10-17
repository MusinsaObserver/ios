//
//  APIClientTests.swift
//  ObserverTests
//
//  Created by Jiwon Kim on 9/17/24.
//

import XCTest
@testable import Observer

class APIClientTests: XCTestCase {
    
    var apiClient: APIClient!
    let mockBaseURL = "https://mock-api.com"
    
    override func setUp() {
        super.setUp()
        
        // Mock URLSession with URLProtocol
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self] // Custom URLProtocol to mock responses
        let mockSession = URLSession(configuration: config)
        
        apiClient = APIClient(baseUrl: mockBaseURL, urlSession: mockSession)
    }
    
    override func tearDown() {
        apiClient = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    // Test searchProducts endpoint success case
    func testSearchProductsSuccess() async throws {
        // Mock Response Data
        let mockProductData = """
        [
            {
                "id": 1,
                "brand": "Brand A",
                "productName": "Test Product",
                "price": 10000,
                "discountRate": "10%",
                "originalPrice": 11000,
                "productURL": "https://example.com",
                "imageURL": "https://example.com/image.jpg",
                "priceHistoryList": [],
                "category": "Category A"
            }
        ]
        """.data(using: .utf8)!
        
        // Set mock response for the request
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, mockProductData)
        }
        
        // Make the API call
        let products = try await apiClient.searchProducts(query: "Test Product")
        
        // Assertions
        XCTAssertEqual(products.count, 1)
        XCTAssertEqual(products.first?.name, "Test Product")
        XCTAssertEqual(products.first?.price, 10000)
    }
    
    // Test getProductDetails success case
    func testGetProductDetailsSuccess() async throws {
        let mockProductData = """
        {
            "id": 1,
            "brand": "Brand A",
            "productName": "Test Product",
            "price": 10000,
            "discountRate": "10%",
            "originalPrice": 11000,
            "productURL": "https://example.com",
            "imageURL": "https://example.com/image.jpg",
            "priceHistoryList": [],
            "category": "Category A"
        }
        """.data(using: .utf8)!
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, mockProductData)
        }
        
        let product = try await apiClient.getProductDetails(productId: 1)
        
        XCTAssertEqual(product.id, 1)
        XCTAssertEqual(product.name, "Test Product")
    }

    // Example Test
    func testInvalidURL() async {
        apiClient = APIClient(baseUrl: "invalid_url")
        
        do {
            _ = try await apiClient.searchProducts(query: "Test Product")
            XCTFail("Expected to throw an invalid URL error")
        } catch {
            XCTAssertEqual(error as? APIError, APIError.invalidURL)
        }
    }

    
    // Test APIClient handles server error (e.g., 500)
    func testServerError() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }
        
        do {
            _ = try await apiClient.searchProducts(query: "Test Product")
            XCTFail("Expected to throw a server error")
        } catch {
            XCTAssertEqual(error as? APIError, APIError.serverError(500))
        }
    }
}

// MARK: - Mock URLProtocol

class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            XCTFail("Handler is unavailable.")
            return
        }
        
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {
        // No-op
    }
}
