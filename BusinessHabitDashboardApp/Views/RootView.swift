//
//  RootView.swift
//  BusinessHabitDashboardApp
//
//  Created by Maria Bravo Angulo on 10/2/26.
//

import SwiftUI

/// RootView decide si mostrar Onboarding, Login o la app principal con tabs
/// según el estado de la sesión y si completó el onboarding
struct RootView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var habitViewModel = HabitViewModel()
    @StateObject private var expenseViewModel = ExpenseViewModel()

    // Estado de onboarding persistido en UserDefaults
    @AppStorage("has_completed_onboarding") private var hasCompletedOnboarding: Bool = false

    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                // Primera vez: mostrar onboarding
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .transition(.opacity.combined(with: .scale))
            } else if let user = authViewModel.currentUser {
                // Usuario autenticado: mostrar tabs
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

                    NavigationStack {
                        ProfileView(authViewModel: authViewModel, user: user)
                    }
                    .tabItem {
                        Label("Perfil", systemImage: "person.circle.fill")
                    }
                }
                .task {
                    // Al abrir la app autenticada, cargamos datos iniciales
                    await habitViewModel.loadHabits(user: user)
                    await expenseViewModel.loadExpenses(user: user)
                }
                .transition(.opacity.combined(with: .scale))
            } else {
                // No autenticado: mostrar login
                LoginView(authViewModel: authViewModel)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.4), value: authViewModel.currentUser != nil)
    }
}

#Preview {
    RootView()
}
