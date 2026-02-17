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

// Estructura para decodificar errores de Supabase
struct SupabaseErrorResponse: Codable {
    let code: Int?
    let errorCode: String?
    let msg: String?

    enum CodingKeys: String, CodingKey {
        case code
        case errorCode = "error_code"
        case msg
    }
}

final class AuthService {
    static let shared = AuthService()

    private init() {}

    // Parsea los errores de Supabase y los mapea a errores amigables
    private func parseError(statusCode: Int, data: Data) -> APIError {
        // Intentar decodificar el error de Supabase
        if let errorResponse = try? JSONDecoder().decode(SupabaseErrorResponse.self, from: data) {
            // Mapear error_code de Supabase a nuestros errores específicos
            switch errorResponse.errorCode {
            case "invalid_credentials":
                return .invalidCredentials
            case "user_not_found":
                return .userNotFound
            case "email_exists", "user_already_exists":
                return .emailAlreadyInUse
            case "weak_password":
                return .weakPassword
            case "invalid_email":
                return .invalidEmail
            default:
                break
            }
        }

        // Si no podemos parsear o no reconocemos el error, usar el código de estado
        switch statusCode {
        case 400:
            return .invalidCredentials
        case 422:
            return .weakPassword
        case 429:
            return .rateLimitExceeded
        default:
            let message = String(data: data, encoding: .utf8) ?? "Error desconocido"
            return .serverError(statusCode, message)
        }
    }

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
            throw parseError(statusCode: httpResponse.statusCode, data: data)
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
            throw parseError(statusCode: httpResponse.statusCode, data: data)
        }

        let decoded = try JSONDecoder().decode(AuthResponse.self, from: data)
        return SessionUser(id: decoded.user.id, email: decoded.user.email, accessToken: decoded.accessToken)
    }

    // Actualiza la contraseña del usuario autenticado
    func updatePassword(newPassword: String, accessToken: String) async throws {
        let endpoint = SupabaseConfig.projectURL
            .appendingPathComponent("auth/v1/user")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let body: [String: String] = ["password": newPassword]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Error al actualizar contraseña"
            throw APIError.serverError(httpResponse.statusCode, message)
        }
    }

    // Actualiza el email del usuario autenticado
    // Nota: Supabase enviará un email de confirmación al nuevo email
    func updateEmail(newEmail: String, accessToken: String) async throws {
        // Normalizar email
        let safeEmail = newEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        let endpoint = SupabaseConfig.projectURL
            .appendingPathComponent("auth/v1/user")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let body: [String: String] = ["email": safeEmail]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Error al actualizar email"
            throw APIError.serverError(httpResponse.statusCode, message)
        }
    }

    // Solicita recuperación de contraseña mediante email
    // Supabase enviará un email con un link mágico para resetear la contraseña
    func resetPassword(email: String) async throws {
        // Normalizar email
        let safeEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        let endpoint = SupabaseConfig.projectURL
            .appendingPathComponent("auth/v1/recover")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")

        // Incluir redirect URL para deep linking
        let body: [String: Any] = [
            "email": safeEmail,
            "options": [
                "redirectTo": "businesshabit://reset-password"
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw parseError(statusCode: httpResponse.statusCode, data: data)
        }
    }

    // Confirma el reset de contraseña con el token del deep link
    func confirmPasswordReset(accessToken: String, newPassword: String) async throws {
        let endpoint = SupabaseConfig.projectURL
            .appendingPathComponent("auth/v1/user")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let body: [String: String] = ["password": newPassword]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Error al cambiar contraseña"
            throw APIError.serverError(httpResponse.statusCode, message)
        }
    }
}
