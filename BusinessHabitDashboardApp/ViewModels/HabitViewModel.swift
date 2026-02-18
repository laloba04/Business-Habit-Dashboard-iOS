//
//  HabitViewModel.swift
//  BusinessHabitDashboardApp
//
//  Created by Maria Bravo Angulo on 10/2/26.
//

import Foundation
import Combine

// ViewModel de hábitos:
// coordina la carga remota y actualiza el estado que consume la UI.

@MainActor
final class HabitViewModel: ObservableObject {
    @Published var habits: [Habit] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadHabits(user: SessionUser) async {
        isLoading = true
        errorMessage = nil

        do {
            habits = try await HabitService.shared.fetchHabits(userID: user.id, token: user.accessToken)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func addHabit(title: String, user: SessionUser) async {
        do {
            let created = try await HabitService.shared.createHabit(userID: user.id, title: title, token: user.accessToken)
            habits.insert(created, at: 0)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleCompletion(_ habit: Habit, user: SessionUser) async {
        do {
            let updated = try await HabitService.shared.updateHabit(
                id: habit.id,
                title: nil,
                completed: !habit.completed,
                token: user.accessToken
            )
            if let index = habits.firstIndex(where: { $0.id == updated.id }) {
                habits[index] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteHabit(_ habit: Habit, user: SessionUser) async {
        do {
            try await HabitService.shared.deleteHabit(id: habit.id, token: user.accessToken)

            // Cancelar notificaciones del hábito eliminado
            NotificationManager.shared.cancelNotification(for: habit)

            habits.removeAll { $0.id == habit.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Actualiza la configuración de recordatorio de un hábito.
    func updateReminder(for habit: Habit, enabled: Bool, time: Date?, days: [Int]?, user: SessionUser) async {
        do {
            let updated = try await HabitService.shared.updateHabit(
                id: habit.id,
                reminderEnabled: enabled,
                reminderTime: time,
                reminderDays: days,
                token: user.accessToken
            )

            // Actualizar en el array local
            if let index = habits.firstIndex(where: { $0.id == updated.id }) {
                habits[index] = updated
            }

            // Gestionar notificaciones
            if enabled {
                await NotificationManager.shared.scheduleNotification(for: updated)
            } else {
                NotificationManager.shared.cancelNotification(for: updated)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
