import Foundation

protocol ProductServiceProtocol {
    func getProductDetails(productId: Int) async throws -> Data
}

class ProductService: ProductServiceProtocol {
    private let baseURL: URL
    private let session: URLSession
    
    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func getProductDetails(productId: Int) async throws -> Data {
        let url = baseURL.appendingPathComponent("api/product/\(productId)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        return data
    }
}
