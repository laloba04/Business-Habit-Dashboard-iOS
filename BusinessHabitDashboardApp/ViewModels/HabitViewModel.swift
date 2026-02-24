//
//  HabitViewModel.swift
//  BusinessHabitDashboardApp
//
//  Created by Maria Bravo Angulo on 10/2/26.
//

import Foundation
import Combine
import WidgetKit

// ViewModel de hábitos:
// coordina la carga remota y actualiza el estado que consume la UI.
// Tras cada mutación persiste los datos en el App Group para que el widget los lea.

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
            persistHabitsToWidget()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func addHabit(title: String, user: SessionUser) async {
        do {
            let created = try await HabitService.shared.createHabit(userID: user.id, title: title, token: user.accessToken)
            habits.insert(created, at: 0)
            persistHabitsToWidget()
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
            persistHabitsToWidget()
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
            persistHabitsToWidget()
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

    // MARK: - Realtime

    /// Cancellable que mantiene la suscripción al subject de Realtime para hábitos.
    private var realtimeCancellable: AnyCancellable?

    /// Activa la escucha de cambios en tiempo real para la tabla `habits`.
    /// El debounce agrupa ráfagas de cambios rápidos en una sola recarga.
    func startRealtime(user: SessionUser) {
        realtimeCancellable = RealtimeService.shared.habitsDidChange
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                Task { await self.loadHabits(user: user) }
            }
    }

    /// Desactiva la suscripción de Realtime para hábitos.
    func stopRealtime() {
        realtimeCancellable = nil
    }

    // MARK: - Widget Data Sync

    /// Serializa los hábitos actuales en UserDefaults del App Group
    /// y fuerza la recarga de timelines del widget.
    private func persistHabitsToWidget() {
        let widgetHabits = habits.map {
            WidgetHabit(id: $0.id.uuidString, title: $0.title, isCompleted: $0.completed)
        }

        if let data = try? JSONEncoder().encode(widgetHabits) {
            UserDefaults(suiteName: "group.com.BusinessHabitDashboardApp.shared")?
                .set(data, forKey: "widgetHabits")
        }

        WidgetCenter.shared.reloadAllTimelines()
    }
}
