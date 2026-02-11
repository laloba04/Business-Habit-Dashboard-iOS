# 🔒 Configuración Segura de Credenciales Supabase

## ✅ Sistema implementado: Template Files (como .env en React)

Este proyecto usa un sistema de **archivos template** para proteger las credenciales de Supabase, similar a cómo funcionan los archivos `.env` en proyectos React/Node.js.

---

## 📁 Archivos de seguridad

### ✅ Lo que SÍ está en git (público):
- `SupabaseCredentials.swift.template` - Plantilla SIN credenciales reales
- `SupabaseConfig.swift` - Código que lee las credenciales
- `.gitignore` - Protección contra subir archivos sensibles

### ❌ Lo que NUNCA está en git (privado):
- `SupabaseCredentials.swift` - TUS credenciales reales (gitignored)
- `.env`, `.key`, `.pem` - Otros archivos sensibles

---

## 🚀 Setup inicial (primera vez)

### 1️⃣ Crear tus credenciales locales

```bash
# Navega al directorio de Services
cd BusinessHabitDashboardApp/Services/

# Copia el template a un archivo real
cp SupabaseCredentials.swift.template SupabaseCredentials.swift
```

### 2️⃣ Editar con tus credenciales

Abre `SupabaseCredentials.swift` y reemplaza con tus datos reales:

```swift
import Foundation

enum SupabaseCredentials {
    static let projectURL = URL(string: "https://TU-PROYECTO-ID.supabase.co")!
    static let anonKey = "TU_ANON_KEY_REAL_AQUI"
}
```

### 3️⃣ Obtener credenciales de Supabase

