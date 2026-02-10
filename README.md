# Business & Habit Dashboard iOS

Starter profesional para una app iOS (SwiftUI + MVVM) de hábitos y gastos conectada a Supabase.

## ✅ Qué incluye este starter

- Arquitectura **MVVM** separada por capas.
- Modelos base: `Habit`, `Expense`, `SessionUser`.
- Servicios API con `async/await` para:
  - Auth (login + registro email/password)
  - CRUD básico de hábitos
  - CRUD básico de gastos
- Dashboard con métricas y gráfico simple usando **Swift Charts**.
- Base para sesión persistida (`UserDefaults`) con JWT.
- Documentación para configurar Supabase y siguientes pasos.

> Este repositorio está preparado como **base de código** para abrir en Xcode y continuar implementación visual / navegación completa.

---

## 📁 Estructura

```text
BusinessHabitDashboard/
  Models/
  Services/
  ViewModels/
  Views/
  Resources/
Docs/
README.md
```

---

## 🚀 Cómo empezar

1. Crea un nuevo proyecto iOS en Xcode (App, SwiftUI, iOS 17+ recomendado).
2. Copia los archivos de `BusinessHabitDashboard/` dentro de tu target.
3. En `YourAppNameApp.swift`, usa `RootView()` como vista inicial.
4. `ContentView.swift` es opcional: puedes borrarlo o dejarlo fuera del target si ya no se usa.
5. Agrega framework **Charts** (Apple) si no está importado automáticamente.
6. Configura tus variables de Supabase en `SupabaseConfig.swift`.
7. Define las tablas y políticas RLS en Supabase (ver `Docs/SUPABASE_SETUP.md`).
8. Ejecuta la app.

---

## 🔐 Variables necesarias

Edita `BusinessHabitDashboard/Services/SupabaseConfig.swift`:

- `projectURL`
- `anonKey`

**Nunca subas claves sensibles de producción al repositorio.**

---

## 🧭 Roadmap sugerido para portfolio

- [ ] Pantallas completas de autenticación (registro, reset password).
- [ ] Navegación por tabs: Dashboard / Hábitos / Gastos / Perfil.
- [ ] Persistencia offline con CoreData.
- [ ] Notificaciones locales para hábitos.
- [ ] Tests unitarios de ViewModels.
- [ ] Capturas y GIF para README de GitHub.

---

## 📤 Subir a GitHub

```bash
git init
git add .
git commit -m "feat: bootstrap iOS MVVM app with Supabase services"
git branch -M main
git remote add origin <tu-repo-url>
git push -u origin main
```
