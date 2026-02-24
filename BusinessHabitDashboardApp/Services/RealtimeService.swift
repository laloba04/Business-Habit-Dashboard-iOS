//
//  RealtimeService.swift
//  BusinessHabitDashboardApp
//
//  Created by Maria Bravo Angulo on 24/2/26.
//

import Combine
import Foundation
import Supabase

// Servicio singleton que gestiona las suscripciones de Supabase Realtime.
// Publica eventos en PassthroughSubject cuando cambian las tablas `habits` o `expenses`,
// para que los ViewModels puedan recargar datos de forma reactiva.
//
// Diseño deliberado:
// - La clase NO es @MainActor para no bloquear el hilo principal durante la conexión WebSocket.
// - Los subjects emiten en MainActor explícitamente para garantizar que los suscriptores
//   de UI reciben las notificaciones en el hilo correcto.

final class RealtimeService {
    static let shared = RealtimeService()

    // MARK: - Public subjects

    /// Se activa cuando cualquier fila de la tabla `habits` cambia (INSERT, UPDATE, DELETE).
    let habitsDidChange = PassthroughSubject<Void, Never>()

    /// Se activa cuando cualquier fila de la tabla `expenses` cambia (INSERT, UPDATE, DELETE).
    let expensesDidChange = PassthroughSubject<Void, Never>()

    // MARK: - Private state

    private let client: SupabaseClient

    /// Tareas de larga duración que mantienen las suscripciones activas.
    private var habitsTask: Task<Void, Never>?
    private var expensesTask: Task<Void, Never>?

    // MARK: - Init

    private init() {
        client = SupabaseClient(
            supabaseURL: SupabaseConfig.projectURL,
            supabaseKey: SupabaseConfig.anonKey
        )
    }

    // MARK: - Public API

    /// Inicia las suscripciones de Realtime autenticadas con el token del usuario.
    /// Cancela cualquier suscripción previa antes de crear las nuevas.
    func start(accessToken: String) {
        // Cancelar suscripciones anteriores antes de crear las nuevas
        stop()

        habitsTask = Task {
            await subscribeToHabits(accessToken: accessToken)
        }

        expensesTask = Task {
            await subscribeToExpenses(accessToken: accessToken)
        }
    }

    /// Detiene todas las suscripciones de Realtime.
    func stop() {
        habitsTask?.cancel()
        expensesTask?.cancel()
        habitsTask = nil
        expensesTask = nil
    }

    // MARK: - Private subscription logic

    private func subscribeToHabits(accessToken: String) async {
        // Autenticar el cliente de Realtime con el JWT del usuario
        await client.realtimeV2.setAuth(accessToken)

        let channel = client.realtimeV2.channel("habits-realtime")

        // Registrar el listener ANTES de suscribirse (requisito de la API)
        _ = channel.onPostgresChange(AnyAction.self, schema: "public", table: "habits") {
            [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.habitsDidChange.send()
            }
        }

        do {
            try await channel.subscribeWithError()
        } catch {
            // Si el error es por cancelación, salimos silenciosamente
            if error is CancellationError { return }
            print("[RealtimeService] Error al suscribirse a habits: \(error)")
            return
        }

        // Esperar cancelación para hacer cleanup ordenado
        await withTaskCancellationHandler {
            // Suspender indefinidamente mientras la tarea esté activa
            await withCheckedContinuation { (_: CheckedContinuation<Void, Never>) in
                // La continuación nunca se reanuda; el cleanup ocurre en onCancel
            }
        } onCancel: {
            Task { [weak self] in
                guard let self else { return }
                await channel.unsubscribe()
                await self.client.realtimeV2.removeChannel(channel)
            }
        }
    }

    private func subscribeToExpenses(accessToken: String) async {
        // El cliente ya fue autenticado en subscribeToHabits; setAuth es idempotente
        // si el token no ha cambiado, pero llamarlo aquí garantiza cobertura en el
        // caso de que los gastos se suscriban solos en el futuro.
        await client.realtimeV2.setAuth(accessToken)

        let channel = client.realtimeV2.channel("expenses-realtime")

        _ = channel.onPostgresChange(AnyAction.self, schema: "public", table: "expenses") {
            [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.expensesDidChange.send()
            }
        }

        do {
            try await channel.subscribeWithError()
        } catch {
            if error is CancellationError { return }
            print("[RealtimeService] Error al suscribirse a expenses: \(error)")
            return
        }

        await withTaskCancellationHandler {
            await withCheckedContinuation { (_: CheckedContinuation<Void, Never>) in }
        } onCancel: {
            Task { [weak self] in
                guard let self else { return }
                await channel.unsubscribe()
                await self.client.realtimeV2.removeChannel(channel)
            }
        }
    }
}