1. Ve a [supabase.com](https://supabase.com) → tu proyecto
2. Sidebar → **Settings** → **API**
3. Copia:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **Project API keys** → **anon public**: `eyJhbGc...` (clave larga)

### 4️⃣ Compilar y ejecutar

1. Abre `BusinessHabitDashboardApp.xcodeproj` en Xcode
2. ⌘R para compilar y ejecutar
3. Si hay errores, verifica que `SupabaseCredentials.swift` existe y tiene tus credenciales

---

## 🔐 Seguridad garantizada

### ¿Cómo funciona la protección?

El archivo `.gitignore` contiene:

```gitignore
# 🔒 SECRETS - NEVER COMMIT THESE FILES
BusinessHabitDashboardApp/Services/SupabaseCredentials.swift
.env
.env.local
*.key
*.pem
```

Esto asegura que **NUNCA** se suban tus credenciales a git, incluso si haces `git add .`

### ✅ Verificar antes de hacer push

```bash
# Ver qué archivos se subirán
git status

# Deberías ver SOLO el template:
✅ BusinessHabitDashboardApp/Services/SupabaseCredentials.swift.template

# NO deberías ver (está protegido):
❌ BusinessHabitDashboardApp/Services/SupabaseCredentials.swift
```

---

## 👥 Para otros desarrolladores que clonen el repo

Si alguien clona tu repositorio público, deberá seguir estos pasos:

1. **Clonar el repositorio**
   ```bash
   git clone https://github.com/tu-usuario/tu-repo.git
   cd tu-repo
   ```

2. **Crear archivo de credenciales**
   ```bash
   cd BusinessHabitDashboardApp/Services/
   cp SupabaseCredentials.swift.template SupabaseCredentials.swift
   ```

3. **Configurar con SUS propias credenciales**
   - Crear su propio proyecto en Supabase
   - Copiar sus propias keys
   - Editar `SupabaseCredentials.swift` con sus datos

4. **Compilar**
   ```bash
   # Abrir Xcode y compilar normalmente
   open BusinessHabitDashboardApp.xcodeproj
   ```

---

## 🏗️ Arquitectura del sistema

### SupabaseCredentials.swift (gitignored)
```swift
// Este archivo contiene TUS credenciales reales
// NUNCA se sube a git
enum SupabaseCredentials {
    static let projectURL = URL(string: "https://real-id.supabase.co")!
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### SupabaseCredentials.swift.template (en git)
```swift
// Este archivo es una plantilla para otros desarrolladores
// SÍ se sube a git, pero sin credenciales reales
enum SupabaseCredentials {
    static let projectURL = URL(string: "https://YOUR-PROJECT-ID.supabase.co")!
    static let anonKey = "YOUR_ANON_KEY_HERE"
}
```

### SupabaseConfig.swift (en git)
```swift
// Lee las credenciales del archivo SupabaseCredentials.swift
enum SupabaseConfig {
    static var projectURL: URL {
        return SupabaseCredentials.projectURL
    }

    static var anonKey: String {
        return SupabaseCredentials.anonKey
    }
}
```

Todos los servicios (AuthService, HabitService, ExpenseService) usan `SupabaseConfig.projectURL` y `SupabaseConfig.anonKey`, nunca acceden directamente a las credenciales.

---

## 🚀 Para CI/CD (GitHub Actions, Xcode Cloud)

Cuando configures integración continua:

### GitHub Actions

```yaml
- name: Create Supabase Credentials
  env:
    SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
    SUPABASE_ANON_KEY: ${{ secrets.SUPABASE_ANON_KEY }}
  run: |
    cat > BusinessHabitDashboardApp/Services/SupabaseCredentials.swift <<EOF
    import Foundation

    enum SupabaseCredentials {
        static let projectURL = URL(string: "$SUPABASE_URL")!
        static let anonKey = "$SUPABASE_ANON_KEY"
    }
    EOF

- name: Build
  run: xcodebuild -project BusinessHabitDashboardApp.xcodeproj ...
```

1. Agrega secrets en GitHub: Settings → Secrets and variables → Actions
2. Crea `SUPABASE_URL` y `SUPABASE_ANON_KEY`
3. El workflow generará el archivo antes de compilar

---

## 🆕 Nuevas features implementadas

### Autenticación
- ✅ **LoginView** - Vista de inicio de sesión limpia
- ✅ **SignUpView** - Vista de registro separada con validación
- ✅ Confirmación de contraseña
- ✅ Validación en tiempo real
- ✅ Auto-login después de registro exitoso
- ✅ Sesión persistente con JWT

### Diseño mejorado
- ✅ Iconos con gradientes
- ✅ Campos con fondos grises redondeados
- ✅ Navegación fluida entre Login/SignUp
- ✅ Mensajes de error claros
- ✅ Botones deshabilitados según validaciones

---

## ❓ Solución de problemas

### Error: "Cannot find 'SupabaseCredentials' in scope"

**Causa**: El archivo `SupabaseCredentials.swift` no existe o no está agregado al proyecto.

**Solución**:
1. Verifica que existe: `ls BusinessHabitDashboardApp/Services/SupabaseCredentials.swift`
2. Si no existe, créalo desde el template: `cp SupabaseCredentials.swift.template SupabaseCredentials.swift`
3. Agrega tus credenciales reales
4. Limpia y recompila: Product → Clean Build Folder (⇧⌘K)

### Error: "Invalid URL" al compilar

**Causa**: La URL en `SupabaseCredentials.swift` no es válida.

**Solución**:
```swift
// ❌ MAL (sin https://)
static let projectURL = URL(string: "xxxxx.supabase.co")!

// ✅ BIEN (con https://)
static let projectURL = URL(string: "https://xxxxx.supabase.co")!
```

### El archivo se sube a git por error

**Causa**: El `.gitignore` no está funcionando o el archivo ya estaba tracked.

**Solución**:
```bash
# Remover del tracking de git (sin borrar el archivo)
git rm --cached BusinessHabitDashboardApp/Services/SupabaseCredentials.swift

# Verificar que .gitignore está correcto
cat .gitignore | grep SupabaseCredentials.swift

# Debería mostrar:
# BusinessHabitDashboardApp/Services/SupabaseCredentials.swift
```

---

## 📊 Comparación con otros métodos

| Método | Seguridad | Simplicidad | Usado en | Recomendado |
|--------|-----------|-------------|----------|-------------|
| **Template Files** (actual) | ✅ Alta | ✅ Muy simple | React, Node.js | ✅ Sí |
| `.xcconfig` files | ✅ Alta | ⚠️ Complicado | iOS nativo | ⚠️ Problemático |
| Hardcoded strings | ❌ Ninguna | ✅ Simple | ❌ Nunca | ❌ No |
| Environment variables | ✅ Alta | ⚠️ Medio | Backend | ⚠️ No en iOS |
| Keychain | ✅ Muy alta | ❌ Complejo | Apps enterprise | ⚠️ Overkill para API keys públicas |

---

## 📚 Referencias

- [Supabase API Keys](https://supabase.com/docs/guides/api/api-keys) - Documentación oficial
- [GitHub .gitignore](https://docs.github.com/en/get-started/getting-started-with-git/ignoring-files) - Protección de archivos
- [Swift Package Manager Secrets](https://www.swiftbysundell.com/articles/handling-secrets-in-swift-packages/) - Patrones similares

---

✅ **Sistema configurado y protegido** - Tus credenciales están seguras y nunca se subirán a GitHub.
