import Foundation

// ViewModel de autenticación:
// expone estado de sesión y acciones de login/logout para las vistas.

@MainActor
final class AuthViewModel: ObservableObject {
    enum AuthMode: String, CaseIterable, Identifiable {
        case login = "Entrar"
        case register = "Crear cuenta"

        var id: String { rawValue }
    }

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var currentUser: SessionUser?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?
    @Published var authMode: AuthMode = .login

    // Clave para persistir la sesión en UserDefaults.

    private let storageKey = "session_user"

    init() {
        restoreSession()
    }

    func submit() async {
        switch authMode {
        case .login:
            await login()
        case .register:
            await register()
        }
    }

    func login() async {
        isLoading = true
        errorMessage = nil
        infoMessage = nil
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

    func register() async {
        isLoading = true
        errorMessage = nil
        infoMessage = nil

        do {
            if let user = try await AuthService.shared.register(email: email, password: password) {
                currentUser = user
                persistSession(user)
            } else {
                infoMessage = "Cuenta creada. Revisa tu email para confirmar y luego inicia sesión."
                authMode = .login
            }
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
