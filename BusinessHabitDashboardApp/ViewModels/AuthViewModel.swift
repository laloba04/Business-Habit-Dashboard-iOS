//
//  AuthViewModel.swift
//  BusinessHabitDashboardApp
//
//  Created by Maria Bravo Angulo on 10/2/26.
//

import Foundation
import Combine

// ViewModel de autenticación:
// expone estado de sesión y acciones de login/logout para las vistas.

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var currentUser: SessionUser?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Clave para persistir la sesión en UserDefaults.
    private let storageKey = "session_user"

    init() {
        restoreSession()
    }

    func signUp() async {
        isLoading = true
        errorMessage = nil

        do {
            let user = try await AuthService.shared.signUp(email: email, password: password)
            currentUser = user
            persistSession(user)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func login() async {
        isLoading = true
        errorMessage = nil

        do {
            let user = try await AuthService.shared.login(email: email, password: password)
            currentUser = user
            persistSession(user)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func logout() {
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    // Actualiza la contraseña del usuario actual
    func updatePassword(newPassword: String) async -> Result<Void, Error> {
        guard let user = currentUser else {
            return .failure(APIError.invalidResponse)
        }

        isLoading = true
        errorMessage = nil

        do {
            try await AuthService.shared.updatePassword(newPassword: newPassword, accessToken: user.accessToken)
            isLoading = false
            return .success(())
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            return .failure(error)
        }
    }

    // Actualiza el email del usuario actual
    // Nota: Supabase requiere confirmación del nuevo email
    func updateEmail(newEmail: String) async -> Result<Void, Error> {
        guard let user = currentUser else {
            return .failure(APIError.invalidResponse)
        }

        isLoading = true
        errorMessage = nil

        do {
            try await AuthService.shared.updateEmail(newEmail: newEmail, accessToken: user.accessToken)

            // Actualizar el email localmente (la sesión sigue siendo válida)
            let updatedUser = SessionUser(id: user.id, email: newEmail, accessToken: user.accessToken)
            currentUser = updatedUser
            persistSession(updatedUser)

            isLoading = false
            return .success(())
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            return .failure(error)
        }
    }

    private func persistSession(_ user: SessionUser) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func restoreSession() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let user = try? JSONDecoder().decode(SessionUser.self, from: data) else {
            return
        }
        currentUser = user
    }
}
