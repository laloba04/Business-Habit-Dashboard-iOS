//
//  ExportService.swift
//  BusinessHabitDashboardApp
//
//  Created by Maria Bravo Angulo on 22/2/26.
//

import Foundation

// Servicio de exportación de datos a CSV.
// Genera archivos temporales en el directorio del sistema que pueden
// compartirse vía ShareLink o descartarse cuando se desmontan las vistas.

enum ExportError: LocalizedError {
    case failedToWriteFile(String)

    var errorDescription: String? {
        switch self {
        case .failedToWriteFile(let name):
            return "No se pudo escribir el archivo \(name). Verifica que haya espacio disponible."
        }
    }
}

final class ExportService {

    static let shared = ExportService()
    private init() {}

    // MARK: - Exportación de Hábitos

    /// Genera un archivo CSV con todos los hábitos y lo guarda en el directorio temporal.
    /// - Returns: URL al archivo temporal generado.
    func exportHabits(_ habits: [Habit]) throws -> URL {
        let fileName = "habitos_\(formattedDateForFileName()).csv"
        let csvContent = buildHabitsCSV(habits)
        return try writeToTemporaryFile(content: csvContent, fileName: fileName)
    }

    // MARK: - Exportación de Gastos

    /// Genera un archivo CSV con todos los gastos y lo guarda en el directorio temporal.
    /// - Returns: URL al archivo temporal generado.
    func exportExpenses(_ expenses: [Expense]) throws -> URL {
        let fileName = "gastos_\(formattedDateForFileName()).csv"
        let csvContent = buildExpensesCSV(expenses)
        return try writeToTemporaryFile(content: csvContent, fileName: fileName)
    }

    // MARK: - Exportación Combinada

    /// Genera un único CSV con hábitos y gastos separados por sección.
    /// - Returns: URL al archivo temporal generado.
    func exportAll(habits: [Habit], expenses: [Expense]) throws -> URL {
        let fileName = "datos_completos_\(formattedDateForFileName()).csv"

        var lines: [String] = []

        // ---- Sección hábitos ----
        lines.append("## HÁBITOS")
        lines.append(contentsOf: buildHabitsCSVLines(habits))

        // Línea en blanco como separador visual entre secciones
        lines.append("")

        // ---- Sección gastos ----
        lines.append("## GASTOS")
        lines.append(contentsOf: buildExpensesCSVLines(expenses))

        let csvContent = lines.joined(separator: "\n")
        return try writeToTemporaryFile(content: csvContent, fileName: fileName)
    }

    // MARK: - Builders internos

    private func buildHabitsCSV(_ habits: [Habit]) -> String {
        let lines = buildHabitsCSVLines(habits)
        return lines.joined(separator: "\n")
    }

    private func buildHabitsCSVLines(_ habits: [Habit]) -> [String] {
        var lines: [String] = []

        // Cabecera en español
        lines.append("ID,Título,Completado,Fecha creación,Recordatorio activo,Días recordatorio")

        let dateFormatter = ISO8601DateFormatter()
        let dayNames = ["Dom", "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb"]

        for habit in habits {
            let id = habit.id.uuidString
            let title = escapedCSVField(habit.title)
            let completed = habit.completed ? "Sí" : "No"
            let createdAt = dateFormatter.string(from: habit.createdAt)
            let reminderEnabled = habit.isReminderEnabled ? "Sí" : "No"

            // Convertir los índices de días a nombres legibles
            let reminderDaysText: String
            if let days = habit.reminderDays, !days.isEmpty {
                let names = days
                    .sorted()
                    .compactMap { index -> String? in
                        guard index >= 0, index < dayNames.count else { return nil }
                        return dayNames[index]
                    }
                reminderDaysText = names.joined(separator: " ")
            } else {
                reminderDaysText = ""
            }

            let row = "\(id),\(title),\(completed),\(createdAt),\(reminderEnabled),\(escapedCSVField(reminderDaysText))"
            lines.append(row)
        }

        return lines
    }

    private func buildExpensesCSV(_ expenses: [Expense]) -> String {
        let lines = buildExpensesCSVLines(expenses)
        return lines.joined(separator: "\n")
    }

    private func buildExpensesCSVLines(_ expenses: [Expense]) -> [String] {
        var lines: [String] = []

        // Cabecera en español
        // Nota: el modelo Expense no tiene campo "description", solo category + amount
        lines.append("ID,Monto,Categoría,Fecha")

        let dateFormatter = ISO8601DateFormatter()

        for expense in expenses {
            let id = expense.id.uuidString
            // Formato de monto con 2 decimales usando punto como separador decimal
            // para que sea estándar CSV y compatible con herramientas de análisis
            let amount = String(format: "%.2f", expense.amount)
            let category = escapedCSVField(expense.category)
            let createdAt = dateFormatter.string(from: expense.createdAt)

            let row = "\(id),\(amount),\(category),\(createdAt)"
            lines.append(row)
        }

        return lines
    }

    // MARK: - Helpers

    /// Escapa un campo CSV: si contiene coma, comilla o salto de línea, lo envuelve en comillas dobles.
    private func escapedCSVField(_ field: String) -> String {
        let needsQuoting = field.contains(",") || field.contains("\"") || field.contains("\n")
        if needsQuoting {
            // Escapar comillas internas duplicándolas
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }

    /// Formato de fecha para usar en el nombre del archivo (sin caracteres especiales).
    private func formattedDateForFileName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    /// Escribe contenido de texto en un archivo dentro del directorio temporal del sistema.
    private func writeToTemporaryFile(content: String, fileName: String) throws -> URL {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        guard let data = content.data(using: .utf8) else {
            throw ExportError.failedToWriteFile(fileName)
        }

        do {
            try data.write(to: tempURL, options: .atomic)
        } catch {
            throw ExportError.failedToWriteFile(fileName)
        }

        return tempURL
    }
}
