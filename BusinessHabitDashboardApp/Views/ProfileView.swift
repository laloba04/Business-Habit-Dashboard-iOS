//
//  ProfileView.swift
//  BusinessHabitDashboardApp
//
//  Created by Maria Bravo Angulo on 11/2/26.
//

import SwiftUI

/// Vista de perfil del usuario con diseño moderno y animaciones
struct ProfileView: View {
    @ObservedObject var authViewModel: AuthViewModel
    let user: SessionUser

    // Datos para exportación (recibidos desde RootView vía los ViewModels)
    let habits: [Habit]
    let expenses: [Expense]

    // Estados para los sheets
    @State private var showingChangePassword = false
    @State private var showingChangeEmail = false
    @State private var showingLogoutConfirmation = false
    @State private var showingExport = false

    // Estados para modo oscuro
    @AppStorage("appearance_mode") private var appearanceMode: AppearanceMode = .system

    var body: some View {
        ScrollView {
            VStack(spacing: AppStyles.spacingLarge) {
                // Header con avatar de iniciales
                VStack(spacing: AppStyles.spacingMedium) {
                    // Avatar circular con gradiente
                    ZStack {
                        Circle()
                            .fill(AppColors.primaryGradient)
                            .frame(width: 100, height: 100)
                            .shadow(color: AppStyles.shadowColor, radius: 10, x: 0, y: 4)

                        Text(userInitial)
                            .font(.system(size: 50, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    Text(user.email)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppColors.textPrimary)
                }
                .padding(.top, 40)

                // Sección de información
                VStack(alignment: .leading, spacing: AppStyles.spacingMedium) {
                    Text("Información de la cuenta")
                        .font(.headline)
                        .foregroundStyle(AppColors.textSecondary)
                        .padding(.horizontal, AppStyles.spacingLarge)

                    // Card de Email
                    HStack {
                        ZStack {
                            Circle()
                                .fill(AppColors.primaryGradient)
                                .frame(width: 40, height: 40)

                            Image(systemName: "envelope.fill")
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Email")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.textSecondary)

                            Text(user.email)
                                .font(.body.weight(.medium))
                                .foregroundStyle(AppColors.textPrimary)
                        }

                        Spacer()
                    }
                    .padding()
                    .cardStyle(shadow: true)
                    .padding(.horizontal, AppStyles.spacingLarge)
                }

                // Sección de Configuración de Cuenta
                VStack(alignment: .leading, spacing: AppStyles.spacingMedium) {
                    Text("Configuración de cuenta")
                        .font(.headline)
                        .foregroundStyle(AppColors.textSecondary)
                        .padding(.horizontal, AppStyles.spacingLarge)

                    // Botón para cambiar email
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        showingChangeEmail = true
                    } label: {
                        ProfileActionRow(
                            icon: "envelope.badge.fill",
                            title: "Cambiar email",
                            gradient: AppColors.primaryGradient
                        )
                    }
                    .padding(.horizontal, AppStyles.spacingLarge)

                    // Botón para cambiar contraseña
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        showingChangePassword = true
                    } label: {
                        ProfileActionRow(
                            icon: "key.fill",
                            title: "Cambiar contraseña",
                            gradient: AppColors.secondaryGradient
                        )
                    }
                    .padding(.horizontal, AppStyles.spacingLarge)
                }

                // Sección de Personalización
                VStack(alignment: .leading, spacing: AppStyles.spacingMedium) {
                    Text("Personalización")
                        .font(.headline)
                        .foregroundStyle(AppColors.textSecondary)
                        .padding(.horizontal, AppStyles.spacingLarge)

                    // Selector de modo de apariencia
                    VStack(spacing: AppStyles.spacingMedium) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(AppColors.accentGradient)
                                    .frame(width: 40, height: 40)

                                Image(systemName: appearanceModeIcon)
                                    .foregroundStyle(.white)
                            }

                            Text("Apariencia")
                                .font(.body.weight(.medium))
                                .foregroundStyle(AppColors.textPrimary)

                            Spacer()
                        }

                        Picker("Apariencia", selection: $appearanceMode) {
                            ForEach(AppearanceMode.allCases, id: \.self) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: appearanceMode) { _, _ in
                            let generator = UISelectionFeedbackGenerator()
                            generator.selectionChanged()
                        }
                    }
                    .padding()
                    .cardStyle(shadow: true)
                    .padding(.horizontal, AppStyles.spacingLarge)
                }

