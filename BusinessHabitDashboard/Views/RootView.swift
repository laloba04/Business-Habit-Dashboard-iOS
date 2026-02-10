import SwiftUI

// RootView decide si mostrar Login o la app principal con tabs
// según exista (o no) una sesión activa.

struct RootView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var habitViewModel = HabitViewModel()
    @StateObject private var expenseViewModel = ExpenseViewModel()

    var body: some View {
        Group {
            if let user = authViewModel.currentUser {
                TabView {
                    NavigationStack {
                        DashboardView(habits: habitViewModel.habits, expenses: expenseViewModel.expenses)
                    }
                    .tabItem {
                        Label("Dashboard", systemImage: "chart.bar.fill")
                    }

                    NavigationStack {
                        HabitsView(viewModel: habitViewModel, user: user)
                    }
                    .tabItem {
                        Label("Hábitos", systemImage: "checklist")
                    }

                    NavigationStack {
                        ExpensesView(viewModel: expenseViewModel, user: user)
                    }
                    .tabItem {
                        Label("Gastos", systemImage: "dollarsign.circle")
                    }
                }
                .task {
                    // Al abrir la app autenticada, cargamos datos iniciales.
                    await habitViewModel.loadHabits(user: user)
                    await expenseViewModel.loadExpenses(user: user)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Salir") {
                            authViewModel.logout()
                        }
                    }
                }
            } else {
                LoginView(authViewModel: authViewModel)
            }
        }
    }
}
