# Business & Habit Dashboard iOS

App iOS profesional (SwiftUI + MVVM) para seguimiento de hábitos y gastos, conectada a Supabase con autenticación segura.

## ✅ Características implementadas

- ✅ **Arquitectura MVVM** separada por capas
- ✅ **Autenticación**:
  - Sign Up con validación de contraseña
  - Login con normalización de emails
  - Vistas separadas con diseño moderno
  - Confirmación de contraseña en tiempo real
  - Botones para mostrar/ocultar contraseñas
  - Manejo de errores específicos (rate limit)
  - Sesión persistente con JWT
- ✅ **Gestión de Hábitos**:
  - CRUD completo (crear, leer, actualizar, eliminar)
  - API integrada con Supabase
- ✅ **Gestión de Gastos**:
  - CRUD completo por categorías
  - API integrada con Supabase
  - Formato de moneda en euros (€)
- ✅ **Dashboard**:
  - Métricas en tiempo real
  - Gráficos con **Swift Charts**
- ✅ **Seguridad**:
  - Credenciales en archivo separado (no en código)
  - Sistema de template para desarrollo colaborativo
  - `.gitignore` configurado para proteger credenciales

> 🔒 **Proyecto listo para ser público**: Las credenciales nunca se suben a git.

---

## 📁 Estructura del proyecto

```text
BusinessHabitDashboardApp/
├── BusinessHabitDashboardApp.xcodeproj
├── Info.plist                          # Info.plist source (variables serán inyectadas)
├── Secrets.xcconfig                    # 🔒 TUS CREDENCIALES (gitignored)
├── Secrets-template.xcconfig           # Plantilla para configurar
├── .gitignore                          # Protección de credenciales
├── SETUP_SEGURO.md                     # Guía de configuración segura
└── BusinessHabitDashboardApp/
    ├── Models/
    │   ├── Habit.swift                 # Modelo de hábitos
    │   ├── Expense.swift               # Modelo de gastos
    │   └── SessionUser.swift           # Modelo de sesión
    ├── Services/
    │   ├── SupabaseConfig.swift            # Configuración de Supabase
    │   ├── SupabaseCredentials.swift       # 🔒 TUS CREDENCIALES (gitignored)
    │   ├── SupabaseCredentials.swift.template  # Template sin credenciales
    │   ├── AuthService.swift               # Servicio de autenticación
    │   ├── APIClient.swift                 # Cliente HTTP genérico
    │   ├── HabitService.swift              # CRUD de hábitos
    │   └── ExpenseService.swift            # CRUD de gastos
    ├── ViewModels/
    │   ├── AuthViewModel.swift         # Lógica de autenticación
    │   ├── HabitViewModel.swift        # Lógica de hábitos
    │   └── ExpenseViewModel.swift      # Lógica de gastos
    ├── Views/
    │   ├── LoginView.swift             # Pantalla de login
    │   ├── SignUpView.swift            # Pantalla de registro
    │   ├── DashboardView.swift         # Dashboard principal
    │   ├── HabitsView.swift            # Lista de hábitos
    │   ├── ExpensesView.swift          # Lista de gastos (formato EUR)
    │   └── RootView.swift              # Vista raíz con navegación
    └── Docs/
        └── SUPABASE_SETUP.md           # Instrucciones de Supabase
```

---

## 🚀 Setup rápido (5 minutos)

### 1️⃣ Configurar Supabase

