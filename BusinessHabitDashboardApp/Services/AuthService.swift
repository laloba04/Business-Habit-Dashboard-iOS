//
//  AuthService.swift
//  BusinessHabitDashboardApp
//
//  Created by Maria Bravo Angulo on 10/2/26.
//

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

struct AuthUser: Codable {
    let id: UUID
    let email: String
}

final class AuthService {
    static let shared = AuthService()

    private init() {}

    // Registra un nuevo usuario con email/password
    func signUp(email: String, password: String) async throws -> SessionUser {
        // Normalizar email: eliminar espacios y convertir a minúsculas
        let safeEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        let endpoint = SupabaseConfig.projectURL
            .appendingPathComponent("auth/v1/signup")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")

        let body: [String: String] = [
            "email": safeEmail,
            "password": password
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            // Manejar rate limit específicamente
            if httpResponse.statusCode == 429 {
                throw APIError.rateLimitExceeded
            }
            let message = String(data: data, encoding: .utf8) ?? "Sign up error"
            throw APIError.serverError(httpResponse.statusCode, message)
        }

        let decoded = try JSONDecoder().decode(AuthResponse.self, from: data)
        return SessionUser(id: decoded.user.id, email: decoded.user.email, accessToken: decoded.accessToken)
    }

    // Inicia sesión con email/password y devuelve un SessionUser listo para usar.
    func login(email: String, password: String) async throws -> SessionUser {
        // Normalizar email: eliminar espacios y convertir a minúsculas
        let safeEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

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
            "email": safeEmail,
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
}