                // Sección de Datos y privacidad
                VStack(alignment: .leading, spacing: AppStyles.spacingMedium) {
                    Text("Datos y privacidad")
                        .font(.headline)
                        .foregroundStyle(AppColors.textSecondary)
                        .padding(.horizontal, AppStyles.spacingLarge)

                    // Botón para exportar datos
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        showingExport = true
                    } label: {
                        ProfileActionRow(
                            icon: "arrow.down.doc.fill",
                            title: "Exportar datos",
                            gradient: AppColors.accentGradient
                        )
                    }
                    .padding(.horizontal, AppStyles.spacingLarge)
                }

                Spacer(minLength: 40)

                // Botón de cerrar sesión
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    showingLogoutConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Cerrar sesión")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                }
                .buttonStyle(AppStyles.PrimaryButtonStyle(
                    gradient: LinearGradient(
                        colors: [AppColors.error, Color(hex: "DC2626")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                ))
                .padding(.horizontal, AppStyles.spacingLarge)
                .confirmationDialog(
                    "¿Estás seguro que deseas cerrar sesión?",
                    isPresented: $showingLogoutConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Cerrar sesión", role: .destructive) {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.warning)
                        authViewModel.logout()
                    }
                    Button("Cancelar", role: .cancel) {}
                }

                // Versión de la app
                Text("Versión 1.0.0")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.top, AppStyles.spacingMedium)

                Spacer()
            }
        }
        .background(AppColors.background)
        .navigationTitle("Perfil")
        .preferredColorScheme(appearanceMode.colorScheme)
        .sheet(isPresented: $showingChangePassword) {
            ChangePasswordView(authViewModel: authViewModel)
        }
        .sheet(isPresented: $showingChangeEmail) {
            ChangeEmailView(authViewModel: authViewModel, currentEmail: user.email)
        }
        .sheet(isPresented: $showingExport) {
            ExportView(habits: habits, expenses: expenses)
        }
    }

    private var userInitial: String {
        let email = user.email
        if let firstChar = email.first {
            return String(firstChar).uppercased()
        }
        return "U"
    }

    private var appearanceModeIcon: String {
        switch appearanceMode {
        case .system:
            return "circle.lefthalf.filled"
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        }
    }
}

// MARK: - ProfileActionRow

struct ProfileActionRow: View {
    let icon: String
    let title: String
    let gradient: LinearGradient

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(gradient)
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .foregroundStyle(.white)
            }

            Text(title)
                .font(.body.weight(.medium))
                .foregroundStyle(AppColors.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding()
        .cardStyle(shadow: true)
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

// MARK: - ChangePasswordView

struct ChangePasswordView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var showingSuccess = false
    @State private var showNewPassword = false
    @State private var showConfirmPassword = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppStyles.spacingLarge) {
                        // Icono header
                        ZStack {
                            Circle()
                                .fill(AppColors.secondaryGradient)
                                .frame(width: 80, height: 80)

                            Image(systemName: "key.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.white)
                        }
                        .padding(.top, AppStyles.spacingLarge)

                        Text("Introduce tu nueva contraseña")
                            .font(.headline)
                            .foregroundStyle(AppColors.textSecondary)
                            .multilineTextAlignment(.center)

                        VStack(spacing: AppStyles.spacingLarge) {
                            // Nueva contraseña
                            VStack(alignment: .leading, spacing: AppStyles.spacingSmall) {
                                Text("Nueva contraseña")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(AppColors.textSecondary)

                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundStyle(AppColors.textSecondary)
                                        .frame(width: 20)

                                    if showNewPassword {
                                        TextField("Mínimo 6 caracteres", text: $newPassword)
                                            .textContentType(.none)
                                            .autocorrectionDisabled()
                                    } else {
                                        SecureField("Mínimo 6 caracteres", text: $newPassword)
                                            .textContentType(.none)
                                    }

                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                            showNewPassword.toggle()
                                        }
                                    } label: {
                                        Image(systemName: showNewPassword ? "eye.slash.fill" : "eye.fill")
                                            .foregroundStyle(AppColors.textSecondary)
                                    }
                                }
                                .padding()
                                .background(AppColors.cardBackground)
                                .cornerRadius(AppStyles.cornerRadiusMedium)
                            }

                            // Confirmar contraseña
                            VStack(alignment: .leading, spacing: AppStyles.spacingSmall) {
                                Text("Confirmar contraseña")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(AppColors.textSecondary)

                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundStyle(AppColors.textSecondary)
                                        .frame(width: 20)

                                    if showConfirmPassword {
                                        TextField("Repite tu contraseña", text: $confirmPassword)
                                            .textContentType(.none)
                                            .autocorrectionDisabled()
                                    } else {
                                        SecureField("Repite tu contraseña", text: $confirmPassword)
                                            .textContentType(.none)
                                    }

                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                            showConfirmPassword.toggle()
                                        }
                                    } label: {
                                        Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                            .foregroundStyle(AppColors.textSecondary)
                                    }
                                }
                                .padding()
                                .background(AppColors.cardBackground)
                                .cornerRadius(AppStyles.cornerRadiusMedium)

                                if !confirmPassword.isEmpty && newPassword != confirmPassword {
                                    Label("Las contraseñas no coinciden", systemImage: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(AppColors.error)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }

                            // Mensaje de error
                            if let error = errorMessage {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                    Text(error)
                                        .font(.callout)
                                }
                                .foregroundStyle(AppColors.error)
                                .transition(.scale.combined(with: .opacity))
                            }

                            // Botón actualizar
                            Button {
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                Task {
                                    await changePassword()
                                }
                            } label: {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    HStack {
                                        Text("Actualizar contraseña")
                                        Image(systemName: "checkmark.circle.fill")
                                    }
                                }
                            }
                            .buttonStyle(AppStyles.PrimaryButtonStyle(
                                gradient: AppColors.secondaryGradient,
                                isDisabled: isButtonDisabled
                            ))
                            .disabled(isButtonDisabled)
                        }
                        .padding(AppStyles.spacingLarge)
                        .cardStyle(shadow: true)
                        .padding(.horizontal, AppStyles.spacingLarge)
                    }
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
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            showingSuccess = true
        case .failure(let error):
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - ChangeEmailView

