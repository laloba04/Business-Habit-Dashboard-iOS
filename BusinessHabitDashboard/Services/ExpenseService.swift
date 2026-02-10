import Foundation

private struct ExpenseCreatePayload: Codable {
    let userID: UUID
    let category: String
    let amount: Double

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case category
        case amount
    }
}

final class ExpenseService {
    static let shared = ExpenseService()

    private init() {}

    func fetchExpenses(userID: UUID, token: String) async throws -> [Expense] {
        try await APIClient.shared.request(
            path: "expenses",
            accessToken: token,
            queryItems: [
                URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString)"),
                URLQueryItem(name: "order", value: "created_at.desc")
            ]
        )
    }

    func createExpense(userID: UUID, category: String, amount: Double, token: String) async throws -> Expense {
        let payload = ExpenseCreatePayload(userID: userID, category: category, amount: amount)
        let body = try APIClient.shared.encode([payload])
        let expenses: [Expense] = try await APIClient.shared.request(
            path: "expenses",
            method: "POST",
            body: body,
            accessToken: token
        )
        guard let first = expenses.first else { throw APIError.decodingError }
        return first
    }
}
