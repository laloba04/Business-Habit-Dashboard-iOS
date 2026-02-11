//
//  RootView.swift
//  BusinessHabitDashboardApp
//
//  Created by Maria Bravo Angulo on 10/2/26.
//

import SwiftUI

//RootView decide si mostrar Login o la app principal con tabs
//según exista (o no) una sesion activa

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

                    NavigationStack {
                        ProfileView(authViewModel: authViewModel, user: user)
                    }
                    .tabItem {
                        Label("Perfil", systemImage: "person.circle.fill")
                    }
                }
                .task {
                    //Al abrir la app autenticada, cargamos datos iniciales.
                    await habitViewModel.loadHabits(user: user)
                    await expenseViewModel.loadExpenses(user: user)
                }
            } else{
                LoginView(authViewModel: authViewModel)
            }
        }
    }
}
