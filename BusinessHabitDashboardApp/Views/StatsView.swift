//
//  StatsView.swift
//  BusinessHabitDashboardApp
//
//  Created by Maria Bravo Angulo on 18/2/26.
//

import Charts
import SwiftUI

// MARK: - StatsView

/// Vista de estadísticas avanzadas con filtros por período.
/// Muestra métricas detalladas de hábitos y gastos con gráficos interactivos.
struct StatsView: View {
    @StateObject private var viewModel = StatsViewModel()

    let habits: [Habit]
    let expenses: [Expense]

    @State private var animateContent = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppStyles.spacingLarge) {
                // Selector de período
                periodSelector

                // Sección de hábitos
                habitStatsSection

                // Sección de gastos
                expenseStatsSection
            }
            .padding(AppStyles.spacingMedium)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("Estadísticas")
        .onAppear {
            // Propagar datos al ViewModel
            viewModel.habits = habits
            viewModel.expenses = expenses
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animateContent = true
            }
        }
        .onChange(of: habits) { _, newHabits in
            viewModel.habits = newHabits
        }
        .onChange(of: expenses) { _, newExpenses in
            viewModel.expenses = newExpenses
        }
    }

    // MARK: - Period Selector

    private var periodSelector: some View {
        VStack(alignment: .leading, spacing: AppStyles.spacingSmall) {
            Text("Período")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)

            HStack(spacing: AppStyles.spacingSmall) {
                ForEach(StatsPeriod.allCases) { period in
                    PeriodChip(
                        label: period.rawValue,
                        isSelected: viewModel.selectedPeriod == period
                    ) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            viewModel.selectedPeriod = period
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: animateContent)
    }

    // MARK: - Habits Stats Section

    private var habitStatsSection: some View {
        VStack(alignment: .leading, spacing: AppStyles.spacingMedium) {
            statsSectionHeader(
                title: "Hábitos",
                icon: "checkmark.circle.fill",
                gradient: AppColors.secondaryGradient,
                delay: 0.15
            )

            // Racha y mejor día (fila de métricas rápidas)
            HStack(spacing: AppStyles.spacingMedium) {
                streakCard
                bestDayCard
            }

            // Gráfico de barras: hábitos completados por día (últimos 7 días)
            habitsPerDayChart

            // Tasa de completación por hábito
            if !viewModel.habitsInPeriod.isEmpty {
                habitCompletionRatesSection
            }
        }
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        VStack(alignment: .leading, spacing: AppStyles.spacingXSmall) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                Spacer()
            }

            Spacer()

            VStack(alignment: .leading, spacing: 2) {
                Text("Racha actual")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(viewModel.currentStreak)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(viewModel.currentStreak == 1 ? "día" : "días")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .padding(AppStyles.spacingMedium)
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color(hex: "F59E0B"), Color(hex: "D97706")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(AppStyles.cornerRadiusLarge)
        .shadow(color: AppStyles.shadowColor, radius: 8, x: 0, y: 4)
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: animateContent)
    }

    // MARK: - Best Day Card

    private var bestDayCard: some View {
        VStack(alignment: .leading, spacing: AppStyles.spacingXSmall) {
            HStack {
                Image(systemName: "star.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                Spacer()
            }

            Spacer()

            VStack(alignment: .leading, spacing: 2) {
                Text("Mejor día")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))

                Text(viewModel.bestDayOfWeek)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(AppStyles.spacingMedium)
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        .background(AppColors.dashboardGradient)
        .cornerRadius(AppStyles.cornerRadiusLarge)
        .shadow(color: AppStyles.shadowColor, radius: 8, x: 0, y: 4)
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.25), value: animateContent)
    }

    // MARK: - Habits Per Day Chart

    private var habitsPerDayChart: some View {
        VStack(alignment: .leading, spacing: AppStyles.spacingMedium) {
            Text("Últimos 7 días")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)

            let data = viewModel.habitsPerDay
            let maxCount = max(1, data.map(\.count).max() ?? 1)

            if data.allSatisfy({ $0.count == 0 }) {
                emptyChartPlaceholder(
                    icon: "chart.bar",
                    message: "Completa hábitos para ver tu actividad diaria"
                )
            } else {
                Chart(data) { point in
                    BarMark(
                        x: .value("Día", point.dayLabel),
                        y: .value("Completados", point.count)
                    )
                    .foregroundStyle(
                        point.count > 0
                            ? AppColors.secondaryGradient
                            : LinearGradient(
                                colors: [AppColors.cardBackground, AppColors.cardBackground],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                    )
                    .cornerRadius(6)
                }
                .chartYScale(domain: 0...Double(maxCount + 1))
                .chartYAxis {
                    AxisMarks(values: .stride(by: 1)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(AppColors.textTertiary.opacity(0.3))
                        AxisValueLabel {
                            if let intVal = value.as(Int.self) {
                                Text("\(intVal)")
                                    .font(.caption2)
                                    .foregroundStyle(AppColors.textTertiary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let label = value.as(String.self) {
                                Text(label)
                                    .font(.caption2)
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                    }
                }
                .frame(height: 160)
            }
        }
        .padding(AppStyles.spacingLarge)
        .cardStyle(shadow: true)
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: animateContent)
    }

    // MARK: - Habit Completion Rates Section

    private var habitCompletionRatesSection: some View {
        VStack(alignment: .leading, spacing: AppStyles.spacingMedium) {
            Text("Tasa de completación")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)

            VStack(spacing: AppStyles.spacingSmall) {
                ForEach(Array(viewModel.habitCompletionRates.enumerated()), id: \.element.id) { index, item in
                    HabitRateRow(item: item, delay: 0.35 + Double(index) * 0.05)
                }
            }
        }
        .padding(AppStyles.spacingLarge)
        .cardStyle(shadow: true)
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.35), value: animateContent)
    }

    // MARK: - Expense Stats Section

    private var expenseStatsSection: some View {
        VStack(alignment: .leading, spacing: AppStyles.spacingMedium) {
            statsSectionHeader(
                title: "Gastos",
                icon: "eurosign.circle.fill",
                gradient: AppColors.accentGradient,
                delay: 0.4
            )

            // Comparativa vs período anterior
            expenseComparisonBanner

            if viewModel.expensesInPeriod.isEmpty {
                emptyStateCard(
                    icon: "eurosign.circle.fill",
                    title: "Sin gastos en este período",
                    message: "Registra gastos para ver las estadísticas"
                )
            } else {
                // Gráfico de dona: distribución por categoría
                categoryDistributionChart

                // Gráfico de línea: evolución temporal
                expenseTrendChart

                // Top 3 categorías
                topCategoriesSection
            }
        }
    }

    // MARK: - Expense Comparison Banner

    private var expenseComparisonBanner: some View {
        HStack(spacing: AppStyles.spacingMedium) {
            // Total del período actual
            VStack(alignment: .leading, spacing: 2) {
                Text("Período actual")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
                Text(formatCurrency(viewModel.totalInPeriod))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
            }

            Spacer()

            // Variación respecto al período anterior
            if let change = viewModel.expenseChangePercentage {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("vs período ant.")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)

                    HStack(spacing: 4) {
                        Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(change >= 0 ? AppColors.error : AppColors.success)

                        Text(String(format: "%.1f%%", abs(change)))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(change >= 0 ? AppColors.error : AppColors.success)
                    }
                }
            } else {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("vs período ant.")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    Text("Sin datos")
                        .font(.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
        }
        .padding(AppStyles.spacingMedium)
        .cardStyle(shadow: true)
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.45), value: animateContent)
    }

    // MARK: - Category Distribution Chart (Donut)

    private var categoryDistributionChart: some View {
        VStack(alignment: .leading, spacing: AppStyles.spacingMedium) {
            Text("Distribución por categoría")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)

            HStack(alignment: .center, spacing: AppStyles.spacingLarge) {
                // Gráfico de dona
                Chart(viewModel.expensesByCategory) { item in
                    SectorMark(
                        angle: .value("Monto", item.amount),
                        innerRadius: .ratio(0.58),
                        angularInset: 2.5
                    )
                    .foregroundStyle(by: .value("Categoría", item.category))
                    .cornerRadius(4)
                }
                .chartForegroundStyleScale(
                    domain: viewModel.expensesByCategory.map(\.category),
                    range: AppColors.chartColors
                )
                .chartLegend(.hidden)
                .frame(width: 140, height: 140)
                .chartBackground { proxy in
                    GeometryReader { geometry in
                        let frame = geometry[proxy.plotFrame!]
                        VStack(spacing: 2) {
                            Text(formatCurrency(viewModel.totalInPeriod))
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(AppColors.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                            Text("total")
                                .font(.caption2)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        .position(x: frame.midX, y: frame.midY)
                    }
                }

                // Leyenda de categorías
                VStack(alignment: .leading, spacing: AppStyles.spacingSmall) {
                    ForEach(Array(viewModel.expensesByCategory.enumerated()), id: \.element.id) { index, item in
                        HStack(spacing: AppStyles.spacingSmall) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(AppColors.chartColors[index % AppColors.chartColors.count])
                                .frame(width: 10, height: 10)

                            Text(item.category.capitalized)
                                .font(.caption)
                                .foregroundStyle(AppColors.textPrimary)
                                .lineLimit(1)

                            Spacer()

                            Text(String(format: "%.0f%%", item.percentage))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(AppStyles.spacingLarge)
        .cardStyle(shadow: true)
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5), value: animateContent)
    }

    // MARK: - Expense Trend Chart (Line)

    private var expenseTrendChart: some View {
        VStack(alignment: .leading, spacing: AppStyles.spacingMedium) {
            Text("Evolución del gasto")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)

            let data = viewModel.expensesOverTime

            if data.isEmpty || data.allSatisfy({ $0.amount == 0 }) {
                emptyChartPlaceholder(
                    icon: "chart.line.uptrend.xyaxis",
                    message: "No hay datos para mostrar la tendencia"
                )
            } else {
                Chart(data) { point in
                    // Área bajo la curva
                    AreaMark(
                        x: .value("Período", point.periodLabel),
                        y: .value("Gasto", point.amount)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hex: "0891B2").opacity(0.3),
                                Color(hex: "0891B2").opacity(0.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    // Línea principal
                    LineMark(
                        x: .value("Período", point.periodLabel),
                        y: .value("Gasto", point.amount)
                    )
                    .foregroundStyle(AppColors.accentGradient)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .interpolationMethod(.catmullRom)

                    // Punto en cada valor
                    PointMark(
                        x: .value("Período", point.periodLabel),
                        y: .value("Gasto", point.amount)
                    )
                    .foregroundStyle(Color(hex: "0891B2"))
                    .symbolSize(30)
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(AppColors.textTertiary.opacity(0.3))
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text(formatCurrencyShort(amount))
                                    .font(.caption2)
                                    .foregroundStyle(AppColors.textTertiary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisValueLabel {
                            if let label = value.as(String.self) {
                                Text(label)
                                    .font(.caption2)
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                    }
                }
                .frame(height: 160)
            }
        }
        .padding(AppStyles.spacingLarge)
        .cardStyle(shadow: true)
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.55), value: animateContent)
    }

    // MARK: - Top Categories Section

    private var topCategoriesSection: some View {
        VStack(alignment: .leading, spacing: AppStyles.spacingMedium) {
            Text("Top 3 categorías")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)

            VStack(spacing: AppStyles.spacingSmall) {
                ForEach(Array(viewModel.topThreeCategories.enumerated()), id: \.element.id) { index, item in
                    TopCategoryRow(
                        rank: index + 1,
                        category: item.category,
                        amount: formatCurrency(item.amount),
                        percentage: item.percentage,
                        color: AppColors.chartColors[index % AppColors.chartColors.count]
                    )
                }
            }
        }
        .padding(AppStyles.spacingLarge)
        .cardStyle(shadow: true)
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.6), value: animateContent)
    }

    // MARK: - Reusable Helper Views

    private func statsSectionHeader(
        title: String,
        icon: String,
        gradient: LinearGradient,
        delay: Double
    ) -> some View {
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
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(delay), value: animateContent)
    }

    private func emptyStateCard(icon: String, title: String, message: String) -> some View {
        VStack(spacing: AppStyles.spacingMedium) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(AppColors.textTertiary)

            VStack(spacing: AppStyles.spacingXSmall) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.textSecondary)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(AppColors.textTertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppStyles.spacingXLarge)
        .cardStyle(shadow: true)
    }

    private func emptyChartPlaceholder(icon: String, message: String) -> some View {
        VStack(spacing: AppStyles.spacingSmall) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(AppColors.textTertiary)
            Text(message)
                .font(.caption)
                .foregroundStyle(AppColors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
    }

    // MARK: - Formatting Helpers

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "€0"
    }

    /// Formato compacto para ejes de gráficos (€1.2k en lugar de €1.200)
    private func formatCurrencyShort(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "€%.1fk", value / 1000)
        }
        return String(format: "€%.0f", value)
    }
}

