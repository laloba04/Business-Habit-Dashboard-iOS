//
//  ProfileView.swift
//  BusinessHabitDashboardApp
//
//  Created by Maria Bravo Angulo on 11/2/26.
//

import SwiftUI

// Vista de perfil del usuario:
// muestra información de la sesión y permite cerrar sesión de forma clara.

struct ProfileView: View {
    @ObservedObject var authViewModel: AuthViewModel
    let user: SessionUser
    @State private var showingLogoutConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header con icono de perfil
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.gradient)
                            .frame(width: 100, height: 100)

                        Image(systemName: "person.fill")
                            .font(.system(size: 50))
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

                    // Card de ID de Usuario
                    HStack {
                        Image(systemName: "person.text.rectangle.fill")
                            .foregroundStyle(.blue)
                            .frame(width: 30)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("ID de Usuario")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text(user.id.uuidString)
                                .font(.caption)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }

                        Spacer()
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

                // Versión de la app (opcional)
                Text("Versión 1.0.0")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 16)

                Spacer()
            }
        }
        .navigationTitle("Perfil")
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
