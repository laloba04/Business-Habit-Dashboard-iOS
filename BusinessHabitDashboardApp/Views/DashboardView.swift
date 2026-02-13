//
//  DashboardView.swift
//  BusinessHabitDashboardApp
//
//  Created by Maria Bravo Angulo on 10/2/26.
//

import Charts
import SwiftUI

struct DashboardView: View {
    let habits: [Habit]
    let expenses: [Expense]

    @State private var animateCards = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppStyles.spacingLarge) {
                // Header con saludo
                headerSection

                // Métricas de hábitos
                habitsMetricsSection

                // Métricas de gastos
                expensesMetricsSection

                // Gráfico de gastos por categoría
                if !expenses.isEmpty {
                    expensesByCategoryChart
                }

                // Gráfico de tendencia de hábitos (simulado con datos disponibles)
                if !habits.isEmpty {
                    habitsCompletionChart
                }
            }
            .padding(AppStyles.spacingMedium)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("Dashboard")
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animateCards = true
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppStyles.spacingSmall) {
            Text("Resumen general")
                .font(.title2.weight(.bold))
                .foregroundStyle(AppColors.textPrimary)

            Text("Tu progreso de hoy")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: animateCards)
    }

    // MARK: - Habits Metrics Section

    private var habitsMetricsSection: some View {
        VStack(alignment: .leading, spacing: AppStyles.spacingMedium) {
            sectionHeader(
                title: "Hábitos",
                icon: "checkmark.circle.fill",
                gradient: AppColors.secondaryGradient
            )

            if habits.isEmpty {
                emptyStateCard(
                    icon: "checkmark.circle.fill",
                    title: "Sin hábitos",
                    message: "Crea tu primer hábito para empezar",
                    gradient: AppColors.secondaryGradient
                )
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: AppStyles.spacingMedium) {
                    // Total de hábitos
                    MetricCard(
                        title: "Total",
                        value: "\(habits.count)",
                        icon: "list.bullet.circle.fill",
                        gradient: AppColors.primaryGradient,
                        delay: 0.2
                    )

                    // Hábitos completados
                    MetricCard(
                        title: "Completados",
                        value: "\(completedHabits)",
                        icon: "checkmark.circle.fill",
                        gradient: AppColors.successGradient,
                        delay: 0.25
                    )

                    // Hábitos pendientes
                    MetricCard(
                        title: "Pendientes",
                        value: "\(pendingHabits)",
                        icon: "clock.fill",
                        gradient: LinearGradient(
                            colors: [AppColors.warning, AppColors.warning.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        delay: 0.3
                    )

                    // Porcentaje de completados
                    MetricCard(
                        title: "Progreso",
                        value: "\(completionPercentage)%",
                        icon: "percent",
                        gradient: AppColors.accentGradient,
                        delay: 0.35
                    )
                }
            }
        }
    }

    // MARK: - Expenses Metrics Section

    private var expensesMetricsSection: some View {
        VStack(alignment: .leading, spacing: AppStyles.spacingMedium) {
            sectionHeader(
                title: "Gastos",
                icon: "eurosign.circle.fill",
                gradient: AppColors.accentGradient
            )

            if expenses.isEmpty {
                emptyStateCard(
                    icon: "eurosign.circle.fill",
                    title: "Sin gastos",
                    message: "Registra tus gastos para llevar control",
                    gradient: AppColors.accentGradient
                )
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: AppStyles.spacingMedium) {
                    // Total gastado
                    MetricCard(
                        title: "Total",
                        value: formatCurrency(totalExpenses),
                        icon: "eurosign.circle.fill",
                        gradient: LinearGradient(
                            colors: [Color(hex: "DC2626"), Color(hex: "B91C1C")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        delay: 0.4
                    )

                    // Cantidad de gastos
                    MetricCard(
                        title: "Registros",
                        value: "\(expenses.count)",
                        icon: "list.number",
                        gradient: AppColors.primaryGradient,
                        delay: 0.45
                    )

                    // Promedio de gastos
                    MetricCard(
                        title: "Promedio",
                        value: formatCurrency(averageExpense),
                        icon: "chart.bar.fill",
                        gradient: AppColors.accentGradient,
                        delay: 0.5
                    )

                    // Categorías únicas
                    MetricCard(
                        title: "Categorías",
                        value: "\(uniqueCategories)",
                        icon: "tag.fill",
                        gradient: LinearGradient(
                            colors: [Color(hex: "8B5CF6"), Color(hex: "7C3AED")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        delay: 0.55
                    )
                }
            }
        }
    }

    // MARK: - Expenses by Category Chart

    private var expensesByCategoryChart: some View {
        VStack(alignment: .leading, spacing: AppStyles.spacingMedium) {
            Text("Gastos por categoría")
                .font(.headline)
                .foregroundStyle(AppColors.textPrimary)

            Chart(expensesByCategory, id: \.category) { item in
                BarMark(
                    x: .value("Monto", item.amount),
                    y: .value("Categoría", item.category)
                )
                .foregroundStyle(by: .value("Categoría", item.category))
                .cornerRadius(6)
            }
            .chartForegroundStyleScale(range: AppColors.chartColors)
            .chartLegend(.hidden)
            .frame(height: CGFloat(max(200, expensesByCategory.count * 50)))
            .padding(.vertical, AppStyles.spacingSmall)
        }
        .padding(AppStyles.spacingLarge)
        .cardStyle(shadow: true)
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.6), value: animateCards)
    }

    // MARK: - Habits Completion Chart

    private var habitsCompletionChart: some View {
        VStack(alignment: .leading, spacing: AppStyles.spacingMedium) {
            Text("Estado de hábitos")
                .font(.headline)
                .foregroundStyle(AppColors.textPrimary)

            Chart {
                // Completados
                SectorMark(
                    angle: .value("Completados", completedHabits),
                    innerRadius: .ratio(0.6),
                    angularInset: 2
                )
                .foregroundStyle(AppColors.success)
                .cornerRadius(4)

                // Pendientes
                SectorMark(
                    angle: .value("Pendientes", pendingHabits),
                    innerRadius: .ratio(0.6),
                    angularInset: 2
                )
                .foregroundStyle(AppColors.warning)
                .cornerRadius(4)
            }
            .frame(height: 200)
            .chartBackground { proxy in
                GeometryReader { geometry in
                    let frame = geometry[proxy.plotFrame!]
                    VStack(spacing: 4) {
                        Text("\(completionPercentage)%")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(AppColors.textPrimary)

                        Text("Completado")
                            .font(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .position(x: frame.midX, y: frame.midY)
                }
            }

            // Legend
            HStack(spacing: AppStyles.spacingLarge) {
                LegendItem(
                    color: AppColors.success,
                    label: "Completados",
                    value: "\(completedHabits)"
                )

                LegendItem(
                    color: AppColors.warning,
                    label: "Pendientes",
                    value: "\(pendingHabits)"
                )
            }
            .padding(.top, AppStyles.spacingSmall)
        }
        .padding(AppStyles.spacingLarge)
        .cardStyle(shadow: true)
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.7), value: animateCards)
    }

    // MARK: - Helper Views

    private func sectionHeader(title: String, icon: String, gradient: LinearGradient) -> some View {
        HStack(spacing: AppStyles.spacingSmall) {
            ZStack {
                Circle()
                    .fill(gradient)
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
            }

            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(AppColors.textPrimary)

            Spacer()
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.15), value: animateCards)
    }

    private func emptyStateCard(icon: String, title: String, message: String, gradient: LinearGradient) -> some View {
        VStack(spacing: AppStyles.spacingMedium) {
            ZStack {
                Circle()
                    .fill(gradient.opacity(0.2))
                    .frame(width: 60, height: 60)

                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundStyle(gradient)
            }

            VStack(spacing: AppStyles.spacingXSmall) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppColors.textPrimary)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppStyles.spacingLarge)
        .cardStyle(shadow: true)
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: animateCards)
    }

    // MARK: - Computed Properties

    private var completedHabits: Int {
        habits.filter(\.completed).count
    }

    private var pendingHabits: Int {
        habits.count - completedHabits
    }

    private var completionPercentage: Int {
        guard habits.count > 0 else { return 0 }
        return Int((Double(completedHabits) / Double(habits.count)) * 100)
    }

    private var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    private var averageExpense: Double {
        guard expenses.count > 0 else { return 0 }
        return totalExpenses / Double(expenses.count)
    }

    private var uniqueCategories: Int {
        Set(expenses.map(\.category)).count
    }

    private var expensesByCategory: [(category: String, amount: Double)] {
        Dictionary(grouping: expenses, by: \.category)
            .map { (category: $0.key, amount: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.amount > $1.amount }
    }

    // MARK: - Helper Functions

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "€0"
    }
}

