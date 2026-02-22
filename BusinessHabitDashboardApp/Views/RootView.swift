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

    // Estado para navegación de reset password
    @State private var showResetPassword = false

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
                        StatsView(habits: habitViewModel.habits, expenses: expenseViewModel.expenses)
                    }
                    .tabItem {
                        Label("Estadísticas", systemImage: "chart.line.uptrend.xyaxis")
                    }

                    NavigationStack {
                        ProfileView(
                            authViewModel: authViewModel,
                            user: user,
                            habits: habitViewModel.habits,
                            expenses: expenseViewModel.expenses
                        )
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
                LoginView(authViewModel: authViewModel, showResetPassword: $showResetPassword)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.4), value: authViewModel.currentUser != nil)
        .onOpenURL { url in
            handleDeepLink(url)
        }
    }

    // MARK: - Deep Link Handler

    private func handleDeepLink(_ url: URL) {
        // Verificar que sea nuestro esquema
        guard url.scheme == "businesshabit" else { return }

        // Verificar que sea la ruta de reset password
        guard url.host == "reset-password" else { return }

        // Parsear el fragmento para extraer el access_token
        // Formato esperado: businesshabit://reset-password#access_token=TOKEN&type=recovery
        if let fragment = url.fragment {
            let params = parseURLFragment(fragment)

            // Extraer access_token
            if let accessToken = params["access_token"],
               let type = params["type"],
               type == "recovery" {

                // Guardar el token en el ViewModel
                authViewModel.resetToken = accessToken

                // Navegar a ResetPasswordView
                showResetPassword = true

                print("✅ Deep link procesado: Token de recuperación recibido")
            } else {
                print("⚠️ Deep link: No se encontró access_token o type válido")
            }
        } else {
            print("⚠️ Deep link: No se encontró fragment en URL")
        }
    }

    // Parsea el fragmento de URL (formato: key1=value1&key2=value2)
    private func parseURLFragment(_ fragment: String) -> [String: String] {
        var params: [String: String] = [:]

        let components = fragment.components(separatedBy: "&")
        for component in components {
            let keyValue = component.components(separatedBy: "=")
            if keyValue.count == 2 {
                let key = keyValue[0]
                let value = keyValue[1]
                params[key] = value
            }
        }

        return params
    }
}

#Preview {
    RootView()
}
