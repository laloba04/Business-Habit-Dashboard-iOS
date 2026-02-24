//
//  ExpenseViewModel.swift
//  BusinessHabitDashboardApp
//
//  Created by Maria Bravo Angulo on 10/2/26.
//

import Foundation
import Combine

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

    func deleteExpense(_ expense: Expense, user: SessionUser) async {
        do {
            try await ExpenseService.shared.deleteExpense(id: expense.id, token: user.accessToken)
            expenses.removeAll { $0.id == expense.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Realtime

    /// Cancellable que mantiene la suscripción al subject de Realtime para gastos.
    private var realtimeCancellable: AnyCancellable?

    /// Activa la escucha de cambios en tiempo real para la tabla `expenses`.
    /// El debounce agrupa ráfagas de cambios rápidos en una sola recarga.
    func startRealtime(user: SessionUser) {
        realtimeCancellable = RealtimeService.shared.expensesDidChange
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                Task { await self.loadExpenses(user: user) }
            }
    }

    /// Desactiva la suscripción de Realtime para gastos.
    func stopRealtime() {
        realtimeCancellable = nil
    }
}
