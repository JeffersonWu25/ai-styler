import Foundation
import Observation

struct AuthUser: Decodable, Equatable {
    let id: String
    let email: String
    let createdAt: Date
}

struct AuthTokenResponse: Decodable {
    let accessToken: String
    let user: AuthUser
}

@Observable
@MainActor
final class AuthService {
    private(set) var isAuthenticated = false
    private(set) var isCheckingSession = true
    private(set) var currentUser: AuthUser?
    var errorMessage: String?

    let apiClient = TryOnAPIClient()

    init() {
        Task { await restoreSession() }
    }

    func restoreSession() async {
        isCheckingSession = true
        defer { isCheckingSession = false }

        guard let token = KeychainHelper.loadAccessToken() else {
            clearSession()
            return
        }

        applySession(token: token)

        do {
            currentUser = try await apiClient.fetchCurrentUser()
            isAuthenticated = true
            errorMessage = nil
        } catch {
            clearSession()
        }
    }

    func signIn(email: String, password: String) async {
        await authenticate {
            try await apiClient.logIn(email: email, password: password)
        }
    }

    func signUp(email: String, password: String) async {
        await authenticate {
            try await apiClient.signUp(email: email, password: password)
        }
    }

    func signOut() {
        KeychainHelper.deleteAccessToken()
        clearSession()
    }

    private func authenticate(_ request: () async throws -> AuthTokenResponse) async {
        errorMessage = nil

        do {
            let response = try await request()
            KeychainHelper.saveAccessToken(response.accessToken)
            applySession(token: response.accessToken)
            currentUser = response.user
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func applySession(token: String) {
        apiClient.accessToken = token
    }

    private func clearSession() {
        apiClient.accessToken = nil
        currentUser = nil
        isAuthenticated = false
    }
}
