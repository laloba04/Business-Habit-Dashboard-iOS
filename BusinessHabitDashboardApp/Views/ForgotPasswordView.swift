//
//  ForgotPasswordView.swift
//  BusinessHabitDashboardApp
//
//  Created by Maria Bravo Angulo on 17/2/26.
//

import SwiftUI

struct ForgotPasswordView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var isVisible = false

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

                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.white)
                        }
                        .scaleEffect(isVisible ? 1 : 0.5)
                        .opacity(isVisible ? 1 : 0)

                        Text("Recuperar contraseña")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .offset(y: isVisible ? 0 : 20)
                            .opacity(isVisible ? 1 : 0)

                        if !authViewModel.passwordResetEmailSent {
                            Text("Ingresa tu email y te enviaremos instrucciones para recuperar tu cuenta")
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
                    if authViewModel.passwordResetEmailSent {
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    authViewModel.resetPasswordResetState()
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Volver")
                    }
                    .foregroundStyle(.white)
                }
            }
        }
        .onAppear {
            authViewModel.resetPasswordResetState()

            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isVisible = true
            }
        }
        .onDisappear {
            isVisible = false
        }
    }

    // MARK: - Form View

    private var formView: some View {
        VStack(spacing: AppStyles.spacingLarge) {
            // Email
            VStack(alignment: .leading, spacing: AppStyles.spacingSmall) {
                Text("Email")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                TextField("tu@email.com", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .inputFieldStyle(icon: "envelope.fill")
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

            // Send button
            Button {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                Task {
                    await authViewModel.requestPasswordReset(email: email)
                }
            } label: {
                if authViewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    HStack {
                        Text("Enviar instrucciones")
                        Image(systemName: "paperplane.fill")
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
                Text("¡Email enviado!")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppColors.textPrimary)

                Text("Revisa tu bandeja de entrada y sigue las instrucciones para recuperar tu contraseña.")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppStyles.spacingMedium)
            }

            VStack(spacing: AppStyles.spacingSmall) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(AppColors.info)
                    Text("Consejo:")
                        .fontWeight(.semibold)
                    Spacer()
                }

                Text("Si no recibes el email en unos minutos, revisa tu carpeta de spam.")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppStyles.cornerRadiusMedium)
                    .fill(AppColors.info.opacity(0.1))
            )

            // Botón para volver al login
            Button {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                authViewModel.resetPasswordResetState()
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "arrow.left.circle.fill")
                    Text("Volver al inicio")
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
        authViewModel.isLoading || email.isEmpty || !isValidEmail(email)
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

#Preview {
    NavigationStack {
        ForgotPasswordView(authViewModel: AuthViewModel())
    }
}
