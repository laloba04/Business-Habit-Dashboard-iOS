import SwiftUI

struct LoginView: View {
    @ObservedObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section("Acceso") {
                    Picker("Modo", selection: $authViewModel.authMode) {
                        ForEach(AuthViewModel.AuthMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    TextField("Email", text: $authViewModel.email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    SecureField("Password", text: $authViewModel.password)
                }

                Section {
                    Button {
                        Task { await authViewModel.submit() }
                        Task { await authViewModel.login() }
                    } label: {
                        if authViewModel.isLoading {
                            ProgressView()
                        } else {
                            Text(authViewModel.authMode.rawValue)
                            Text("Entrar")
                        }
                    }
                    .disabled(authViewModel.email.isEmpty || authViewModel.password.isEmpty || authViewModel.isLoading)
                }

                if let info = authViewModel.infoMessage {
                    Section {
                        Text(info)
                            .foregroundStyle(.blue)
                    }
                }

                if let error = authViewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Business & Habit")
        }
    }
}
