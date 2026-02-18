//
//  Habit.swift
//  BusinessHabitDashboardApp
//
//  Created by Maria Bravo Angulo on 10/2/26.
//

import Foundation

// Modelo de dominio para un hábito del usuario.
// Se mapea 1:1 con la tabla `habits` de Supabase.

struct Habit: Codable, Identifiable, Hashable {
    let id: UUID
    let userID: UUID
    var title: String
    var completed: Bool
    let createdAt: Date

    // Campos de recordatorio (opcionales para compatibilidad con datos existentes)
    var reminderEnabled: Bool?
    var reminderTime: Date?
    var reminderDays: [Int]? // 0=Domingo, 1=Lunes, ..., 6=Sábado

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case title
        case completed
        case createdAt = "created_at"
        case reminderEnabled = "reminder_enabled"
        case reminderTime = "reminder_time"
        case reminderDays = "reminder_days"
    }

    // Helpers para trabajar con valores opcionales
    var isReminderEnabled: Bool {
        reminderEnabled ?? false
    }

    var hasValidReminder: Bool {
        isReminderEnabled && reminderTime != nil && !(reminderDays?.isEmpty ?? true)
    }
}
