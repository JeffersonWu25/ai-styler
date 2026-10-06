import Foundation

struct HealthResponse: Decodable {
    let status: String
}

enum APIError: LocalizedError {
    case invalidResponse
    case serverUnavailable
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "Unexpected response from the server."
        case .serverUnavailable:
            "Could not reach the backend. Make sure it is running on \(AppConfig.apiBaseURL.absoluteString)."
        case .apiError(let message):
            message
        }
    }
}

final class APIClient {
    private let session: URLSession
    private let baseURL: URL
    private let jsonEncoder: JSONEncoder

    init(baseURL: URL = AppConfig.apiBaseURL, session: URLSession? = nil) {
        self.baseURL = baseURL
        self.jsonEncoder = JSONEncoder()

        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 300
            configuration.timeoutIntervalForResource = 600
            self.session = URLSession(configuration: configuration)
        }
    }

    func checkHealth() async throws -> Bool {
        let url = baseURL.appending(path: "health")

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw APIError.serverUnavailable
        }

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(HealthResponse.self, from: data)
        return decoded.status == "ok"
    }

    func fetchUser() async throws -> UserResponse {
        try await get("user", as: UserResponse.self)
    }

    func uploadUserPhoto(slot: String, jpegData: Data) async throws -> PhotoResponse {
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        appendFile(
            to: &body,
            boundary: boundary,
            fieldName: "image",
            filename: "\(slot).jpg",
            mimeType: "image/jpeg",
            data: jpegData
        )
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        var request = makeRequest(path: "user/photos/\(slot)", method: "PUT")
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )
        request.httpBody = body

        return try await send(request, as: PhotoResponse.self)
    }

    func deleteUserPhoto(slot: String) async throws {
        try await send(makeRequest(path: "user/photos/\(slot)", method: "DELETE"))
    }

    func fetchOutfits() async throws -> [OutfitSummary] {
        try await get("outfits", as: [OutfitSummary].self)
    }

    func fetchOutfit(id: UUID) async throws -> OutfitDetail {
        try await get("outfits/\(id.uuidString)", as: OutfitDetail.self)
    }

    func createTryOn(outfitId: UUID) async throws -> TryOnResponse {
        try await post("try-ons", body: TryOnCreateRequest(outfitId: outfitId), as: TryOnResponse.self)
    }

    func fetchSavedLooks() async throws -> [SavedLook] {
        try await get("user/saved-looks", as: [SavedLook].self)
    }

    func saveLook(tryOnId: UUID) async throws -> SavedLook {
        try await post(
            "user/saved-looks",
            body: SavedLookCreateRequest(tryOnId: tryOnId),
            as: SavedLook.self
        )
    }

    func deleteSavedLook(id: UUID) async throws {
        try await send(makeRequest(path: "user/saved-looks/\(id.uuidString)", method: "DELETE"))
    }

    func downloadImage(from url: URL) async throws -> Data {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw APIError.apiError("Could not download the image.")
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.apiError("Could not download the image.")
        }

        return data
    }

    private func get<T: Decodable>(_ path: String, as type: T.Type) async throws -> T {
        try await send(makeRequest(path: path, method: "GET"), as: type)
    }

    private func post<Body: Encodable, T: Decodable>(
        _ path: String,
        body: Body,
        as type: T.Type
    ) async throws -> T {
        var request = makeRequest(path: path, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try jsonEncoder.encode(body)
        } catch {
            throw APIError.invalidResponse
        }
        return try await send(request, as: type)
    }

    private func makeRequest(path: String, method: String) -> URLRequest {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = method
        return request
    }

    private func send(_ request: URLRequest) async throws {
        _ = try await responseData(for: request)
    }

    private func send<T: Decodable>(_ request: URLRequest, as type: T.Type) async throws -> T {
        let data = try await responseData(for: request)
        do {
            return try makeDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.invalidResponse
        }
    }

    private func responseData(for request: URLRequest) async throws -> Data {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.serverUnavailable
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if !(200...299).contains(httpResponse.statusCode) {
            if let message = Self.parseAPIErrorMessage(from: data) {
                throw APIError.apiError(message)
            }
            throw APIError.apiError("Request failed with status \(httpResponse.statusCode).")
        }

        return data
    }

    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            if let date = Self.parseDate(value) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date: \(value)"
            )
        }
        return decoder
    }

    private static func parseDate(_ value: String) -> Date? {
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = withFraction.date(from: value) {
            return date
        }

        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return plain.date(from: value)
    }

    private static func parseAPIErrorMessage(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let detail = json["detail"] else {
            return nil
        }

        if let message = detail as? String {
            return message
        }

        if let items = detail as? [[String: Any]] {
            return items.first?["msg"] as? String
        }

        return nil
    }

    private func appendFile(
        to body: inout Data,
        boundary: String,
        fieldName: String,
        filename: String,
        mimeType: String,
        data: Data
    ) {
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append(
            "Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename)\"\r\n"
                .data(using: .utf8)!
        )
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
    }
}

private struct TryOnCreateRequest: Encodable {
    let outfitId: UUID
}

private struct SavedLookCreateRequest: Encodable {
    let tryOnId: UUID
}