struct ChangeEmailView: View {
    @ObservedObject var authViewModel: AuthViewModel
    let currentEmail: String
    @Environment(\.dismiss) private var dismiss

    @State private var newEmail = ""
    @State private var errorMessage: String?
    @State private var showingSuccess = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppStyles.spacingLarge) {
                        // Icono header
                        ZStack {
                            Circle()
                                .fill(AppColors.primaryGradient)
                                .frame(width: 80, height: 80)

                            Image(systemName: "envelope.badge.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.white)
                        }
                        .padding(.top, AppStyles.spacingLarge)

                        Text("Actualiza tu dirección de email")
                            .font(.headline)
                            .foregroundStyle(AppColors.textSecondary)
                            .multilineTextAlignment(.center)

                        VStack(spacing: AppStyles.spacingLarge) {
                            // Email actual
                            VStack(alignment: .leading, spacing: AppStyles.spacingSmall) {
                                Text("Email actual")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(AppColors.textSecondary)

                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .foregroundStyle(AppColors.textSecondary)
                                        .frame(width: 20)

                                    Text(currentEmail)
                                        .foregroundStyle(AppColors.textSecondary)

                                    Spacer()
                                }
                                .padding()
                                .background(AppColors.cardBackground)
                                .cornerRadius(AppStyles.cornerRadiusMedium)
                            }

                            // Nuevo email
                            VStack(alignment: .leading, spacing: AppStyles.spacingSmall) {
                                Text("Nuevo email")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(AppColors.textSecondary)

                                TextField("nuevo@email.com", text: $newEmail)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .inputFieldStyle(icon: "envelope.fill")

                                Text("Recibirás un correo de confirmación")
                                    .font(.caption)
                                    .foregroundStyle(AppColors.textSecondary)
                            }

                            // Mensaje de error
                            if let error = errorMessage {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                    Text(error)
                                        .font(.callout)
                                }
                                .foregroundStyle(AppColors.error)
                                .transition(.scale.combined(with: .opacity))
                            }

                            // Botón actualizar
                            Button {
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                Task {
                                    await changeEmail()
                                }
                            } label: {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    HStack {
                                        Text("Actualizar email")
                                        Image(systemName: "checkmark.circle.fill")
                                    }
                                }
                            }
                            .buttonStyle(AppStyles.PrimaryButtonStyle(
                                gradient: AppColors.primaryGradient,
                                isDisabled: isButtonDisabled
                            ))
                            .disabled(isButtonDisabled)
                        }
                        .padding(AppStyles.spacingLarge)
                        .cardStyle(shadow: true)
                        .padding(.horizontal, AppStyles.spacingLarge)
                    }
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
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            showingSuccess = true
        case .failure(let error):
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
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
            ),
            habits: [],
            expenses: []
        )
    }
}
