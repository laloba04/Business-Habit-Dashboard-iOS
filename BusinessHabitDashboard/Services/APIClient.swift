import Foundation

// Cliente HTTP genérico para endpoints REST de Supabase.
// Centraliza headers, serialización y manejo básico de errores.

enum APIError: LocalizedError {
    // Errores típicos de red/decodificación que mostramos en la UI.
    case invalidResponse
    case serverError(Int, String)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Respuesta inválida del servidor"
        case let .serverError(code, message):
            return "Error \(code): \(message)"
        case .decodingError:
            return "No se pudo decodificar la respuesta"
        }
    }
}

final class APIClient {
    static let shared = APIClient()

    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
    }

    // Método genérico para peticiones REST que devuelven JSON decodificable.
    func request<T: Decodable>(
        path: String,
        method: String = "GET",
        body: Data? = nil,
        accessToken: String? = nil,
        queryItems: [URLQueryItem] = []
    ) async throws -> T {
        var components = URLComponents(url: SupabaseConfig.projectURL, resolvingAgainstBaseURL: false)
        components?.path = "/rest/v1/\(path)"
        components?.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components?.url else {
            throw APIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")

        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(httpResponse.statusCode, message)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError
        }
    }

    func encode<T: Encodable>(_ value: T) throws -> Data {
        try encoder.encode(value)
    }
}
