import Foundation

// Servicio de acceso a datos para hábitos (CRUD básico vía REST).

private struct HabitCreatePayload: Codable {
    let userID: UUID
    let title: String
    let completed: Bool

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case title
        case completed
    }
}

private struct HabitUpdatePayload: Codable {
    let title: String?
    let completed: Bool?
}

final class HabitService {
    static let shared = HabitService()

    private init() {}

    func fetchHabits(userID: UUID, token: String) async throws -> [Habit] {
        try await APIClient.shared.request(
            path: "habits",
            accessToken: token,
            queryItems: [
                URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString)"),
                URLQueryItem(name: "order", value: "created_at.desc")
            ]
        )
    }

    func createHabit(userID: UUID, title: String, token: String) async throws -> Habit {
        let payload = HabitCreatePayload(userID: userID, title: title, completed: false)
        let body = try APIClient.shared.encode([payload])
        let habits: [Habit] = try await APIClient.shared.request(
            path: "habits",
            method: "POST",
            body: body,
            accessToken: token
        )
        guard let first = habits.first else { throw APIError.decodingError }
        return first
    }

    func updateHabit(id: UUID, title: String?, completed: Bool?, token: String) async throws -> Habit {
        let payload = HabitUpdatePayload(title: title, completed: completed)
        let body = try APIClient.shared.encode(payload)
        let habits: [Habit] = try await APIClient.shared.request(
            path: "habits",
            method: "PATCH",
            body: body,
            accessToken: token,
            queryItems: [URLQueryItem(name: "id", value: "eq.\(id.uuidString)")]
        )
        guard let first = habits.first else { throw APIError.decodingError }
        return first
    }

    func deleteHabit(id: UUID, token: String) async throws {
        let _: [Habit] = try await APIClient.shared.request(
            path: "habits",
            method: "DELETE",
            accessToken: token,
            queryItems: [URLQueryItem(name: "id", value: "eq.\(id.uuidString)")]
        )
    }
}
