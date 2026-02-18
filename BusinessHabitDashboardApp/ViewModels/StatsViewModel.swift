//
//  StatsViewModel.swift
//  BusinessHabitDashboardApp
//
//  Created by Maria Bravo Angulo on 18/2/26.
//

import Combine
import Foundation
import SwiftUI

// MARK: - Period Selector

/// Períodos de tiempo disponibles para filtrar estadísticas
enum StatsPeriod: String, CaseIterable, Identifiable {
    case week = "Esta semana"
    case month = "Este mes"
    case threeMonths = "3 meses"
    case year = "Este año"

    var id: String { rawValue }

    /// Devuelve la fecha de inicio del período actual
    var startDate: Date {
        let calendar = Calendar.current
        let now = Date()
        switch self {
        case .week:
            return calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        case .month:
            return calendar.dateInterval(of: .month, for: now)?.start ?? now
        case .threeMonths:
            return calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .year:
            return calendar.dateInterval(of: .year, for: now)?.start ?? now
        }
    }

    /// Devuelve la fecha de inicio del período anterior (para comparativas)
    var previousPeriodStartDate: Date {
        let calendar = Calendar.current
        switch self {
        case .week:
            return calendar.date(byAdding: .weekOfYear, value: -1, to: startDate) ?? startDate
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: startDate) ?? startDate
        case .threeMonths:
            return calendar.date(byAdding: .month, value: -3, to: startDate) ?? startDate
        case .year:
            return calendar.date(byAdding: .year, value: -1, to: startDate) ?? startDate
        }
    }
}

// MARK: - Data Structs for Charts

/// Punto de dato para gráfico de barras de hábitos por día
struct HabitDayData: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
    let dayLabel: String
}

/// Punto de dato para la evolución de gastos en el tiempo
struct ExpenseTimePoint: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
    let periodLabel: String
}

/// Tasa de completación de un hábito individual
struct HabitCompletionRate: Identifiable {
    let id: UUID
    let title: String
    let rate: Double    // 0.0 - 1.0
    let completedDays: Int
    let totalDays: Int
}

/// Categoría con su total de gasto
struct CategoryExpense: Identifiable {
    let id = UUID()
    let category: String
    let amount: Double
    let percentage: Double
}

// MARK: - StatsViewModel

/// ViewModel dedicado a las estadísticas avanzadas.
/// Recibe los datos de HabitViewModel y ExpenseViewModel y calcula métricas.
@MainActor
final class StatsViewModel: ObservableObject {

    // MARK: - Input Data (updated externally)
    @Published var habits: [Habit] = []
    @Published var expenses: [Expense] = []

    // MARK: - Period Selection
    @Published var selectedPeriod: StatsPeriod = .month

    // MARK: - Derived: Filtered Data

    /// Hábitos dentro del período seleccionado (por createdAt)
    var habitsInPeriod: [Habit] {
        habits.filter { $0.createdAt >= selectedPeriod.startDate }
    }

    /// Gastos dentro del período seleccionado
    var expensesInPeriod: [Expense] {
        expenses.filter { $0.createdAt >= selectedPeriod.startDate }
    }

    /// Gastos del período anterior (para comparativa)
    var expensesInPreviousPeriod: [Expense] {
        let start = selectedPeriod.previousPeriodStartDate
        let end = selectedPeriod.startDate
        return expenses.filter { $0.createdAt >= start && $0.createdAt < end }
    }

    // MARK: - Habit Stats

    /// Datos de hábitos completados por día (últimos 7 días)
    var habitsPerDay: [HabitDayData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var result: [HabitDayData] = []

        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let nextDay = calendar.date(byAdding: .day, value: 1, to: date) ?? date

            // Contar hábitos creados ese día que estén completados
            // (usamos createdAt como proxy de actividad del día)
            let completedCount = habits.filter { habit in
                habit.completed &&
                habit.createdAt >= date &&
                habit.createdAt < nextDay
            }.count

            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            formatter.locale = Locale(identifier: "es_ES")
            let label = formatter.string(from: date).capitalized

            result.append(HabitDayData(date: date, count: completedCount, dayLabel: label))
        }

