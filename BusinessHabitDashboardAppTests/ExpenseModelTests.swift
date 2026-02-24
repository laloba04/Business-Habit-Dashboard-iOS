//
//  ExpenseModelTests.swift
//  BusinessHabitDashboardAppTests
//
//  Tests unitarios del modelo Expense.
//  Verifican la inicialización, campos de monto y categoría.
//

import XCTest
@testable import BusinessHabitDashboardApp

@MainActor
final class ExpenseModelTests: XCTestCase {

    // MARK: - Helpers de fixtures

    private func makeExpense(
        id: UUID = UUID(),
        userID: UUID = UUID(),
        category: String = "Alimentación",
        amount: Double = 25.50,
        createdAt: Date = Date()
    ) -> Expense {
        Expense(
            id: id,
            userID: userID,
            category: category,
            amount: amount,
            createdAt: createdAt
        )
    }

    // MARK: - Inicialización

    func testExpenseInitialization() {
        // GIVEN: valores concretos para cada campo
        let expenseID = UUID()
        let ownerID = UUID()
        let creationDate = Date(timeIntervalSince1970: 1_700_000_000)

        // WHEN: creamos el Expense
        let expense = makeExpense(
            id: expenseID,
            userID: ownerID,
            category: "Transporte",
            amount: 42.00,
            createdAt: creationDate
        )

        // THEN: todos los campos coinciden con los valores pasados
        XCTAssertEqual(expense.id, expenseID)
        XCTAssertEqual(expense.userID, ownerID)
        XCTAssertEqual(expense.category, "Transporte")
        XCTAssertEqual(expense.amount, 42.00, accuracy: 0.001)
        XCTAssertEqual(expense.createdAt, creationDate)
    }

    // MARK: - Monto

    func testExpenseAmountPositive() {
        let expense = makeExpense(amount: 99.99)
        XCTAssertGreaterThan(expense.amount, 0)
        XCTAssertEqual(expense.amount, 99.99, accuracy: 0.001)
    }

    func testExpenseAmountZero() {
        // El modelo admite montos de cero (regla de negocio, no de modelo)
        let expense = makeExpense(amount: 0.0)
        XCTAssertEqual(expense.amount, 0.0, accuracy: 0.001)
    }

    func testExpenseAmountSmallCents() {
        // Valores con decimales se almacenan con precisión Double
        let expense = makeExpense(amount: 0.01)
        XCTAssertEqual(expense.amount, 0.01, accuracy: 0.0001)
    }

    func testExpenseAmountLarge() {
        // Gastos grandes no deben perder precisión relevante para euros
        let expense = makeExpense(amount: 12_500.75)
        XCTAssertEqual(expense.amount, 12_500.75, accuracy: 0.01)
    }

    // MARK: - Categoría

    func testExpenseCategory() {
        let expense = makeExpense(category: "Salud")
        XCTAssertEqual(expense.category, "Salud")
    }

    func testExpenseCategoryIsStoredAsProvided() {
        // La categoría se almacena exactamente como se pasa (case-sensitive)
        let expense = makeExpense(category: "OCIO")
        XCTAssertEqual(expense.category, "OCIO")
        XCTAssertNotEqual(expense.category, "ocio")
    }

    func testExpenseCategoryCanBeSpanishLabel() {
        let categories = ["Alimentación", "Transporte", "Salud", "Ocio", "Otros"]
        for category in categories {
            let expense = makeExpense(category: category)
            XCTAssertEqual(expense.category, category)
        }
    }

    func testExpenseCategoryEmptyString() {
        // El modelo no valida el contenido — eso es responsabilidad del ViewModel
        let expense = makeExpense(category: "")
        XCTAssertEqual(expense.category, "")
    }

    // MARK: - Fecha de creación

    func testExpenseCreatedAtIsStored() {
        let specificDate = Date(timeIntervalSince1970: 1_690_000_000)
        let expense = makeExpense(createdAt: specificDate)
        XCTAssertEqual(expense.createdAt, specificDate)
    }

    // MARK: - Identidad (Identifiable + Hashable)

    func testExpensesWithDifferentIDsAreNotEqual() {
        let a = makeExpense(id: UUID(), category: "Salud", amount: 10)
        let b = makeExpense(id: UUID(), category: "Salud", amount: 10)
        // Hashable en structs usa todos los campos almacenados; IDs distintos implican !=
        XCTAssertNotEqual(a, b)
    }

    func testExpenseWithSameFieldsAreEqual() {
        let sharedID = UUID()
        let sharedUserID = UUID()
        let sharedDate = Date(timeIntervalSince1970: 1_700_000_000)

        let a = makeExpense(id: sharedID, userID: sharedUserID, category: "Ocio", amount: 50, createdAt: sharedDate)
        let b = makeExpense(id: sharedID, userID: sharedUserID, category: "Ocio", amount: 50, createdAt: sharedDate)

        XCTAssertEqual(a, b)
    }

    // MARK: - Codable (round-trip básico)

    func testExpenseEncodesAndDecodes() throws {
        let original = makeExpense(
            category: "Tecnología",
            amount: 299.99
        )

        // Los modelos ya tienen CodingKeys explícitos en snake_case,
        // por lo que no se necesita ninguna estrategia de clave.
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(Expense.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.category, original.category)
        XCTAssertEqual(decoded.amount, original.amount, accuracy: 0.001)
    }
}
