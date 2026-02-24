//
//  ExportServiceTests.swift
//  BusinessHabitDashboardAppTests
//
//  Tests unitarios de ExportService.
//  Verifican que los archivos CSV se generan, tienen las cabeceras correctas
//  y el contenido respeta el formato esperado.
//
//  No se necesita red: ExportService solo escribe en el directorio temporal del sistema.
//

import XCTest
@testable import BusinessHabitDashboardApp

final class ExportServiceTests: XCTestCase {

    // MARK: - Propiedades

    private let service = ExportService.shared
    private let userID  = UUID()

    // MARK: - Helpers de fixtures

    private func makeHabit(
        title: String = "Hábito test",
        completed: Bool = true,
        reminderEnabled: Bool? = nil,
        reminderDays: [Int]? = nil
    ) -> Habit {
        Habit(
            id: UUID(),
            userID: userID,
            title: title,
            completed: completed,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            reminderEnabled: reminderEnabled,
            reminderTime: reminderEnabled == true ? Date(timeIntervalSince1970: 1_700_000_000) : nil,
            reminderDays: reminderDays
        )
    }

    private func makeExpense(
        category: String = "Alimentación",
        amount: Double = 25.00
    ) -> Expense {
        Expense(
            id: UUID(),
            userID: userID,
            category: category,
            amount: amount,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }

    /// Lee el contenido de texto del archivo generado.
    private func readCSV(at url: URL) throws -> String {
        try String(contentsOf: url, encoding: .utf8)
    }

    // MARK: - exportHabits

    func testExportHabitsGeneratesFile() throws {
        let habits = [makeHabit(title: "Correr")]
        let url = try service.exportHabits(habits)

        // El archivo debe existir en disco
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path),
            "Se esperaba encontrar el archivo CSV en: \(url.path)")
    }

    func testExportHabitsFileHasCSVExtension() throws {
        let url = try service.exportHabits([makeHabit()])
        XCTAssertEqual(url.pathExtension, "csv")
    }

    func testExportHabitsContent() throws {
        let habits = [makeHabit(title: "Meditar")]
        let url    = try service.exportHabits(habits)
        let csv    = try readCSV(at: url)

        // La primera línea debe ser la cabecera exacta
        let firstLine = csv.components(separatedBy: "\n").first ?? ""
        XCTAssertEqual(firstLine, "ID,Título,Completado,Fecha creación,Recordatorio activo,Días recordatorio")
    }

    func testExportHabitsHasOneDataRowPerHabit() throws {
        let habits = [makeHabit(title: "A"), makeHabit(title: "B"), makeHabit(title: "C")]
        let url    = try service.exportHabits(habits)
        let csv    = try readCSV(at: url)

        // Líneas = cabecera + N filas (ignorar línea vacía final si existe)
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }
        XCTAssertEqual(lines.count, 1 + habits.count,
            "Se esperaban \(1 + habits.count) líneas, se encontraron \(lines.count)")
    }

    func testExportHabitsCompletedFieldUsesSpanish() throws {
        let completedHabit = makeHabit(title: "Sí", completed: true)
        let pendingHabit   = makeHabit(title: "No", completed: false)
        let url = try service.exportHabits([completedHabit, pendingHabit])
        let csv = try readCSV(at: url)

        XCTAssertTrue(csv.contains(",Sí,"), "El campo 'completado' para hábito completado debe ser 'Sí'")
        XCTAssertTrue(csv.contains(",No,"), "El campo 'completado' para hábito pendiente debe ser 'No'")
    }

    func testExportHabitsTitleWithCommaIsEscaped() throws {
        // Un título con coma debe envolverse en comillas dobles (RFC 4180)
        let habit = makeHabit(title: "Correr, nadar")
        let url   = try service.exportHabits([habit])
        let csv   = try readCSV(at: url)

        XCTAssertTrue(csv.contains("\"Correr, nadar\""),
            "Los títulos con coma deben estar entre comillas dobles en el CSV")
    }

    func testExportHabitsTitleWithQuoteIsDoubleEscaped() throws {
        // Una comilla doble en el título debe convertirse en dos comillas dobles
        let habit = makeHabit(title: "El \"mejor\" hábito")
        let url   = try service.exportHabits([habit])
        let csv   = try readCSV(at: url)

        XCTAssertTrue(csv.contains("\"El \"\"mejor\"\" hábito\""),
            "Las comillas dentro de un campo CSV deben duplicarse")
    }

    func testExportHabitsWithReminderDays() throws {
        let habit = makeHabit(
            title: "Yoga",
            completed: true,
            reminderEnabled: true,
            reminderDays: [1, 3, 5] // Lun, Mié, Vie
        )
        let url = try service.exportHabits([habit])
        let csv = try readCSV(at: url)

        // Los días deben aparecer como nombres abreviados en español
        XCTAssertTrue(csv.contains("Lun"), "El CSV debe incluir el abreviado del día 'Lun'")
        XCTAssertTrue(csv.contains("Mié"), "El CSV debe incluir el abreviado del día 'Mié'")
        XCTAssertTrue(csv.contains("Vie"), "El CSV debe incluir el abreviado del día 'Vie'")
    }

    func testExportHabitsEmptyList() throws {
        let url = try service.exportHabits([])
        let csv = try readCSV(at: url)

        // Solo debe haber la cabecera
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }
        XCTAssertEqual(lines.count, 1, "Un CSV vacío debe tener solo la línea de cabecera")
    }

    // MARK: - exportExpenses

    func testExportExpensesGeneratesFile() throws {
        let expenses = [makeExpense(category: "Transporte", amount: 15.50)]
        let url      = try service.exportExpenses(expenses)

        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    func testExportExpensesContent() throws {
        let url    = try service.exportExpenses([makeExpense()])
        let csv    = try readCSV(at: url)
        let firstLine = csv.components(separatedBy: "\n").first ?? ""

        // La cabecera debe ser exactamente la esperada
        XCTAssertEqual(firstLine, "ID,Monto,Categoría,Fecha")
    }

    func testExportExpensesHasOneDataRowPerExpense() throws {
        let expenses = [
            makeExpense(category: "Salud", amount: 30),
            makeExpense(category: "Ocio",  amount: 80)
        ]
        let url  = try service.exportExpenses(expenses)
        let csv  = try readCSV(at: url)
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }

        XCTAssertEqual(lines.count, 1 + expenses.count)
    }

    func testExportExpensesAmountFormattedWithTwoDecimals() throws {
        let expense = makeExpense(amount: 9.5)
        let url     = try service.exportExpenses([expense])
        let csv     = try readCSV(at: url)

        // El monto debe aparecer como "9.50" (dos decimales, punto decimal)
        XCTAssertTrue(csv.contains("9.50"),
            "Los montos deben formatearse con dos decimales; CSV contenía: \(csv)")
    }

    func testExportExpensesAmountWholeNumber() throws {
        let expense = makeExpense(amount: 100.0)
        let url     = try service.exportExpenses([expense])
        let csv     = try readCSV(at: url)

        XCTAssertTrue(csv.contains("100.00"))
    }

    func testExportExpensesCategoryWithCommaIsEscaped() throws {
        let expense = makeExpense(category: "Café, restaurante")
        let url     = try service.exportExpenses([expense])
        let csv     = try readCSV(at: url)

        XCTAssertTrue(csv.contains("\"Café, restaurante\""),
            "Las categorías con coma deben estar entre comillas dobles")
    }

    func testExportExpensesEmptyList() throws {
        let url  = try service.exportExpenses([])
        let csv  = try readCSV(at: url)
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }

        XCTAssertEqual(lines.count, 1, "Un CSV vacío debe tener solo la línea de cabecera")
    }

    // MARK: - exportAll

    func testExportAllCombinesBoth() throws {
        let habits   = [makeHabit(title: "Meditación")]
        let expenses = [makeExpense(category: "Salud", amount: 40)]

        let url = try service.exportAll(habits: habits, expenses: expenses)
        let csv = try readCSV(at: url)

        // Debe contener las secciones de ambos dominios
        XCTAssertTrue(csv.contains("## HÁBITOS"), "El CSV combinado debe tener sección '## HÁBITOS'")
        XCTAssertTrue(csv.contains("## GASTOS"),  "El CSV combinado debe tener sección '## GASTOS'")
    }

    func testExportAllContainsBothHeaders() throws {
        let url = try service.exportAll(habits: [makeHabit()], expenses: [makeExpense()])
        let csv = try readCSV(at: url)

        XCTAssertTrue(csv.contains("ID,Título,Completado,Fecha creación,Recordatorio activo,Días recordatorio"),
            "El CSV combinado debe incluir la cabecera de hábitos")
        XCTAssertTrue(csv.contains("ID,Monto,Categoría,Fecha"),
            "El CSV combinado debe incluir la cabecera de gastos")
    }

    func testExportAllHasSeparatorBetweenSections() throws {
        let url = try service.exportAll(habits: [makeHabit()], expenses: [makeExpense()])
        let csv = try readCSV(at: url)
        let lines = csv.components(separatedBy: "\n")

        // Debe haber al menos una línea vacía entre las dos secciones
        XCTAssertTrue(lines.contains(""),
            "El CSV combinado debe tener una línea vacía de separación entre secciones")
    }

    func testExportAllGeneratesFile() throws {
        let url = try service.exportAll(habits: [makeHabit()], expenses: [makeExpense()])
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    func testExportAllWithEmptyHabitsAndExpenses() throws {
        let url = try service.exportAll(habits: [], expenses: [])
        let csv = try readCSV(at: url)

        // Debe seguir teniendo las secciones aunque estén vacías
        XCTAssertTrue(csv.contains("## HÁBITOS"))
        XCTAssertTrue(csv.contains("## GASTOS"))
    }

    func testExportAllDataRowsArePresentForEachDomain() throws {
        let habits = [makeHabit(title: "Yoga"), makeHabit(title: "Leer")]
        let expenses = [makeExpense(category: "Transporte", amount: 10)]

        let url = try service.exportAll(habits: habits, expenses: expenses)
        let csv = try readCSV(at: url)

        XCTAssertTrue(csv.contains("Yoga"),       "El CSV combinado debe incluir el título del hábito 'Yoga'")
        XCTAssertTrue(csv.contains("Leer"),       "El CSV combinado debe incluir el título del hábito 'Leer'")
        XCTAssertTrue(csv.contains("Transporte"), "El CSV combinado debe incluir la categoría 'Transporte'")
    }
}