        return result
    }

    /// Racha actual: días consecutivos (hacia atrás desde hoy) con al menos 1 hábito completado.
    /// Usa el campo `completed` como indicador de actividad reciente.
    var currentStreak: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Obtener todos los días únicos con hábitos completados
        let completedDays: Set<Date> = Set(
            habits.filter(\.completed).compactMap { habit in
                calendar.startOfDay(for: habit.createdAt)
            }
        )

        var streak = 0
        var checkDate = today

        // Verificar día de hoy primero; si no hay actividad hoy, empezar desde ayer
        if !completedDays.contains(checkDate) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) else { return 0 }
            checkDate = yesterday
        }

        while completedDays.contains(checkDate) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
        }

        return streak
    }

    /// Tasa de completación por hábito en el período.
    /// Calcula el % de días desde la creación del hábito hasta hoy en que estuvo "activo".
    var habitCompletionRates: [HabitCompletionRate] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let periodStart = selectedPeriod.startDate

        return habitsInPeriod.map { habit in
            // Días desde que el hábito fue creado (o inicio del período) hasta hoy
            let effectiveStart = max(calendar.startOfDay(for: habit.createdAt), calendar.startOfDay(for: periodStart))
            let totalDays = max(1, calendar.dateComponents([.day], from: effectiveStart, to: today).day ?? 1)

            // Si el hábito está completado, contamos 1 día completado como mínimo
            // (dado que no tenemos historial completo, este es el dato disponible)
            let completedDays = habit.completed ? 1 : 0
            let rate = Double(completedDays) / Double(totalDays)

            return HabitCompletionRate(
                id: habit.id,
                title: habit.title,
                rate: min(rate, 1.0),
                completedDays: completedDays,
                totalDays: totalDays
            )
        }
        .sorted { $0.rate > $1.rate }
    }

    /// Mejor día de la semana: el que acumula más hábitos completados.
    var bestDayOfWeek: String {
        let calendar = Calendar.current
        let completedHabits = habits.filter(\.completed)
        guard !completedHabits.isEmpty else { return "—" }

        // Contar hábitos por día de la semana (1=Dom, 2=Lun, ..., 7=Sáb)
        var countsByWeekday: [Int: Int] = [:]
        for habit in completedHabits {
            let weekday = calendar.component(.weekday, from: habit.createdAt)
            countsByWeekday[weekday, default: 0] += 1
        }

        guard let bestWeekday = countsByWeekday.max(by: { $0.value < $1.value })?.key else { return "—" }

        let dayNames = ["", "Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"]
        return dayNames[bestWeekday]
    }

    // MARK: - Expense Stats

    /// Total gastado en el período seleccionado
    var totalInPeriod: Double {
        expensesInPeriod.reduce(0) { $0 + $1.amount }
    }

    /// Total gastado en el período anterior
    var totalInPreviousPeriod: Double {
        expensesInPreviousPeriod.reduce(0) { $0 + $1.amount }
    }

    /// Variación porcentual respecto al período anterior.
    /// Positivo = gasto mayor, negativo = gasto menor.
    var expenseChangePercentage: Double? {
        guard totalInPreviousPeriod > 0 else { return nil }
        return ((totalInPeriod - totalInPreviousPeriod) / totalInPreviousPeriod) * 100
    }

    /// Gastos agrupados y ponderados por categoría en el período
    var expensesByCategory: [CategoryExpense] {
        let total = totalInPeriod
        guard total > 0 else { return [] }

        let grouped = Dictionary(grouping: expensesInPeriod, by: \.category)
        return grouped.map { category, items in
            let amount = items.reduce(0) { $0 + $1.amount }
            return CategoryExpense(
                category: category,
                amount: amount,
                percentage: (amount / total) * 100
            )
        }
        .sorted { $0.amount > $1.amount }
    }

    /// Top 3 categorías de gasto
    var topThreeCategories: [CategoryExpense] {
        Array(expensesByCategory.prefix(3))
    }

    /// Evolución del gasto agrupado por día o semana según el período.
    var expensesOverTime: [ExpenseTimePoint] {
        let calendar = Calendar.current
        let periodStart = selectedPeriod.startDate

        switch selectedPeriod {
        case .week:
            // Agrupar por día (7 puntos)
            return groupExpensesByDay(from: periodStart, count: 7, calendar: calendar)
        case .month:
            // Agrupar por semana dentro del mes (4-5 puntos)
            return groupExpensesByWeek(from: periodStart, calendar: calendar)
        case .threeMonths:
            // Agrupar por semana (12-13 semanas)
            return groupExpensesByWeek(from: periodStart, calendar: calendar)
        case .year:
            // Agrupar por mes (12 puntos)
            return groupExpensesByMonth(from: periodStart, count: 12, calendar: calendar)
        }
    }

    // MARK: - Private Grouping Helpers

    private func groupExpensesByDay(from start: Date, count: Int, calendar: Calendar) -> [ExpenseTimePoint] {
        let dayStart = calendar.startOfDay(for: start)
        let formatter = DateFormatter()
        formatter.dateFormat = "d/M"

        return (0..<count).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: dayStart),
                  date <= Date() else { return nil }
            let nextDate = calendar.date(byAdding: .day, value: 1, to: date) ?? date
            let total = expensesInPeriod
                .filter { $0.createdAt >= date && $0.createdAt < nextDate }
                .reduce(0) { $0 + $1.amount }
            return ExpenseTimePoint(date: date, amount: total, periodLabel: formatter.string(from: date))
        }
    }

    private func groupExpensesByWeek(from start: Date, calendar: Calendar) -> [ExpenseTimePoint] {
        var result: [ExpenseTimePoint] = []
        var current = calendar.startOfDay(for: start)
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "d/M"

        while current <= now {
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: current) ?? current
            let total = expensesInPeriod
                .filter { $0.createdAt >= current && $0.createdAt < weekEnd }
                .reduce(0) { $0 + $1.amount }
            result.append(ExpenseTimePoint(date: current, amount: total, periodLabel: formatter.string(from: current)))
            current = weekEnd
        }

        return result
    }

    private func groupExpensesByMonth(from start: Date, count: Int, calendar: Calendar) -> [ExpenseTimePoint] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        formatter.locale = Locale(identifier: "es_ES")

        return (0..<count).compactMap { offset in
            guard let date = calendar.date(byAdding: .month, value: offset, to: start),
                  date <= Date() else { return nil }
            let nextDate = calendar.date(byAdding: .month, value: 1, to: date) ?? date
            let total = expenses
                .filter { $0.createdAt >= date && $0.createdAt < nextDate }
                .reduce(0) { $0 + $1.amount }
            let label = formatter.string(from: date).capitalized
            return ExpenseTimePoint(date: date, amount: total, periodLabel: label)
        }
    }
}
