//
//  LoginView.swift
//  BusinessHabitDashboardApp
//
//  Created by Maria Bravo Angulo on 10/2/26.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var showPassword = false
    @State private var isVisible = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo con gradiente
                AppColors.authBackgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppStyles.spacingLarge) {
                        Spacer()
                            .frame(height: 60)

                        // Header con animación
                        VStack(spacing: AppStyles.spacingMedium) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 100, height: 100)

                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.white)
                            }
                            .scaleEffect(isVisible ? 1 : 0.5)
                            .opacity(isVisible ? 1 : 0)

                            Text("Business & Habit")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .offset(y: isVisible ? 0 : 20)
                                .opacity(isVisible ? 1 : 0)

                            Text("Gestiona tus hábitos y gastos")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.9))
                                .offset(y: isVisible ? 0 : 20)
                                .opacity(isVisible ? 1 : 0)
                        }
                        .padding(.bottom, AppStyles.spacingLarge)

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
                                        TextField("Ingresa tu contraseña", text: $authViewModel.password)
                                            .textContentType(.none)
                                            .autocorrectionDisabled()
                                    } else {
                                        SecureField("Ingresa tu contraseña", text: $authViewModel.password)
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

                            // Login Button
                            Button {
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                Task {
                                    await authViewModel.login()
                                }
                            } label: {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    HStack {
                                        Text("Iniciar sesión")
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

                        Spacer()

                        // Sign Up link
                        HStack {
                            Text("¿No tienes cuenta?")
                                .foregroundStyle(.white.opacity(0.8))

                            NavigationLink("Regístrate") {
                                SignUpView(authViewModel: authViewModel)
                            }
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                        }
                        .font(.subheadline)
                        .offset(y: isVisible ? 0 : 20)
                        .opacity(isVisible ? 1 : 0)

                        Spacer()
                            .frame(height: 32)
                    }
                }
            }
            .onAppear {
                authViewModel.errorMessage = nil

                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    isVisible = true
                }
            }
            .onDisappear {
                isVisible = false
            }
        }
    }

    private var isButtonDisabled: Bool {
        authViewModel.isLoading ||
        authViewModel.email.isEmpty ||
        authViewModel.password.isEmpty
    }
}

#Preview {
    LoginView(authViewModel: AuthViewModel())
}
