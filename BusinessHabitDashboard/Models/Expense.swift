import Foundation

struct Expense: Codable, Identifiable, Hashable {
    let id: UUID
    let userID: UUID
    var category: String
    var amount: Double
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case category
        case amount
        case createdAt = "created_at"
    }
}