// MARK: - Period Chip

private struct PeriodChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(isSelected ? .bold : .regular))
                .foregroundStyle(isSelected ? .white : AppColors.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Group {
                        if isSelected {
                            AppColors.primaryGradient
                        } else {
                            AppColors.cardBackground
                        }
                    }
                )
                .cornerRadius(AppStyles.cornerRadiusMedium)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Habit Rate Row

private struct HabitRateRow: View {
    let item: HabitCompletionRate
    let delay: Double

    @State private var showBar = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.title)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)

                Spacer()

                Text(completed ? "Completado" : "Pendiente")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(completed ? AppColors.success : AppColors.textTertiary)
            }

            // Barra de progreso animada
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppColors.cardBackground)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(completed ? AppColors.secondaryGradient : LinearGradient(
                            colors: [AppColors.warning, AppColors.warning],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: showBar ? geometry.size.width * CGFloat(item.rate) : 0, height: 6)
                        .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(delay), value: showBar)
                }
            }
            .frame(height: 6)
        }
        .onAppear {
            showBar = true
        }
    }

    private var completed: Bool {
        item.rate > 0
    }
}

// MARK: - Top Category Row

private struct TopCategoryRow: View {
    let rank: Int
    let category: String
    let amount: String
    let percentage: Double
    let color: Color

