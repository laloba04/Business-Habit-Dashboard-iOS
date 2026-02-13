//
//  ProfileView.swift
//  BusinessHabitDashboardApp
//
//  Created by Maria Bravo Angulo on 11/2/26.
//

import SwiftUI

// Vista de perfil del usuario:
// muestra información de la sesión, configuración de cuenta y personalización.

struct ProfileView: View {
    @ObservedObject var authViewModel: AuthViewModel
    let user: SessionUser

    // Estados para los sheets
    @State private var showingChangePassword = false
    @State private var showingChangeEmail = false
    @State private var showingLogoutConfirmation = false

    // Estados para modo oscuro
    @AppStorage("appearance_mode") private var appearanceMode: AppearanceMode = .system

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header con avatar de iniciales
                VStack(spacing: 16) {
                    // Avatar circular con inicial del email
                    ZStack {
                        Circle()
                            .fill(Color.blue.gradient)
                            .frame(width: 100, height: 100)

                        Text(userInitial)
                            .font(.system(size: 50, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    Text(user.email)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                }
                .padding(.top, 40)

                // Sección de información
                VStack(alignment: .leading, spacing: 16) {
                    Text("Información de la cuenta")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 24)

                    // Card de Email
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(.blue)
                            .frame(width: 30)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Email")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text(user.email)
                                .font(.body)
                                .foregroundStyle(.primary)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                }

                // Sección de Configuración de Cuenta
                VStack(alignment: .leading, spacing: 16) {
                    Text("Configuración de cuenta")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 24)

                    // Botón para cambiar email
                    Button {
                        showingChangeEmail = true
                    } label: {
                        HStack {
                            Image(systemName: "envelope.badge.fill")
                                .foregroundStyle(.blue)
                                .frame(width: 30)

                            Text("Cambiar email")
                                .font(.body)
                                .foregroundStyle(.primary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)

                    // Botón para cambiar contraseña
                    Button {
                        showingChangePassword = true
                    } label: {
                        HStack {
                            Image(systemName: "key.fill")
                                .foregroundStyle(.blue)
                                .frame(width: 30)

                            Text("Cambiar contraseña")
                                .font(.body)
                                .foregroundStyle(.primary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                }

                // Sección de Personalización
                VStack(alignment: .leading, spacing: 16) {
                    Text("Personalización")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 24)

                    // Selector de modo de apariencia
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "moon.fill")
                                .foregroundStyle(.blue)
                                .frame(width: 30)

                            Text("Apariencia")
                                .font(.body)
                                .foregroundStyle(.primary)

                            Spacer()
                        }

                        Picker("Apariencia", selection: $appearanceMode) {
                            ForEach(AppearanceMode.allCases, id: \.self) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                }

                Spacer(minLength: 40)

                // Botón de cerrar sesión
                Button {
                    showingLogoutConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Cerrar sesión")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.red.gradient)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .confirmationDialog(
                    "¿Estás seguro que deseas cerrar sesión?",
                    isPresented: $showingLogoutConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Cerrar sesión", role: .destructive) {
                        authViewModel.logout()
                    }
                    Button("Cancelar", role: .cancel) {}
                }

                // Versión de la app
                Text("Versión 1.0.0")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 16)

                Spacer()
            }
        }
        .navigationTitle("Perfil")
        // Aplicar el modo de apariencia seleccionado
        .preferredColorScheme(appearanceMode.colorScheme)
        .sheet(isPresented: $showingChangePassword) {
            ChangePasswordView(authViewModel: authViewModel)
        }
        .sheet(isPresented: $showingChangeEmail) {
            ChangeEmailView(authViewModel: authViewModel, currentEmail: user.email)
        }
    }

    // Computed property para obtener la inicial del email
    private var userInitial: String {
        let email = user.email
        if let firstChar = email.first {
            return String(firstChar).uppercased()
        }
        return "U" // Fallback
    }
}

// MARK: - Enum para modo de apariencia

enum AppearanceMode: String, CaseIterable {
    case system = "Sistema"
    case light = "Claro"
    case dark = "Oscuro"

    var displayName: String {
        self.rawValue
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

// MARK: - Vista para cambiar contraseña

struct ChangePasswordView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var showingSuccess = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Nueva contraseña", text: $newPassword)
                    SecureField("Confirmar contraseña", text: $confirmPassword)
                } header: {
                    Text("Introduce tu nueva contraseña")
                } footer: {
                    Text("La contraseña debe tener al menos 6 caracteres")
                }

                // Mensaje de error
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }

                Section {
                    Button {
                        Task {
                            await changePassword()
                        }
                    } label: {
                        if authViewModel.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            Text("Actualizar contraseña")
                                .frame(maxWidth: .infinity)
                                .foregroundStyle(.white)
                        }
                    }
                    .listRowBackground(Color.blue)
                    .disabled(isButtonDisabled)
                }
            }
            .navigationTitle("Cambiar contraseña")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
            .alert("Contraseña actualizada", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Tu contraseña ha sido actualizada correctamente.")
            }
        }
    }

    private var isButtonDisabled: Bool {
        newPassword.count < 6 || newPassword != confirmPassword || authViewModel.isLoading
    }

    private func changePassword() async {
        errorMessage = nil

        // Validación local
        guard newPassword.count >= 6 else {
            errorMessage = "La contraseña debe tener al menos 6 caracteres"
            return
        }

        guard newPassword == confirmPassword else {
            errorMessage = "Las contraseñas no coinciden"
            return
        }

        let result = await authViewModel.updatePassword(newPassword: newPassword)

        switch result {
        case .success:
            showingSuccess = true
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Vista para cambiar email

struct ChangeEmailView: View {
    @ObservedObject var authViewModel: AuthViewModel
    let currentEmail: String
    @Environment(\.dismiss) private var dismiss

    @State private var newEmail = ""
    @State private var errorMessage: String?
    @State private var showingSuccess = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(currentEmail)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Email actual")
                }

                Section {
                    TextField("Nuevo email", text: $newEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Nuevo email")
                } footer: {
                    Text("Recibirás un correo de confirmación en el nuevo email")
                }

                // Mensaje de error
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }

                Section {
                    Button {
                        Task {
                            await changeEmail()
                        }
                    } label: {
                        if authViewModel.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            Text("Actualizar email")
                                .frame(maxWidth: .infinity)
                                .foregroundStyle(.white)
                        }
                    }
                    .listRowBackground(Color.blue)
                    .disabled(isButtonDisabled)
                }
            }
            .navigationTitle("Cambiar email")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
            .alert("Email actualizado", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Se ha enviado un correo de confirmación a \(newEmail). Por favor, verifica tu nuevo email.")
            }
        }
    }

    private var isButtonDisabled: Bool {
        newEmail.isEmpty || !isValidEmail(newEmail) || newEmail == currentEmail || authViewModel.isLoading
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    private func changeEmail() async {
        errorMessage = nil

        // Validación local
        guard isValidEmail(newEmail) else {
            errorMessage = "Formato de email inválido"
            return
        }

        guard newEmail != currentEmail else {
            errorMessage = "El nuevo email debe ser diferente al actual"
            return
        }

        let result = await authViewModel.updateEmail(newEmail: newEmail)

        switch result {
        case .success:
            showingSuccess = true
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView(
            authViewModel: AuthViewModel(),
            user: SessionUser(
                id: UUID(),
                email: "usuario@ejemplo.com",
                accessToken: "token_ejemplo"
            )
        )
    }
}
