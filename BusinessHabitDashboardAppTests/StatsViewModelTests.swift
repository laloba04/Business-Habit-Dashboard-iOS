//
//  StatsViewModelTests.swift
//  BusinessHabitDashboardAppTests
//
//  Tests unitarios de StatsViewModel.
//  Todos los cálculos son pure functions sobre arrays; no se necesita red.
//
//  Nota: StatsViewModel está anotado con @MainActor, por lo que los tests
//  que acceden a él deben ejecutarse en el actor principal. Se usa
//  `MainActor.run { }` dentro de métodos `async` de XCTest.
//

import XCTest
@testable import BusinessHabitDashboardApp

final class StatsViewModelTests: XCTestCase {

    // MARK: - Helpers

    private let userID = UUID()

    /// Crea un hábito con fecha relativa a hoy (offset en días; negativo = pasado).
    private func makeHabit(
        daysAgo: Int = 0,
        completed: Bool = true,
        title: String = "Hábito test"
    ) -> Habit {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        return Habit(
            id: UUID(),
            userID: userID,
            title: title,
            completed: completed,
            createdAt: date
        )
    }

    /// Crea un gasto con fecha relativa a hoy.
    private func makeExpense(
        daysAgo: Int = 0,
        amount: Double = 10.0,
        category: String = "Otros"
    ) -> Expense {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        return Expense(
            id: UUID(),
            userID: userID,
            category: category,
            amount: amount,
            createdAt: date
        )
    }

    // MARK: - Progreso (completados / total)

    func testProgressCalculation() async {
        await MainActor.run {
            let vm = StatsViewModel()

            // 3 hábitos, 2 completados
            vm.habits = [
                makeHabit(completed: true),
                makeHabit(completed: true),
                makeHabit(completed: false)
            ]

            let completedCount = vm.habits.filter(\.completed).count
            let totalCount = vm.habits.count

            XCTAssertEqual(completedCount, 2)
            XCTAssertEqual(totalCount, 3)

            let progress = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0
            XCTAssertEqual(progress, 2.0 / 3.0, accuracy: 0.001)
        }
    }

    func testProgressCalculationAllCompleted() async {
        await MainActor.run {
            let vm = StatsViewModel()
            vm.habits = [
                makeHabit(completed: true),
                makeHabit(completed: true)
            ]

            let completed = vm.habits.filter(\.completed).count
            XCTAssertEqual(completed, 2)
            XCTAssertEqual(vm.habits.count, 2)
        }
    }

    func testProgressCalculationNoneCompleted() async {
        await MainActor.run {
            let vm = StatsViewModel()
            vm.habits = [
                makeHabit(completed: false),
                makeHabit(completed: false)
            ]

            let completed = vm.habits.filter(\.completed).count
            XCTAssertEqual(completed, 0)
        }
    }

    // MARK: - Racha actual (currentStreak)

    func testCurrentStreakWithHabitsCompletedTodayAndYesterday() async {
        await MainActor.run {
            let vm = StatsViewModel()

            // Hábitos completados hoy y ayer: racha de al menos 2
            vm.habits = [
                makeHabit(daysAgo: 0, completed: true), // hoy
                makeHabit(daysAgo: 1, completed: true)  // ayer
            ]

            XCTAssertGreaterThanOrEqual(vm.currentStreak, 2)
        }
    }

    func testCurrentStreakIsZeroWithNoCompletedHabits() async {
        await MainActor.run {
            let vm = StatsViewModel()
            vm.habits = [
                makeHabit(daysAgo: 0, completed: false),
                makeHabit(daysAgo: 1, completed: false)
            ]

            XCTAssertEqual(vm.currentStreak, 0)
        }
    }

    func testCurrentStreakIsZeroWithEmptyHabits() async {
        await MainActor.run {
            let vm = StatsViewModel()
            vm.habits = []

            XCTAssertEqual(vm.currentStreak, 0)
        }
    }

