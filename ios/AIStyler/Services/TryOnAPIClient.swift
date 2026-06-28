import Foundation

struct HealthResponse: Decodable {
    let status: String
}

struct TryOnResponse: Decodable {
    let imageBase64: String
    let outfitName: String
}

private struct APIErrorResponse: Decodable {
    let detail: APIErrorDetail?

    var message: String? {
        switch detail {
        case .string(let value):
            return value
        case .array(let values):
            return values.first?.msg
        case .none:
            return nil
        }
    }

    private enum APIErrorDetail: Decodable {
        case string(String)
        case array([APIErrorItem])

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let string = try? container.decode(String.self) {
                self = .string(string)
                return
            }
            self = .array(try container.decode([APIErrorItem].self))
        }
    }

    private struct APIErrorItem: Decodable {
        let msg: String
    }
}

enum TryOnAPIError: LocalizedError {
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

struct TryOnAPIClient {
    private let session: URLSession
    private let baseURL: URL

    init(baseURL: URL = AppConfig.apiBaseURL, session: URLSession? = nil) {
        self.baseURL = baseURL

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

    func tryOn(front: Data, side: Data, back: Data) async throws -> TryOnResponse {
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()

        appendFile(
            to: &body,
            boundary: boundary,
            fieldName: "front",
            filename: "front.jpg",
            mimeType: "image/jpeg",
            data: front
        )
        appendFile(
            to: &body,
            boundary: boundary,
            fieldName: "side",
            filename: "side.jpg",
            mimeType: "image/jpeg",
            data: side
        )
        appendFile(
            to: &body,
            boundary: boundary,
            fieldName: "back",
            filename: "back.jpg",
            mimeType: "image/jpeg",
            data: back
        )
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        var request = URLRequest(url: baseURL.appending(path: "try-on"))
        request.httpMethod = "POST"
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )
        request.httpBody = body

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

        if !(200...299).contains(httpResponse.statusCode) {
            if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data),
               let message = apiError.message {
                throw TryOnAPIError.apiError(message)
            }
            throw TryOnAPIError.apiError("Try-on failed with status \(httpResponse.statusCode).")
        }

        do {
            return try JSONDecoder().decode(TryOnResponse.self, from: data)
        } catch {
            throw TryOnAPIError.invalidResponse
        }
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
