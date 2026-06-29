import Foundation

struct HealthResponse: Decodable {
    let status: String
}

struct TryOnResponse: Decodable {
    let generationId: String
    let imageBase64: String
    let outfitName: String
}

struct GenerationResponse: Decodable, Hashable, Identifiable {
    let id: String
    let outfitName: String
    let isSaved: Bool
    let createdAt: Date
}

struct UserPhotoResponse: Decodable {
    let slot: String
    let updatedAt: Date
}

struct MeAssetsResponse: Decodable {
    let userPhotos: [UserPhotoResponse]
    let generations: [GenerationResponse]
}

enum TryOnAPIError: LocalizedError {
    case invalidResponse
    case serverUnavailable
    case unauthorized
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "Unexpected response from the server."
        case .serverUnavailable:
            "Could not reach the backend. Make sure it is running on \(AppConfig.apiBaseURL.absoluteString)."
        case .unauthorized:
            "Your session expired. Please sign in again."
        case .apiError(let message):
            message
        }
    }
}

final class TryOnAPIClient {
    var accessToken: String?

    private let session: URLSession
    private let baseURL: URL
    private let jsonDecoder: JSONDecoder

    init(baseURL: URL = AppConfig.apiBaseURL, session: URLSession? = nil) {
        self.baseURL = baseURL
        self.jsonDecoder = JSONDecoder()
        self.jsonDecoder.dateDecodingStrategy = .iso8601

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
            throw TryOnAPIError.serverUnavailable
        }

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw TryOnAPIError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(HealthResponse.self, from: data)
        return decoded.status == "ok"
    }

    func signUp(email: String, password: String) async throws -> AuthTokenResponse {
        let url = baseURL.appending(path: "auth/signup")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["email": email, "password": password])

        return try await send(request, decode: AuthTokenResponse.self)
    }

    func logIn(email: String, password: String) async throws -> AuthTokenResponse {
        let url = baseURL.appending(path: "auth/login")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["email": email, "password": password])

        return try await send(request, decode: AuthTokenResponse.self)
    }

    func fetchCurrentUser() async throws -> AuthUser {
        let url = baseURL.appending(path: "auth/me")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyAuthHeader(to: &request)

        return try await send(request, decode: AuthUser.self)
    }

    func tryOn() async throws -> TryOnResponse {
        var request = URLRequest(url: baseURL.appending(path: "try-on"))
        request.httpMethod = "POST"
        applyAuthHeader(to: &request)

        return try await send(request, decode: TryOnResponse.self)
    }

    func fetchMeAssets() async throws -> MeAssetsResponse {
        let url = baseURL.appending(path: "me/assets")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyAuthHeader(to: &request)

        return try await send(request, decode: MeAssetsResponse.self)
    }

    func fetchUserPhotos() async throws -> [UserPhotoResponse] {
        let url = baseURL.appending(path: "user-photos")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyAuthHeader(to: &request)

        struct ListResponse: Decodable {
            let photos: [UserPhotoResponse]
        }

        let response = try await send(request, decode: ListResponse.self)
        return response.photos
    }

    func uploadUserPhoto(slot: String, jpegData: Data) async throws -> UserPhotoResponse {
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

        var request = URLRequest(url: baseURL.appending(path: "user-photos/\(slot)"))
        request.httpMethod = "PUT"
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )
        request.httpBody = body
        applyAuthHeader(to: &request)

        return try await send(request, decode: UserPhotoResponse.self)
    }

    func fetchUserPhotoImage(slot: String) async throws -> Data {
        let url = baseURL.appending(path: "user-photos/\(slot)/image")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyAuthHeader(to: &request)

        return try await fetchImageData(request)
    }

    func deleteUserPhoto(slot: String) async throws {
        let url = baseURL.appending(path: "user-photos/\(slot)")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        applyAuthHeader(to: &request)

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw TryOnAPIError.serverUnavailable
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TryOnAPIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw TryOnAPIError.unauthorized
        }

        if httpResponse.statusCode == 204 {
            return
        }

        if let message = Self.parseAPIErrorMessage(from: data) {
            throw TryOnAPIError.apiError(message)
        }
        throw TryOnAPIError.apiError("Request failed with status \(httpResponse.statusCode).")
    }

    func fetchGenerations() async throws -> [GenerationResponse] {
        let url = baseURL.appending(path: "generations")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyAuthHeader(to: &request)

        return try await send(request, decode: [GenerationResponse].self)
    }

    func saveGeneration(id: String) async throws -> GenerationResponse {
        let url = baseURL.appending(path: "generations/\(id)/save")
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        applyAuthHeader(to: &request)

        return try await send(request, decode: GenerationResponse.self)
    }

    func fetchSavedGenerations() async throws -> [GenerationResponse] {
        var components = URLComponents(
            url: baseURL.appending(path: "generations"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [URLQueryItem(name: "saved", value: "true")]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        applyAuthHeader(to: &request)

        return try await send(request, decode: [GenerationResponse].self)
    }

    func fetchGenerationImage(id: String) async throws -> Data {
        let url = baseURL.appending(path: "generations/\(id)/image")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyAuthHeader(to: &request)

        return try await fetchImageData(request)
    }

    private func fetchImageData(_ request: URLRequest) async throws -> Data {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw TryOnAPIError.serverUnavailable
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TryOnAPIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw TryOnAPIError.unauthorized
        }

        if !(200...299).contains(httpResponse.statusCode) {
            if let message = Self.parseAPIErrorMessage(from: data) {
                throw TryOnAPIError.apiError(message)
            }
            throw TryOnAPIError.apiError("Request failed with status \(httpResponse.statusCode).")
        }

        return data
    }

    private func send<T: Decodable>(_ request: URLRequest, decode type: T.Type) async throws -> T {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw TryOnAPIError.serverUnavailable
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TryOnAPIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw TryOnAPIError.unauthorized
        }

        if !(200...299).contains(httpResponse.statusCode) {
            if let message = Self.parseAPIErrorMessage(from: data) {
                throw TryOnAPIError.apiError(message)
            }
            throw TryOnAPIError.apiError("Request failed with status \(httpResponse.statusCode).")
        }

        do {
            return try jsonDecoder.decode(T.self, from: data)
        } catch {
            throw TryOnAPIError.invalidResponse
        }
    }

    private func applyAuthHeader(to request: inout URLRequest) {
        guard let accessToken else { return }
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
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
