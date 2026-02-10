import Foundation

// Servicio responsable de autenticación contra Supabase Auth.

struct AuthResponse: Codable {
    let accessToken: String
    let user: AuthUser

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case user
    }
}

struct SignUpResponse: Codable {
    let accessToken: String?
    let user: AuthUser?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case user
    }
}

struct AuthUser: Codable {
    let id: UUID
    let email: String
}

final class AuthService {
    static let shared = AuthService()

    private init() {}

    // Inicia sesión con email/password y devuelve un SessionUser listo para usar.
    func login(email: String, password: String) async throws -> SessionUser {
        let endpoint = SupabaseConfig.projectURL
            .appendingPathComponent("auth/v1/token")

        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "grant_type", value: "password")]

        guard let url = components?.url else {
            throw APIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")

        let body: [String: String] = [
            "email": email,
            "password": password
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Login error"
            throw APIError.serverError(httpResponse.statusCode, message)
        }

        let decoded = try JSONDecoder().decode(AuthResponse.self, from: data)
        return SessionUser(id: decoded.user.id, email: decoded.user.email, accessToken: decoded.accessToken)
    }

    // Registra un usuario nuevo. Si Supabase devuelve sesión, también la retornamos.
    func register(email: String, password: String) async throws -> SessionUser? {
        let endpoint = SupabaseConfig.projectURL
            .appendingPathComponent("auth/v1/signup")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")

        let body: [String: String] = [
            "email": email,
            "password": password
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Register error"
            throw APIError.serverError(httpResponse.statusCode, message)
        }

        let decoded = try JSONDecoder().decode(SignUpResponse.self, from: data)

        guard let user = decoded.user, let token = decoded.accessToken else {
            return nil
        }

        return SessionUser(id: user.id, email: user.email, accessToken: token)
    }
}
