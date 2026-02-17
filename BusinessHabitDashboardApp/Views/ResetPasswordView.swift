//
//  ResetPasswordView.swift
//  BusinessHabitDashboardApp
//
//  Created by Maria Bravo Angulo on 17/2/26.
//

import SwiftUI

/// Vista para ingresar nueva contraseña después de hacer clic en el link del email
struct ResetPasswordView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showNewPassword = false
    @State private var showConfirmPassword = false
    @State private var isVisible = false
    @State private var isResetting = false
    @State private var resetSuccess = false

    var body: some View {
        ZStack {
            // Fondo con gradiente
            AppColors.authBackgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppStyles.spacingLarge) {
                    Spacer()
                        .frame(height: 40)

                    // Header con icono animado
                    VStack(spacing: AppStyles.spacingMedium) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 100, height: 100)

                            Image(systemName: "lock.rotation")
                                .font(.system(size: 50))
                                .foregroundStyle(.white)
                        }
                        .scaleEffect(isVisible ? 1 : 0.5)
                        .opacity(isVisible ? 1 : 0)

                        Text("Nueva contraseña")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .offset(y: isVisible ? 0 : 20)
                            .opacity(isVisible ? 1 : 0)

                        if !resetSuccess {
                            Text("Ingresa tu nueva contraseña segura")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, AppStyles.spacingLarge)
                                .offset(y: isVisible ? 0 : 20)
                                .opacity(isVisible ? 1 : 0)
                        }
                    }
                    .padding(.bottom, AppStyles.spacingLarge)

                    // Card con formulario o mensaje de éxito
                    if resetSuccess {
                        // Estado de éxito
                        successView
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .opacity
                            ))
                    } else {
                        // Formulario
                        formView
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .opacity
                            ))
                    }

                    Spacer()
                        .frame(height: 32)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isVisible = true
            }
        }
    }

    // MARK: - Form View

    private var formView: some View {
        VStack(spacing: AppStyles.spacingLarge) {
            // Nueva contraseña
            VStack(alignment: .leading, spacing: AppStyles.spacingSmall) {
                Text("Nueva contraseña")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                HStack {
                    Group {
                        if showNewPassword {
                            TextField("Mínimo 6 caracteres", text: $newPassword)
                        } else {
                            SecureField("Mínimo 6 caracteres", text: $newPassword)
                        }
                    }
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                    Button {
                        showNewPassword.toggle()
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    } label: {
                        Image(systemName: showNewPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                .inputFieldStyle(icon: "lock.fill")

                // Indicador de fortaleza
                if !newPassword.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(0..<3) { index in
                            Rectangle()
                                .fill(passwordStrengthColor(index: index))
                                .frame(height: 4)
                                .cornerRadius(2)
                        }
                    }
                    .animation(.easeInOut, value: newPassword)

                    Text(passwordStrengthText)
                        .font(.caption)
                        .foregroundStyle(passwordStrengthColor(index: 0))
                }
            }

            // Confirmar contraseña
            VStack(alignment: .leading, spacing: AppStyles.spacingSmall) {
                Text("Confirmar contraseña")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                HStack {
                    Group {
                        if showConfirmPassword {
                            TextField("Repite tu contraseña", text: $confirmPassword)
                        } else {
                            SecureField("Repite tu contraseña", text: $confirmPassword)
                        }
                    }
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                    Button {
                        showConfirmPassword.toggle()
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    } label: {
                        Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                .inputFieldStyle(icon: "lock.fill")

                // Validación de coincidencia
                if !confirmPassword.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(passwordsMatch ? AppColors.success : AppColors.error)

                        Text(passwordsMatch ? "Las contraseñas coinciden" : "Las contraseñas no coinciden")
                            .font(.caption)
                            .foregroundStyle(passwordsMatch ? AppColors.success : AppColors.error)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }

            // Error message
            if let error = authViewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(error)
                        .font(.callout)
                }
                .foregroundStyle(AppColors.error)
                .transition(.scale.combined(with: .opacity))
            }

            // Cambiar contraseña button
            Button {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                Task {
                    await resetPassword()
                }
            } label: {
                if isResetting {
                    ProgressView()
                        .tint(.white)
                } else {
                    HStack {
                        Text("Cambiar contraseña")
                        Image(systemName: "arrow.right.circle.fill")
                    }
                }
            }
            .buttonStyle(AppStyles.PrimaryButtonStyle(isDisabled: isButtonDisabled))
            .disabled(isButtonDisabled)
        }
        .padding(AppStyles.spacingLarge)
        .background(
            RoundedRectangle(cornerRadius: AppStyles.cornerRadiusLarge)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal, AppStyles.spacingLarge)
        .offset(y: isVisible ? 0 : 30)
        .opacity(isVisible ? 1 : 0)
    }

    // MARK: - Success View

    private var successView: some View {
        VStack(spacing: AppStyles.spacingLarge) {
            // Icono de éxito
            ZStack {
                Circle()
                    .fill(AppColors.success.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(AppColors.success)
            }

            VStack(spacing: AppStyles.spacingSmall) {
                Text("¡Contraseña actualizada!")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppColors.textPrimary)

                Text("Tu contraseña ha sido cambiada con éxito. Ya puedes iniciar sesión con tu nueva contraseña.")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppStyles.spacingMedium)
            }

            // Botón para ir al login
            Button {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                authViewModel.resetPasswordResetState()
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                    Text("Ir al inicio de sesión")
                }
            }
            .buttonStyle(AppStyles.PrimaryButtonStyle(gradient: AppColors.successGradient))
        }
        .padding(AppStyles.spacingLarge)
        .background(
            RoundedRectangle(cornerRadius: AppStyles.cornerRadiusLarge)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal, AppStyles.spacingLarge)
        .offset(y: isVisible ? 0 : 30)
        .opacity(isVisible ? 1 : 0)
    }

    // MARK: - Computed Properties

    private var isButtonDisabled: Bool {
        isResetting ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty ||
        newPassword.count < 6 ||
        !passwordsMatch
    }

    private var passwordsMatch: Bool {
        newPassword == confirmPassword
    }

    private var passwordStrength: Int {
        var strength = 0
        if newPassword.count >= 6 { strength += 1 }
        if newPassword.count >= 10 { strength += 1 }
        if newPassword.rangeOfCharacter(from: .decimalDigits) != nil &&
            newPassword.rangeOfCharacter(from: .letters) != nil {
            strength += 1
        }
        return min(strength, 3)
    }

    private var passwordStrengthText: String {
        switch passwordStrength {
        case 0: return "Débil"
        case 1: return "Aceptable"
        case 2: return "Buena"
        case 3: return "Excelente"
        default: return ""
        }
    }

    private func passwordStrengthColor(index: Int) -> Color {
        guard index < passwordStrength else {
            return Color.gray.opacity(0.3)
        }

        switch passwordStrength {
        case 1: return AppColors.error
        case 2: return AppColors.warning
        case 3: return AppColors.success
        default: return Color.gray.opacity(0.3)
        }
    }

    // MARK: - Actions

    private func resetPassword() async {
        guard let resetToken = authViewModel.resetToken else {
            authViewModel.errorMessage = "Token de recuperación inválido"
            return
        }

        isResetting = true
        authViewModel.errorMessage = nil

        let result = await authViewModel.confirmPasswordReset(accessToken: resetToken, newPassword: newPassword)

        isResetting = false

        switch result {
        case .success:
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                resetSuccess = true
            }

            // Haptic feedback de éxito
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

        case .failure(let error):
            authViewModel.errorMessage = error.localizedDescription

            // Haptic feedback de error
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
}

#Preview {
    ResetPasswordView(authViewModel: AuthViewModel())
}
