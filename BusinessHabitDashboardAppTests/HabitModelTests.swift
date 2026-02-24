//
//  HabitModelTests.swift
//  BusinessHabitDashboardAppTests
//
//  Tests unitarios del modelo Habit.
//  Verifican la inicialización, campos calculados y lógica de recordatorio.
//

import XCTest
@testable import BusinessHabitDashboardApp

@MainActor
final class HabitModelTests: XCTestCase {

    // MARK: - Helpers de fixtures

    /// Crea un Habit con valores por defecto para tests.
    /// Los parámetros opcionales permiten sobrescribir sólo lo relevante para cada caso.
    private func makeHabit(
        id: UUID = UUID(),
        userID: UUID = UUID(),
        title: String = "Hacer ejercicio",
        completed: Bool = false,
        createdAt: Date = Date(),
        reminderEnabled: Bool? = nil,
        reminderTime: Date? = nil,
        reminderDays: [Int]? = nil
    ) -> Habit {
        Habit(
            id: id,
            userID: userID,
            title: title,
            completed: completed,
            createdAt: createdAt,
            reminderEnabled: reminderEnabled,
            reminderTime: reminderTime,
            reminderDays: reminderDays
        )
    }

    // MARK: - Inicialización

    func testHabitInitialization() {
        // GIVEN: valores concretos para cada campo
        let habitID = UUID()
        let ownerID = UUID()
        let creationDate = Date(timeIntervalSince1970: 1_700_000_000)

        // WHEN: creamos el Habit
        let habit = makeHabit(
            id: habitID,
            userID: ownerID,
            title: "Meditar 10 minutos",
            completed: false,
            createdAt: creationDate
        )

        // THEN: todos los campos coinciden con los valores pasados
        XCTAssertEqual(habit.id, habitID)
        XCTAssertEqual(habit.userID, ownerID)
        XCTAssertEqual(habit.title, "Meditar 10 minutos")
        XCTAssertFalse(habit.completed)
        XCTAssertEqual(habit.createdAt, creationDate)
        XCTAssertNil(habit.reminderEnabled)
        XCTAssertNil(habit.reminderTime)
        XCTAssertNil(habit.reminderDays)
    }

    // MARK: - Estado completado

    func testHabitIsCompleted() {
        // Un hábito puede crearse como completado
        let completedHabit = makeHabit(completed: true)
        XCTAssertTrue(completedHabit.completed)

        // O como no completado
        let pendingHabit = makeHabit(completed: false)
        XCTAssertFalse(pendingHabit.completed)
    }

    // MARK: - isReminderEnabled (propiedad calculada)

    func testIsReminderEnabledWhenNil() {
        // Si reminderEnabled es nil, la propiedad calculada devuelve false
        let habit = makeHabit(reminderEnabled: nil)
        XCTAssertFalse(habit.isReminderEnabled)
    }

    func testIsReminderEnabledWhenFalse() {
        let habit = makeHabit(reminderEnabled: false)
        XCTAssertFalse(habit.isReminderEnabled)
    }

    func testIsReminderEnabledWhenTrue() {
        let habit = makeHabit(reminderEnabled: true)
        XCTAssertTrue(habit.isReminderEnabled)
    }

    // MARK: - hasValidReminder

    func testHabitHasValidReminderWhenAllFieldsPresent() {
        // GIVEN: recordatorio habilitado, hora definida y al menos un día
        let reminderTime = Calendar.current.date(
            bySettingHour: 8, minute: 30, second: 0, of: Date()
        )!
        let habit = makeHabit(
            reminderEnabled: true,
            reminderTime: reminderTime,
            reminderDays: [1, 3, 5] // Lunes, Miércoles, Viernes
        )

        // THEN: hasValidReminder es true
        XCTAssertTrue(habit.hasValidReminder)
    }

    func testHabitHasValidReminderReturnsFalseWhenDisabled() {
        // GIVEN: recordatorio desactivado aunque el resto de campos estén presentes
        let reminderTime = Calendar.current.date(
            bySettingHour: 9, minute: 0, second: 0, of: Date()
        )!
        let habit = makeHabit(
            reminderEnabled: false,
            reminderTime: reminderTime,
            reminderDays: [1, 2]
        )

        XCTAssertFalse(habit.hasValidReminder)
    }

    func testHabitHasValidReminderReturnsFalseWhenTimeIsNil() {
        // GIVEN: habilitado pero sin hora
        let habit = makeHabit(
            reminderEnabled: true,
            reminderTime: nil,
            reminderDays: [1]
        )

        XCTAssertFalse(habit.hasValidReminder)
    }

    func testHabitHasValidReminderReturnsFalseWhenDaysAreEmpty() {
        // GIVEN: habilitado y con hora, pero sin días seleccionados
        let reminderTime = Calendar.current.date(
            bySettingHour: 7, minute: 0, second: 0, of: Date()
        )!
        let habit = makeHabit(
            reminderEnabled: true,
            reminderTime: reminderTime,
            reminderDays: []
        )

        XCTAssertFalse(habit.hasValidReminder)
    }

    func testHabitHasValidReminderReturnsFalseWhenDaysAreNil() {
        // GIVEN: habilitado y con hora, pero reminderDays == nil
        let reminderTime = Calendar.current.date(
            bySettingHour: 7, minute: 0, second: 0, of: Date()
        )!
        let habit = makeHabit(
            reminderEnabled: true,
            reminderTime: reminderTime,
            reminderDays: nil
        )

        XCTAssertFalse(habit.hasValidReminder)
    }

    // MARK: - Días de recordatorio

    func testHabitReminderDaysStoredCorrectly() {
        // Los índices de días siguen la convención 0=Dom…6=Sáb
        let days = [0, 1, 6] // Domingo, Lunes, Sábado
        let habit = makeHabit(reminderDays: days)

        XCTAssertEqual(habit.reminderDays, days)
    }

    func testHabitReminderDaysAllWeek() {
        // Un recordatorio con todos los días de la semana
        let allDays = [0, 1, 2, 3, 4, 5, 6]
        let reminderTime = Calendar.current.date(
            bySettingHour: 6, minute: 0, second: 0, of: Date()
        )!
        let habit = makeHabit(
            reminderEnabled: true,
            reminderTime: reminderTime,
            reminderDays: allDays
        )

        XCTAssertTrue(habit.hasValidReminder)
        XCTAssertEqual(habit.reminderDays?.count, 7)
    }

    func testHabitReminderDaysSingleDay() {
        // Un único día también es válido
        let reminderTime = Calendar.current.date(
            bySettingHour: 8, minute: 0, second: 0, of: Date()
        )!
        let habit = makeHabit(
            reminderEnabled: true,
            reminderTime: reminderTime,
            reminderDays: [3] // Miércoles
        )

        XCTAssertTrue(habit.hasValidReminder)
        XCTAssertEqual(habit.reminderDays, [3])
    }

    // MARK: - Codable (round-trip básico)

    func testHabitEncodesAndDecodes() throws {
        // Verifica que el modelo sobrevive un ciclo encode → decode sin pérdida de datos
        let original = makeHabit(
            title: "Leer 30 minutos",
            completed: true,
            reminderEnabled: true,
            reminderDays: [1, 3]
        )

        // Los modelos ya tienen CodingKeys explícitos en snake_case,
        // por lo que no se necesita ninguna estrategia de clave.
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(Habit.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.title, original.title)
        XCTAssertEqual(decoded.completed, original.completed)
        XCTAssertEqual(decoded.reminderEnabled, original.reminderEnabled)
        XCTAssertEqual(decoded.reminderDays, original.reminderDays)
    }
}
