# 💻 Código Implementado - Resumen Técnico

Este documento resume los cambios de código principales en la implementación de deep links.

## 🔧 AuthService.swift

### Cambio 1: resetPassword() con redirect URL

**Antes:**
```swift
let body: [String: String] = ["email": safeEmail]
```

**Después:**
```swift
let body: [String: Any] = [
    "email": safeEmail,
    "options": [
        "redirectTo": "businesshabit://reset-password"
    ]
]
```

### Cambio 2: Nuevo método confirmPasswordReset()

**Nuevo código:**
```swift
func confirmPasswordReset(accessToken: String, newPassword: String) async throws {
    let endpoint = SupabaseConfig.projectURL
        .appendingPathComponent("auth/v1/user")

    var request = URLRequest(url: endpoint)
    request.httpMethod = "PUT"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

    let body: [String: String] = ["password": newPassword]
    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
        throw APIError.invalidResponse
    }

    guard (200...299).contains(httpResponse.statusCode) else {
        let message = String(data: data, encoding: .utf8) ?? "Error al cambiar contraseña"
        throw APIError.serverError(httpResponse.statusCode, message)
    }
}
```

---

## 🧠 AuthViewModel.swift

### Cambio 1: Nuevo @Published var resetToken

```swift
@Published var resetToken: String?
```

### Cambio 2: Nuevo método confirmPasswordReset()

```swift
func confirmPasswordReset(accessToken: String, newPassword: String) async -> Result<Void, Error> {
    isLoading = true
    errorMessage = nil

    do {
        try await AuthService.shared.confirmPasswordReset(
            accessToken: accessToken,
            newPassword: newPassword
        )
        isLoading = false
        return .success(())
    } catch {
        isLoading = false
        errorMessage = error.localizedDescription
        return .failure(error)
    }
}
```

### Cambio 3: Actualización de resetPasswordResetState()

**Antes:**
```swift
func resetPasswordResetState() {
    passwordResetEmailSent = false
    errorMessage = nil
}
```

**Después:**
```swift
func resetPasswordResetState() {
    passwordResetEmailSent = false
    resetToken = nil  // Nueva línea
    errorMessage = nil
}
```

---

## 📱 RootView.swift

### Cambio 1: Nueva variable de estado

```swift
@State private var showResetPassword = false
```

### Cambio 2: Modificación de LoginView

**Antes:**
```swift
LoginView(authViewModel: authViewModel)
```

**Después:**
```swift
LoginView(authViewModel: authViewModel, showResetPassword: $showResetPassword)
```

### Cambio 3: Añadido .onOpenURL handler

```swift
.onOpenURL { url in
    handleDeepLink(url)
}
```

### Cambio 4: Nuevo método handleDeepLink()

```swift
private func handleDeepLink(_ url: URL) {
    // Verificar que sea nuestro esquema
    guard url.scheme == "businesshabit" else { return }

    // Verificar que sea la ruta de reset password
    guard url.host == "reset-password" else { return }

    // Parsear el fragmento para extraer el access_token
    if let fragment = url.fragment {
        let params = parseURLFragment(fragment)

        // Extraer access_token
        if let accessToken = params["access_token"],
           let type = params["type"],
           type == "recovery" {

            // Guardar el token en el ViewModel
            authViewModel.resetToken = accessToken

            // Navegar a ResetPasswordView
            showResetPassword = true

            print("✅ Deep link procesado: Token de recuperación recibido")
        } else {
            print("⚠️ Deep link: No se encontró access_token o type válido")
        }
    } else {
        print("⚠️ Deep link: No se encontró fragment en URL")
    }
}
```

### Cambio 5: Nuevo método parseURLFragment()

```swift
private func parseURLFragment(_ fragment: String) -> [String: String] {
    var params: [String: String] = [:]

    let components = fragment.components(separatedBy: "&")
    for component in components {
        let keyValue = component.components(separatedBy: "=")
        if keyValue.count == 2 {
            let key = keyValue[0]
            let value = keyValue[1]
            params[key] = value
        }
    }

    return params
}
```

---

## 🔐 LoginView.swift

### Cambio 1: Nuevo @Binding

**Antes:**
```swift
struct LoginView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var showPassword = false
    @State private var isVisible = false
    @State private var showForgotPassword = false
```

**Después:**
```swift
struct LoginView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Binding var showResetPassword: Bool  // Nueva línea
    @State private var showPassword = false
    @State private var isVisible = false
    @State private var showForgotPassword = false
```

### Cambio 2: Añadido navigationDestination para ResetPasswordView

**Después de la línea de ForgotPasswordView:**
```swift
.navigationDestination(isPresented: $showForgotPassword) {
    ForgotPasswordView(authViewModel: authViewModel)
}
.navigationDestination(isPresented: $showResetPassword) {  // Nueva sección
    ResetPasswordView(authViewModel: authViewModel)
}
```

### Cambio 3: Actualización del Preview

**Antes:**
```swift
#Preview {
    LoginView(authViewModel: AuthViewModel())
}
```

**Después:**
```swift
#Preview {
    LoginView(authViewModel: AuthViewModel(), showResetPassword: .constant(false))
}
```

---

## 🆕 ResetPasswordView.swift (NUEVO)

**Vista completa para resetear contraseña. Características principales:**

### Estados
```swift
@ObservedObject var authViewModel: AuthViewModel
@Environment(\.dismiss) private var dismiss

@State private var newPassword = ""
@State private var confirmPassword = ""
@State private var showNewPassword = false
@State private var showConfirmPassword = false
@State private var isVisible = false
@State private var isResetting = false
@State private var resetSuccess = false
```

