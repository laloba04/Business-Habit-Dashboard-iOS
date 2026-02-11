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

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue.gradient)

                Text("Crear cuenta")
                    .font(.largeTitle.bold())

                Text("Únete a Business & Habit")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 40)

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
                            TextField("Mínimo 6 caracteres", text: $authViewModel.password)
                                .textContentType(.none)
                                .autocorrectionDisabled()
                        } else {
                            SecureField("Mínimo 6 caracteres", text: $authViewModel.password)
                                .textContentType(.none)
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

                // Confirm Password
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confirmar contraseña")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    HStack {
                        if showConfirmPassword {
                            TextField("Repite tu contraseña", text: $confirmPassword)
                                .textContentType(.none)
                                .autocorrectionDisabled()
                        } else {
                            SecureField("Repite tu contraseña", text: $confirmPassword)
                                .textContentType(.none)
                        }

                        Button {
                            showConfirmPassword.toggle()
                        } label: {
                            Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                    if !confirmPassword.isEmpty && authViewModel.password != confirmPassword {
                        Label("Las contraseñas no coinciden", systemImage: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
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

            // Sign Up Button
            Button {
                Task {
                    await authViewModel.signUp()
                }
            } label: {
                if authViewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Crear cuenta")
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
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Limpiar campos al entrar a la vista
            authViewModel.email = ""
            authViewModel.password = ""
            authViewModel.errorMessage = nil
            confirmPassword = ""
            showPassword = false
            showConfirmPassword = false
        }
        .onChange(of: authViewModel.currentUser) { _, newUser in
            // Si el registro fue exitoso, cerrar esta vista
            if newUser != nil {
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
}
