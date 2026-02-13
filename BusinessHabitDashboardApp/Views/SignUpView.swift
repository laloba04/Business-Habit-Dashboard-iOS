//
//  SignUpView.swift
//  BusinessHabitDashboardApp
//
//  Created by Maria Bravo Angulo on 11/2/26.
//

import SwiftUI

struct SignUpView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
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

                    // Header con animación
                    VStack(spacing: AppStyles.spacingMedium) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 80, height: 80)

                            Image(systemName: "person.badge.plus.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.white)
                        }
                        .scaleEffect(isVisible ? 1 : 0.5)
                        .opacity(isVisible ? 1 : 0)

                        Text("Crear cuenta")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .offset(y: isVisible ? 0 : 20)
                            .opacity(isVisible ? 1 : 0)

                        Text("Únete a Business & Habit")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                            .offset(y: isVisible ? 0 : 20)
                            .opacity(isVisible ? 1 : 0)
                    }
                    .padding(.bottom, AppStyles.spacingMedium)

                    // Card con formulario
                    VStack(spacing: AppStyles.spacingLarge) {
                        // Email
                        VStack(alignment: .leading, spacing: AppStyles.spacingSmall) {
                            Text("Email")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)

                            TextField("tu@email.com", text: $authViewModel.email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .inputFieldStyle(icon: "envelope.fill")
                        }

                        // Password
                        VStack(alignment: .leading, spacing: AppStyles.spacingSmall) {
                            Text("Contraseña")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)

                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundStyle(AppColors.textSecondary)
                                    .frame(width: 20)

                                if showPassword {
                                    TextField("Mínimo 6 caracteres", text: $authViewModel.password)
                                        .textContentType(.none)
                                        .autocorrectionDisabled()
                                } else {
                                    SecureField("Mínimo 6 caracteres", text: $authViewModel.password)
                                        .textContentType(.none)
                                }

                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        showPassword.toggle()
                                    }
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                } label: {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundStyle(AppColors.textSecondary)
                                }
                            }
                            .padding()
                            .background(AppColors.cardBackground)
                            .cornerRadius(AppStyles.cornerRadiusMedium)

                            // Indicador de fortaleza
                            if !authViewModel.password.isEmpty {
                                HStack(spacing: 4) {
                                    ForEach(0..<3) { index in
                                        Rectangle()
                                            .fill(passwordStrengthColor(index: index))
                                            .frame(height: 3)
                                    }
                                }
                                .transition(.scale.combined(with: .opacity))
                            }
                        }

                        // Confirm Password
                        VStack(alignment: .leading, spacing: AppStyles.spacingSmall) {
                            Text("Confirmar contraseña")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)

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
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                } label: {
                                    Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundStyle(AppColors.textSecondary)
                                }
                            }
                            .padding()
                            .background(AppColors.cardBackground)
                            .cornerRadius(AppStyles.cornerRadiusMedium)

                            if !confirmPassword.isEmpty && authViewModel.password != confirmPassword {
                                Label("Las contraseñas no coinciden", systemImage: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(AppColors.error)
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

                        // Sign Up Button
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            Task {
                                await authViewModel.signUp()
                            }
                        } label: {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                HStack {
                                    Text("Crear cuenta")
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
                    .background(
                        RoundedRectangle(cornerRadius: AppStyles.cornerRadiusLarge)
                            .fill(.ultraThinMaterial)
                    )
                    .padding(.horizontal, AppStyles.spacingLarge)
                    .offset(y: isVisible ? 0 : 30)
                    .opacity(isVisible ? 1 : 0)

                    Spacer()
                        .frame(height: 32)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            authViewModel.email = ""
            authViewModel.password = ""
            authViewModel.errorMessage = nil
            confirmPassword = ""
            showPassword = false
            showConfirmPassword = false

            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isVisible = true
            }
        }
        .onDisappear {
            isVisible = false
        }
        .onChange(of: authViewModel.currentUser) { _, newUser in
            if newUser != nil {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                dismiss()
            }
        }
    }

    private var isButtonDisabled: Bool {
        authViewModel.isLoading ||
        authViewModel.email.isEmpty ||
        authViewModel.password.isEmpty ||
        confirmPassword.isEmpty ||
        authViewModel.password != confirmPassword ||
        authViewModel.password.count < 6
    }

    private func passwordStrengthColor(index: Int) -> Color {
        let length = authViewModel.password.count
        if length < 6 {
            return index == 0 ? AppColors.error : Color.gray.opacity(0.3)
        } else if length < 8 {
            return index < 2 ? AppColors.warning : Color.gray.opacity(0.3)
        } else {
            return AppColors.success
        }
    }
}

#Preview {
    NavigationStack {
        SignUpView(authViewModel: AuthViewModel())
    }
}
