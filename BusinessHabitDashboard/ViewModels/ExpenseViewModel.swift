import Foundation

// ViewModel de gastos:
// mantiene lista, loading y errores para la pantalla de gastos.

@MainActor
final class ExpenseViewModel: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadExpenses(user: SessionUser) async {
        isLoading = true
        errorMessage = nil

        do {
            expenses = try await ExpenseService.shared.fetchExpenses(userID: user.id, token: user.accessToken)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func addExpense(category: String, amount: Double, user: SessionUser) async {
        do {
            let created = try await ExpenseService.shared.createExpense(
                userID: user.id,
                category: category,
                amount: amount,
                token: user.accessToken
            )
            expenses.insert(created, at: 0)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