    func testCurrentStreakBreaksWhenGapExists() async {
        await MainActor.run {
            let vm = StatsViewModel()

            // Completado hace 3 días pero no ayer ni hoy — racha rota
            vm.habits = [
                makeHabit(daysAgo: 3, completed: true)
            ]

            // La racha desde hoy es 0 (hoy y ayer no tienen actividad)
            XCTAssertEqual(vm.currentStreak, 0)
        }
    }

    func testCurrentStreakConsecutiveThreeDays() async {
        await MainActor.run {
            let vm = StatsViewModel()

            vm.habits = [
                makeHabit(daysAgo: 0, completed: true), // hoy
                makeHabit(daysAgo: 1, completed: true), // ayer
                makeHabit(daysAgo: 2, completed: true)  // anteayer
            ]

            XCTAssertGreaterThanOrEqual(vm.currentStreak, 3)
        }
    }

    // MARK: - Mejor día de la semana (bestDayOfWeek)

    func testBestDayOfWeekWithNoHabits() async {
        await MainActor.run {
            let vm = StatsViewModel()
            vm.habits = []

            XCTAssertEqual(vm.bestDayOfWeek, "—")
        }
    }

    func testBestDayOfWeekWithNoCompletedHabits() async {
        await MainActor.run {
            let vm = StatsViewModel()
            vm.habits = [makeHabit(completed: false)]

            XCTAssertEqual(vm.bestDayOfWeek, "—")
        }
    }

    func testBestDayOfWeekReturnsSpanishDayName() async {
        await MainActor.run {
            let vm = StatsViewModel()

            // Al menos un hábito completado → debe devolver un nombre de día en español
            vm.habits = [makeHabit(daysAgo: 0, completed: true)]

            let validDays = ["Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"]
            XCTAssertTrue(validDays.contains(vm.bestDayOfWeek),
                "bestDayOfWeek debería ser un día en español, pero fue: \(vm.bestDayOfWeek)")
        }
    }

    // MARK: - Gastos por categoría (expensesByCategory)

    func testExpensesByCategoryGroupsCorrectly() async {
        await MainActor.run {
            let vm = StatsViewModel()
            vm.selectedPeriod = .year // período amplio para incluir todos los gastos de prueba

            vm.expenses = [
                makeExpense(daysAgo: 1, amount: 30, category: "Alimentación"),
                makeExpense(daysAgo: 2, amount: 20, category: "Alimentación"),
                makeExpense(daysAgo: 3, amount: 50, category: "Transporte")
            ]

            let categories = vm.expensesByCategory

            // Deben aparecer exactamente 2 categorías
            XCTAssertEqual(categories.count, 2)

            // Alimentación: 50, Transporte: 50 → mismos totales; ambos deben estar presentes
            let categoryNames = categories.map(\.category)
            XCTAssertTrue(categoryNames.contains("Alimentación"))
            XCTAssertTrue(categoryNames.contains("Transporte"))
        }
    }

    func testExpensesByCategoryAmountsAreCorrect() async {
        await MainActor.run {
            let vm = StatsViewModel()
            vm.selectedPeriod = .year

            vm.expenses = [
                makeExpense(daysAgo: 1, amount: 40, category: "Salud"),
                makeExpense(daysAgo: 2, amount: 60, category: "Ocio")
            ]

            let categories = vm.expensesByCategory

            let salud = categories.first(where: { $0.category == "Salud" })
            let ocio  = categories.first(where: { $0.category == "Ocio" })

            XCTAssertNotNil(salud)
            XCTAssertNotNil(ocio)
            XCTAssertEqual(salud!.amount, 40, accuracy: 0.001)
            XCTAssertEqual(ocio!.amount,  60, accuracy: 0.001)
        }
    }

    func testExpensesByCategoryPercentagesSumTo100() async {
        await MainActor.run {
            let vm = StatsViewModel()
            vm.selectedPeriod = .year

            vm.expenses = [
                makeExpense(daysAgo: 1, amount: 25, category: "A"),
                makeExpense(daysAgo: 2, amount: 75, category: "B")
            ]

            let categories = vm.expensesByCategory
            let totalPercentage = categories.reduce(0) { $0 + $1.percentage }
            XCTAssertEqual(totalPercentage, 100.0, accuracy: 0.001)
        }
    }

