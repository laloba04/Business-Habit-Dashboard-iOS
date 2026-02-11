//
//  LoginView.swift
//  BusinessHabitDashboardApp
//
//  Created by Maria Bravo Angulo on 10/2/26.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var selectedTab: AuthTab = .login

    enum AuthTab {
        case login, signUp
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tabs personalizados
                HStack(spacing: 0) {
                    Button {
                        selectedTab = .login
                        authViewModel.errorMessage = nil
                    } label: {
                        Text("Entrar")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedTab == .login ? Color.accentColor.opacity(0.1) : Color.clear)
                    }
                    .foregroundStyle(selectedTab == .login ? .primary : .secondary)

                    Button {
                        selectedTab = .signUp
                        authViewModel.errorMessage = nil
                    } label: {
                        Text("Registrarse")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedTab == .signUp ? Color.accentColor.opacity(0.1) : Color.clear)
                    }
                    .foregroundStyle(selectedTab == .signUp ? .primary : .secondary)
                }
                .background(Color(uiColor: .systemGroupedBackground))

                Form {
                    Section(selectedTab == .login ? "Iniciar sesión" : "Crear cuenta") {
                        TextField("Email", text: $authViewModel.email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                        SecureField("Password", text: $authViewModel.password)

                        if selectedTab == .signUp {
                            Text("Mínimo 6 caracteres")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Section {
                        Button {
                            Task {
                                if selectedTab == .login {
                                    await authViewModel.login()
                                } else {
                                    await authViewModel.signUp()
                                }
                            }
                        } label: {
                            if authViewModel.isLoading {
                                ProgressView()
                            } else {
                                Text(selectedTab == .login ? "Entrar" : "Crear cuenta")
                            }
                        }
                        .disabled(authViewModel.email.isEmpty || authViewModel.password.isEmpty || authViewModel.isLoading)
                    }

                    if let error = authViewModel.errorMessage {
                        Section {
                            Text(error)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .navigationTitle("Business & Habit")
        }
    }
}
