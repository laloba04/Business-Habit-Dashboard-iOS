import Foundation

// Modelo de dominio para un hábito del usuario.
// Se mapea 1:1 con la tabla `habits` de Supabase.

struct Habit: Codable, Identifiable, Hashable {
    let id: UUID
    let userID: UUID
    var title: String
    var completed: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case title
        case completed
        case createdAt = "created_at"
    }
}