1. Crea un proyecto gratuito en [supabase.com](https://supabase.com)
2. Crea las tablas `habits` y `expenses` (SQL en `Docs/SUPABASE_SETUP.md`)
3. Activa Row Level Security (RLS) con las políticas incluidas
4. Copia tu **Project URL** y **anon public key**

### 2️⃣ Configurar credenciales (seguro)

```bash
# Copia el template
cd BusinessHabitDashboardApp/Services/
cp SupabaseCredentials.swift.template SupabaseCredentials.swift
```

Edita `SupabaseCredentials.swift` con tus credenciales:

```swift
enum SupabaseCredentials {
    static let projectURL = URL(string: "https://TU-PROYECTO-ID.supabase.co")!
    static let anonKey = "TU_ANON_KEY_AQUI"
}
```

⚠️ **IMPORTANTE**: Este archivo está en `.gitignore` y **NUNCA** se subirá a git.

### 3️⃣ Compilar y ejecutar

1. Abre `BusinessHabitDashboardApp.xcodeproj` en Xcode
2. Selecciona un simulador (iPhone 15 Pro recomendado)
3. ⌘R para compilar y ejecutar
4. Crea una cuenta con "Registrarse"

---

## 🔐 Seguridad de credenciales

Este proyecto usa un **sistema de archivos template**:

✅ **Lo que SÍ está en git:**
- `SupabaseCredentials.swift.template` - Plantilla SIN credenciales
- `SupabaseConfig.swift` - Código que lee las credenciales

❌ **Lo que NUNCA está en git:**
- `SupabaseCredentials.swift` - TUS credenciales reales (gitignored)

**Para otros desarrolladores que clonen el repo:**
```bash
cp SupabaseCredentials.swift.template SupabaseCredentials.swift
# Editar con sus propias credenciales
```

Las credenciales **nunca** están en el código que se sube a git.

---

## 🧭 Roadmap

### ✅ Completado
- [x] Autenticación con Sign Up y Login (vistas separadas)
- [x] Validación de contraseñas en tiempo real
- [x] CRUD de hábitos con Supabase
- [x] CRUD de gastos con Supabase (formato EUR)
- [x] Dashboard con métricas y gráficos
- [x] Sistema de seguridad para credenciales (template)
- [x] Arquitectura MVVM limpia

### 🚧 Próximas mejoras
- [ ] **Vista de Perfil con botón de Logout** (prioridad alta)
- [ ] Navegación por tabs: Dashboard / Hábitos / Gastos / Perfil
- [ ] Reset password / recuperación de cuenta
- [ ] Persistencia offline con CoreData
- [ ] Notificaciones locales para recordatorios de hábitos
- [ ] Tests unitarios de ViewModels
- [ ] Tests de integración de servicios
- [ ] Capturas de pantalla y GIF para README
- [ ] Modo oscuro personalizado
- [ ] Sincronización en tiempo real (Supabase Realtime)

---

## 📤 Subir a GitHub (seguro)

```bash
# 1. Inicializar repositorio
git init
git add .
git commit -m "feat: iOS MVVM app with Supabase - initial commit"

# 2. Crear repositorio en GitHub y conectar
git branch -M main
git remote add origin https://github.com/tu-usuario/tu-repo.git
git push -u origin main
```

**✅ Verificación de seguridad antes de push:**
```bash
# Asegúrate de que las credenciales NO se suban
git status

# Deberías ver SOLO el template:
# ✅ BusinessHabitDashboardApp/Services/SupabaseCredentials.swift.template

# NO deberías ver (está en .gitignore):
# ❌ BusinessHabitDashboardApp/Services/SupabaseCredentials.swift

# Si ves el archivo con credenciales, verifica .gitignore
```

---

## 🛠 Tecnologías

- **Swift 5.9+** / **SwiftUI**
- **iOS 17.0+**
- **Supabase** (Backend as a Service)
  - Auth (autenticación)
  - PostgreSQL (base de datos)
  - Row Level Security (RLS)
- **Swift Charts** (gráficos nativos)
- **async/await** (concurrencia moderna)
- **MVVM** (arquitectura)

---

## 📝 Licencia

Este proyecto es de código abierto. Úsalo como base para tus propios proyectos.

---

## 🤝 Contribuciones

¡Las contribuciones son bienvenidas! Si encuentras un bug o tienes una mejora:

1. Fork el proyecto
2. Crea una rama (`git checkout -b feature/mejora`)
3. Commit tus cambios (`git commit -m 'feat: nueva característica'`)
4. Push a la rama (`git push origin feature/mejora`)
5. Abre un Pull Request

---

**Hecho con ❤️ usando SwiftUI y Supabase**