### Computed Properties clave

```swift
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
```

### Acción principal: resetPassword()

```swift
private func resetPassword() async {
    guard let resetToken = authViewModel.resetToken else {
        authViewModel.errorMessage = "Token de recuperación inválido"
        return
    }

    isResetting = true
    authViewModel.errorMessage = nil

    let result = await authViewModel.confirmPasswordReset(
        accessToken: resetToken,
        newPassword: newPassword
    )

    isResetting = false

    switch result {
    case .success:
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            resetSuccess = true
        }

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

    case .failure(let error):
        authViewModel.errorMessage = error.localizedDescription

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
}
```

### UI Structure

```swift
var body: some View {
    ZStack {
        AppColors.authBackgroundGradient
            .ignoresSafeArea()

        ScrollView {
            VStack(spacing: AppStyles.spacingLarge) {
                // Header con icono animado
                headerView

                // Formulario o Success state
                if resetSuccess {
                    successView
                } else {
                    formView
                }
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
```

---

## 📄 BusinessHabitDashboardAppApp.swift

### Añadidos comentarios de documentación

```swift
// NOTA: Para habilitar deep links, debes configurar manualmente en Xcode:
// 1. Abrir el proyecto en Xcode
// 2. Seleccionar el target "BusinessHabitDashboardApp"
// 3. Ir a la pestaña "Info"
// 4. Expandir "URL Types"
// 5. Hacer clic en el botón "+" para añadir un nuevo URL Type
// 6. Configurar:
//    - Identifier: com.businesshabit.auth
//    - URL Schemes: businesshabit
// 7. Guardar los cambios
//
// Alternativamente, puedes añadir directamente en Info.plist:
// <key>CFBundleURLTypes</key>
// <array>
//     <dict>
//         <key>CFBundleURLSchemes</key>
//         <array>
//             <string>businesshabit</string>
//         </array>
//         <key>CFBundleURLName</key>
//         <string>com.businesshabit.auth</string>
//     </dict>
// </array>
```

---

## 🧪 Ejemplo de URL que la app maneja

```
businesshabit://reset-password#access_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...&type=recovery
```

**Componentes:**
- **Scheme:** `businesshabit`
- **Host:** `reset-password`
- **Fragment:** `access_token=...&type=recovery`

**Parsing:**
1. URL llega a `.onOpenURL`
2. `handleDeepLink()` verifica scheme y host
3. `parseURLFragment()` extrae parámetros del fragment
4. `access_token` se guarda en `authViewModel.resetToken`
5. `showResetPassword = true` activa navegación
6. ResetPasswordView se muestra

---

## 🔄 Flujo de datos

```
Email de Supabase
    ↓
Deep Link URL (businesshabit://...)
    ↓
iOS System (detecta URL scheme)
    ↓
RootView.onOpenURL
    ↓
handleDeepLink(url)
    ↓
parseURLFragment(fragment)
    ↓
authViewModel.resetToken = token
    ↓
showResetPassword = true
    ↓
LoginView.navigationDestination activa
    ↓
ResetPasswordView
    ↓
Usuario ingresa nueva contraseña
    ↓
authViewModel.confirmPasswordReset()
    ↓
AuthService.confirmPasswordReset()
    ↓
PUT /auth/v1/user con Bearer token
    ↓
Supabase actualiza contraseña
    ↓
Success → resetSuccess = true
    ↓
Muestra success view
    ↓
Usuario toca "Ir al inicio de sesión"
    ↓
dismiss() → vuelve a LoginView
```

---

## 📊 Validaciones implementadas

### En ResetPasswordView:

1. **Longitud de contraseña:**
   ```swift
   newPassword.count >= 6
   ```

2. **Contraseñas coinciden:**
   ```swift
   newPassword == confirmPassword
   ```

3. **Fortaleza de contraseña:**
   - Débil: < 6 caracteres
   - Aceptable: 6-9 caracteres
   - Buena: 10+ caracteres
   - Excelente: 10+ caracteres + letras + números

4. **Token presente:**
   ```swift
   guard let resetToken = authViewModel.resetToken else {
       authViewModel.errorMessage = "Token de recuperación inválido"
       return
   }
   ```

### En RootView (handleDeepLink):

1. **Scheme correcto:**
   ```swift
   guard url.scheme == "businesshabit" else { return }
   ```

2. **Host correcto:**
   ```swift
   guard url.host == "reset-password" else { return }
   ```

3. **Fragment presente:**
   ```swift
   if let fragment = url.fragment { ... }
   ```

4. **Access token presente:**
   ```swift
   if let accessToken = params["access_token"] { ... }
   ```

5. **Type correcto:**
   ```swift
   if let type = params["type"], type == "recovery" { ... }
   ```

---

## 🎨 Estilos reutilizados

- `AppColors.authBackgroundGradient`
- `AppColors.successGradient`
- `AppColors.success`, `AppColors.error`, `AppColors.warning`
- `AppStyles.spacingLarge`, `AppStyles.spacingMedium`
- `AppStyles.cornerRadiusLarge`
- `AppStyles.PrimaryButtonStyle()`
- `.inputFieldStyle(icon: "lock.fill")`
- `.ultraThinMaterial`

---

## 🔐 Seguridad

- Token en URL es temporal (expira en ~1 hora)
- Token solo se usa una vez
- Validación en backend (Supabase)
- HTTPS obligatorio para redirect URLs en producción
- No se persiste el token (solo en memoria durante la sesión)

---

**Total de líneas de código nuevo:** ~600 líneas
**Complejidad:** Media
**Testing:** Cubierto en TESTING_DEEP_LINKS.md