    func testExpensesByCategoryEmptyWhenNoExpenses() async {
        await MainActor.run {
            let vm = StatsViewModel()
            vm.expenses = []

            XCTAssertTrue(vm.expensesByCategory.isEmpty)
        }
    }

    func testExpensesByCategorySortedByAmountDescending() async {
        await MainActor.run {
            let vm = StatsViewModel()
            vm.selectedPeriod = .year

            vm.expenses = [
                makeExpense(daysAgo: 1, amount: 10, category: "Pequeño"),
                makeExpense(daysAgo: 2, amount: 100, category: "Grande"),
                makeExpense(daysAgo: 3, amount: 50, category: "Mediano")
            ]

            let categories = vm.expensesByCategory
            XCTAssertEqual(categories.first?.category, "Grande")
            XCTAssertEqual(categories.last?.category, "Pequeño")
        }
    }

    // MARK: - Variación porcentual (expenseChangePercentage)

    func testExpenseChangePercentageIsNilWhenNoPreviousPeriod() async {
        await MainActor.run {
            let vm = StatsViewModel()
            vm.selectedPeriod = .month

            // Solo gastos en el período actual, ninguno en el anterior
            vm.expenses = [makeExpense(daysAgo: 1, amount: 100)]

            XCTAssertNil(vm.expenseChangePercentage)
        }
    }

    func testExpenseChangePercentagePositiveWhenCurrentIsHigher() async {
        await MainActor.run {
            let vm = StatsViewModel()
            vm.selectedPeriod = .month

            // Período actual: 200. Período anterior: 100. Cambio esperado: +100%.
            let calendar = Calendar.current
            let periodStart = StatsPeriod.month.startDate
            let previousStart = StatsPeriod.month.previousPeriodStartDate

            // Gasto en el período actual (1 día atrás, dentro del mes)
            let currentDate = calendar.date(byAdding: .day, value: 1, to: periodStart)!
            let currentExpense = Expense(
                id: UUID(), userID: userID,
                category: "Test", amount: 200,
                createdAt: currentDate
            )

            // Gasto en el período anterior (1 día después de su inicio)
            let previousDate = calendar.date(byAdding: .day, value: 1, to: previousStart)!
            let previousExpense = Expense(
                id: UUID(), userID: userID,
                category: "Test", amount: 100,
                createdAt: previousDate
            )

            vm.expenses = [currentExpense, previousExpense]

            if let pct = vm.expenseChangePercentage {
                XCTAssertGreaterThan(pct, 0)
                XCTAssertEqual(pct, 100.0, accuracy: 0.1)
            } else {
                XCTFail("expenseChangePercentage no debería ser nil cuando hay gastos en ambos períodos")
            }
        }
    }

    func testExpenseChangePercentageNegativeWhenCurrentIsLower() async {
        await MainActor.run {
            let vm = StatsViewModel()
            vm.selectedPeriod = .month

            let calendar = Calendar.current
            let periodStart = StatsPeriod.month.startDate
            let previousStart = StatsPeriod.month.previousPeriodStartDate

            // Actual: 50. Anterior: 100. Cambio esperado: -50%.
            let currentDate  = calendar.date(byAdding: .day, value: 1, to: periodStart)!
            let previousDate = calendar.date(byAdding: .day, value: 1, to: previousStart)!

            vm.expenses = [
                Expense(id: UUID(), userID: userID, category: "Test", amount: 50,  createdAt: currentDate),
                Expense(id: UUID(), userID: userID, category: "Test", amount: 100, createdAt: previousDate)
            ]

            if let pct = vm.expenseChangePercentage {
                XCTAssertLessThan(pct, 0)
                XCTAssertEqual(pct, -50.0, accuracy: 0.1)
            } else {
                XCTFail("expenseChangePercentage no debería ser nil cuando hay gastos en ambos períodos")
            }
        }
    }

    // MARK: - Tasas de completación por hábito (habitCompletionRates)

