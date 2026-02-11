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
