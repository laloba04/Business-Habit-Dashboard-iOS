import SwiftUI

struct LoginView: View {
    @ObservedObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section("Acceso") {
                    TextField("Email", text: $authViewModel.email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    SecureField("Password", text: $authViewModel.password)
                }

                Section {
                    Button {
                        Task { await authViewModel.login() }
                    } label: {
                        if authViewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("Entrar")
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
            .navigationTitle("Business & Habit")
        }
    }
}