    var body: some View {
        HStack(spacing: AppStyles.spacingMedium) {
            // Ranking badge
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)

                Text("#\(rank)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(color)
            }

            // Categoría
            VStack(alignment: .leading, spacing: 2) {
                Text(category.capitalized)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)

                Text(String(format: "%.0f%% del total", percentage))
                    .font(.caption2)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            // Monto
            Text(amount)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppColors.textPrimary)
        }
        .padding(AppStyles.spacingSmall)
        .background(AppColors.secondaryBackground)
        .cornerRadius(AppStyles.cornerRadiusMedium)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        StatsView(
            habits: [
                Habit(id: UUID(), userID: UUID(), title: "Meditar", completed: true, createdAt: Date()),
                Habit(id: UUID(), userID: UUID(), title: "Ejercicio", completed: false,
                      createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()),
                Habit(id: UUID(), userID: UUID(), title: "Leer", completed: true,
                      createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()),
                Habit(id: UUID(), userID: UUID(), title: "Estudiar", completed: true,
                      createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date())
            ],
            expenses: [
                Expense(id: UUID(), userID: UUID(), category: "Comida", amount: 150.0, createdAt: Date()),
                Expense(id: UUID(), userID: UUID(), category: "Transporte", amount: 80.0, createdAt: Date()),
                Expense(id: UUID(), userID: UUID(), category: "Entretenimiento", amount: 60.0,
                        createdAt: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date()),
                Expense(id: UUID(), userID: UUID(), category: "Salud", amount: 120.0,
                        createdAt: Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date()),
                Expense(id: UUID(), userID: UUID(), category: "Comida", amount: 45.0,
                        createdAt: Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date())
            ]
        )
    }
}
