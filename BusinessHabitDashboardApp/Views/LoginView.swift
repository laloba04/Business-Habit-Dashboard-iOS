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

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue.gradient)

                    Text("Business & Habit")
                        .font(.largeTitle.bold())

                    Text("Gestiona tus hábitos y gastos")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 60)

                // Form
                VStack(spacing: 16) {
                    // Email
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)

                        TextField("tu@email.com", text: $authViewModel.email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }

                    // Password
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Contraseña")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)

                        HStack {
                            if showPassword {
                                TextField("Ingresa tu contraseña", text: $authViewModel.password)
                            } else {
                                SecureField("Ingresa tu contraseña", text: $authViewModel.password)
                            }

                            Button {
                                showPassword.toggle()
                            } label: {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 24)

                // Error message
                if let error = authViewModel.errorMessage {
                    Text(error)
                        .font(.callout)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 24)
                }

                // Login Button
                Button {
                    Task {
                        await authViewModel.login()
                    }
                } label: {
                    if authViewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Iniciar sesión")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(isButtonDisabled ? Color.gray : Color.blue)
                .foregroundStyle(.white)
                .cornerRadius(12)
                .disabled(isButtonDisabled)
                .padding(.horizontal, 24)
                .padding(.top, 8)

                Spacer()

                // Sign Up link
                HStack {
                    Text("¿No tienes cuenta?")
                        .foregroundStyle(.secondary)

                    NavigationLink("Regístrate") {
                        SignUpView(authViewModel: authViewModel)
                    }
                    .fontWeight(.semibold)
                }
                .font(.subheadline)
                .padding(.bottom, 32)
            }
            .onAppear {
                // Limpiar error al volver a esta vista
                authViewModel.errorMessage = nil
            }
        }
    }

    private var isButtonDisabled: Bool {
        authViewModel.isLoading ||
        authViewModel.email.isEmpty ||
        authViewModel.password.isEmpty
    }
}
