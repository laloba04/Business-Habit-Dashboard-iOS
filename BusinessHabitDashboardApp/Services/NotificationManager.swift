//
//  NotificationManager.swift
//  BusinessHabitDashboardApp
//
//  Created by Maria Bravo Angulo on 18/2/26.
//

import Foundation
import UserNotifications

/// Gestiona las notificaciones locales para recordatorios de hábitos.
final class NotificationManager {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Permisos

    /// Solicita autorización para enviar notificaciones.
    /// - Returns: true si se concedieron los permisos, false si fueron denegados.
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Error solicitando permisos de notificación: \(error)")
            return false
        }
    }

    /// Verifica el estado actual de los permisos de notificación.
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Programación de notificaciones

    /// Programa notificaciones para un hábito según su configuración de recordatorio.
    /// - Parameter habit: El hábito para el cual programar notificaciones.
    func scheduleNotification(for habit: Habit) async {
        // Primero cancelar cualquier notificación existente para este hábito
        cancelNotification(for: habit)

        // Verificar que el recordatorio esté habilitado y tenga datos válidos
        guard habit.isReminderEnabled,
              let reminderTime = habit.reminderTime,
              let reminderDays = habit.reminderDays,
              !reminderDays.isEmpty else {
            return
        }

        // Extraer hora y minuto de la fecha
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: reminderTime)
        let minute = calendar.component(.minute, from: reminderTime)

        // Crear una notificación para cada día seleccionado
        for weekday in reminderDays {
            let content = UNMutableNotificationContent()
            content.title = "Recordatorio de hábito"
            content.body = "Es hora de: \(habit.title)"
            content.sound = .default
            content.badge = 1

            // Crear componentes de fecha para el trigger
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute
            dateComponents.weekday = weekday + 1 // UNCalendarNotificationTrigger usa 1=Domingo, 2=Lunes, etc.

            // Crear trigger que se repite semanalmente
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

            // Crear request con identificador único
            let identifier = notificationIdentifier(for: habit, weekday: weekday)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            // Programar la notificación
            do {
                try await center.add(request)
                print("✅ Notificación programada: \(habit.title) - Día \(weekday) a las \(hour):\(String(format: "%02d", minute))")
            } catch {
                print("❌ Error programando notificación: \(error)")
            }
        }
    }

    /// Cancela todas las notificaciones de un hábito.
    /// - Parameter habit: El hábito cuyas notificaciones cancelar.
    func cancelNotification(for habit: Habit) {
        // Cancelar notificaciones para todos los días de la semana
        let identifiers = (0...6).map { notificationIdentifier(for: habit, weekday: $0) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        print("🔕 Notificaciones canceladas para: \(habit.title)")
    }

    /// Elimina todas las notificaciones programadas.
    func removeAllNotifications() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        print("🔕 Todas las notificaciones eliminadas")
    }

    // MARK: - Helpers

    /// Genera un identificador único para la notificación de un hábito en un día específico.
    /// - Parameters:
    ///   - habit: El hábito.
    ///   - weekday: El día de la semana (0=Domingo, 1=Lunes, etc.)
    /// - Returns: Identificador único en formato "habit-{UUID}-{weekday}".
    private func notificationIdentifier(for habit: Habit, weekday: Int) -> String {
        return "habit-\(habit.id.uuidString)-\(weekday)"
    }

    /// Obtiene todas las notificaciones pendientes (útil para debugging).
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await center.pendingNotificationRequests()
    }
}