// MARK: - Metric Card Component

private struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let gradient: LinearGradient
    let delay: Double

    @State private var animate = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppStyles.spacingSmall) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.white)

                Spacer()
            }

            Spacer()

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))

                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .padding(AppStyles.spacingMedium)
        .frame(height: 100)
        .background(gradient)
        .cornerRadius(AppStyles.cornerRadiusLarge)
        .shadow(color: AppStyles.shadowColor, radius: 8, x: 0, y: 4)
        .scaleEffect(animate ? 1 : 0.8)
        .opacity(animate ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(delay)) {
                animate = true
            }
        }
    }
}

// MARK: - Legend Item Component

private struct LegendItem: View {
    let color: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: AppStyles.spacingSmall) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(AppColors.textSecondary)

                Text(value)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DashboardView(
            habits: [
                Habit(id: UUID(), userID: UUID(), title: "Meditar", completed: true, createdAt: Date()),
                Habit(id: UUID(), userID: UUID(), title: "Ejercicio", completed: true, createdAt: Date()),
                Habit(id: UUID(), userID: UUID(), title: "Leer", completed: false, createdAt: Date()),
                Habit(id: UUID(), userID: UUID(), title: "Estudiar", completed: false, createdAt: Date())
            ],
            expenses: [
                Expense(id: UUID(), userID: UUID(), category: "Comida", amount: 45.50, createdAt: Date()),
                Expense(id: UUID(), userID: UUID(), category: "Transporte", amount: 30.00, createdAt: Date()),
                Expense(id: UUID(), userID: UUID(), category: "Comida", amount: 25.75, createdAt: Date()),
                Expense(id: UUID(), userID: UUID(), category: "Entretenimiento", amount: 60.00, createdAt: Date()),
                Expense(id: UUID(), userID: UUID(), category: "Salud", amount: 80.00, createdAt: Date())
            ]
        )
    }
}