    func testHabitCompletionRatesCompletedHabitHasRateGreaterThanZero() async {
        await MainActor.run {
            let vm = StatsViewModel()
            vm.selectedPeriod = .month

            let periodStart = StatsPeriod.month.startDate
            let calendar = Calendar.current

            // Hábito creado dentro del período actual
            let habitDate = calendar.date(byAdding: .day, value: 1, to: periodStart)!
            let completedHabit = Habit(
                id: UUID(), userID: userID,
                title: "Completado", completed: true,
                createdAt: habitDate
            )

            vm.habits = [completedHabit]

            let rates = vm.habitCompletionRates
            XCTAssertEqual(rates.count, 1)

            let rate = rates.first!
            XCTAssertGreaterThan(rate.rate, 0)
            XCTAssertEqual(rate.completedDays, 1)
            XCTAssertEqual(rate.title, "Completado")
        }
    }

    func testHabitCompletionRatesIncompleteHabitHasRateZero() async {
        await MainActor.run {
            let vm = StatsViewModel()
            vm.selectedPeriod = .month

            let periodStart = StatsPeriod.month.startDate
            let calendar = Calendar.current
            let habitDate = calendar.date(byAdding: .day, value: 1, to: periodStart)!

            let pendingHabit = Habit(
                id: UUID(), userID: userID,
                title: "Pendiente", completed: false,
                createdAt: habitDate
            )

            vm.habits = [pendingHabit]

            let rates = vm.habitCompletionRates
            XCTAssertEqual(rates.count, 1)

            let rate = rates.first!
            XCTAssertEqual(rate.rate, 0.0, accuracy: 0.001)
            XCTAssertEqual(rate.completedDays, 0)
        }
    }

    func testHabitCompletionRatesSortedByRateDescending() async {
        await MainActor.run {
            let vm = StatsViewModel()
            vm.selectedPeriod = .month

            let periodStart = StatsPeriod.month.startDate
            let calendar = Calendar.current
            let habitDate = calendar.date(byAdding: .day, value: 1, to: periodStart)!

            let completed = Habit(
                id: UUID(), userID: userID,
                title: "Primero", completed: true, createdAt: habitDate
            )
            let pending = Habit(
                id: UUID(), userID: userID,
                title: "Segundo", completed: false, createdAt: habitDate
            )

            vm.habits = [pending, completed] // orden inverso intencionado

            let rates = vm.habitCompletionRates

            // El completado debe aparecer primero (mayor rate)
            XCTAssertEqual(rates.first?.title, "Primero")
        }
    }

    func testHabitCompletionRatesRateIsCappedAtOne() async {
        await MainActor.run {
            let vm = StatsViewModel()
            vm.selectedPeriod = .month

            let periodStart = StatsPeriod.month.startDate
            let calendar = Calendar.current
            // Creado exactamente en el inicio del período (totalDays=1 o muy bajo → rate podría ser >1 sin cap)
            let habitDate = calendar.date(byAdding: .day, value: 1, to: periodStart)!

            let habit = Habit(
                id: UUID(), userID: userID,
                title: "Cap test", completed: true, createdAt: habitDate
            )
            vm.habits = [habit]

            let rates = vm.habitCompletionRates
            if let rate = rates.first {
                XCTAssertLessThanOrEqual(rate.rate, 1.0)
            }
        }
    }

    func testHabitCompletionRatesEmptyWhenNoHabitsInPeriod() async {
        await MainActor.run {
            let vm = StatsViewModel()
            vm.selectedPeriod = .week

            // Hábito creado hace 60 días, fuera del período de esta semana
            let oldDate = Calendar.current.date(byAdding: .day, value: -60, to: Date())!
            let oldHabit = Habit(
                id: UUID(), userID: userID,
                title: "Viejo", completed: true, createdAt: oldDate
            )
            vm.habits = [oldHabit]

            // habitsInPeriod filtra por createdAt >= startDate de la semana, así que no debe incluirlo
            XCTAssertTrue(vm.habitCompletionRates.isEmpty)
        }
    }
}
