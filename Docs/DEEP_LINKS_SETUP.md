# Configuración de Deep Links para Reset Password

Esta guía explica cómo configurar los deep links para permitir que los emails de recuperación de contraseña de Supabase abran automáticamente la app.

## 📋 Resumen

Los deep links permiten que URLs personalizadas abran directamente la aplicación iOS. En este proyecto, usamos el esquema `businesshabit://` para manejar el flujo de recuperación de contraseña.

**URL de deep link:**
```
businesshabit://reset-password#access_token=TOKEN&type=recovery
```

## 🔧 Configuración en Xcode

Hay dos formas de configurar el URL scheme en tu proyecto:

### Opción 1: Usando la interfaz de Xcode (Recomendado)

1. Abre el proyecto en Xcode
2. En el navegador de proyecto (panel izquierdo), selecciona el archivo del proyecto (BusinessHabitDashboardApp.xcodeproj)
3. Selecciona el target **BusinessHabitDashboardApp**
4. Ve a la pestaña **Info**
5. Busca la sección **URL Types** y expándela
6. Haz clic en el botón **+** para añadir un nuevo URL Type
7. Configura los siguientes campos:
   - **Identifier:** `com.businesshabit.auth`
   - **URL Schemes:** `businesshabit`
   - **Role:** `Editor` (por defecto)
8. Guarda los cambios

### Opción 2: Editando Info.plist directamente

Si prefieres editar el archivo Info.plist manualmente:

1. Abre el archivo `Info.plist` en tu proyecto
2. Añade la siguiente configuración:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>businesshabit</string>
        </array>
        <key>CFBundleURLName</key>
        <string>com.businesshabit.auth</string>
    </dict>
</array>
```

## ✅ Verificar la configuración

Después de configurar, verifica que el URL scheme esté registrado correctamente:

1. Abre el archivo `Info.plist` en Xcode
2. Busca la clave `CFBundleURLTypes`
3. Deberías ver un array con un diccionario que contiene:
   - `CFBundleURLSchemes`: ["businesshabit"]
   - `CFBundleURLName`: "com.businesshabit.auth"

## 🧪 Probar los Deep Links

### Desde el Simulador

1. Ejecuta la app en el simulador
2. Abre Safari en el simulador
3. En la barra de direcciones, escribe:
   ```
   businesshabit://reset-password#access_token=test123&type=recovery
   ```
4. Safari debería preguntar si quieres abrir la app
5. Al aceptar, la app debería abrirse y mostrar `ResetPasswordView`

### Desde un dispositivo real

1. Envíate un email a ti mismo con el link:
   ```html
   <a href="businesshabit://reset-password#access_token=test123&type=recovery">
     Reset Password
   </a>
   ```
2. Abre el email en tu iPhone
3. Toca el enlace
4. La app debería abrirse automáticamente

### Con Supabase (Producción)

1. Ve a `ForgotPasswordView` en la app
2. Ingresa tu email
3. Toca "Enviar instrucciones"
4. Revisa tu bandeja de entrada
5. Toca el link en el email
6. La app debería abrirse con `ResetPasswordView`
7. Ingresa tu nueva contraseña
8. Toca "Cambiar contraseña"

## 🔄 Flujo completo

```
Usuario olvida contraseña
    ↓
LoginView → "¿Olvidaste tu contraseña?"
    ↓
ForgotPasswordView → ingresa email → envía request
    ↓
Supabase envía email con link: businesshabit://reset-password#access_token=...
    ↓
Usuario toca el link en su email
    ↓
iOS abre la app Business & Habit Dashboard
    ↓
RootView.onOpenURL detecta el deep link
    ↓
Parsea access_token del URL
    ↓
Guarda token en authViewModel.resetToken
    ↓
Navega a ResetPasswordView
    ↓
Usuario ingresa nueva contraseña
    ↓
authViewModel.confirmPasswordReset() → AuthService.confirmPasswordReset()
    ↓
Supabase actualiza la contraseña
    ↓
Success → Muestra mensaje de éxito
    ↓
Usuario toca "Ir al inicio de sesión"
    ↓
Vuelve a LoginView
```

## 🔍 Debugging

Si los deep links no funcionan:

1. **Verifica que el URL scheme esté configurado:**
   - Revisa `Info.plist` y confirma que `CFBundleURLTypes` esté presente
   - El scheme debe ser exactamente `businesshabit` (sin mayúsculas)

2. **Verifica que Supabase esté enviando el redirect correcto:**
   - El código en `AuthService.resetPassword()` debe incluir:
     ```swift
     "options": [
         "redirectTo": "businesshabit://reset-password"
     ]
     ```

3. **Verifica los logs:**
   - Al abrir un deep link, deberías ver en la consola de Xcode:
     ```
     ✅ Deep link procesado: Token de recuperación recibido
     ```

4. **Verifica el formato del URL:**
   - El URL debe tener el formato exacto:
     ```
     businesshabit://reset-password#access_token=TOKEN&type=recovery
     ```
   - Nota el `#` (fragmento) en lugar de `?` (query)

5. **Reinstala la app:**
   - A veces Xcode no actualiza la configuración de URL schemes
   - Desinstala la app del simulador/dispositivo
   - Vuelve a ejecutar desde Xcode

## 📱 Configuración de Supabase

En el panel de Supabase (https://app.supabase.com):

1. Ve a **Authentication** → **URL Configuration**
2. En **Redirect URLs**, añade:
   ```
   businesshabit://reset-password
   ```
3. Guarda los cambios

Esto es necesario para que Supabase permita el redirect a tu app.

## 🔒 Seguridad

- El `access_token` en el deep link es temporal (expira en ~1 hora)
- El token solo se puede usar una vez para cambiar la contraseña
- Después de cambiar la contraseña, el token queda invalidado
- La app valida que el token esté presente antes de permitir el cambio

## 📚 Archivos relacionados

- `/BusinessHabitDashboardApp/Services/AuthService.swift` - Métodos `resetPassword()` y `confirmPasswordReset()`
- `/BusinessHabitDashboardApp/ViewModels/AuthViewModel.swift` - Manejo del reset token
- `/BusinessHabitDashboardApp/Views/RootView.swift` - Handler de deep links `.onOpenURL`
- `/BusinessHabitDashboardApp/Views/ResetPasswordView.swift` - Vista para nueva contraseña
- `/BusinessHabitDashboardApp/Views/ForgotPasswordView.swift` - Vista para solicitar reset
- `/BusinessHabitDashboardApp/BusinessHabitDashboardAppApp.swift` - Documentación de configuración

## 🆘 Soporte

Si tienes problemas con los deep links:

1. Revisa los logs de Xcode
2. Verifica la configuración de Supabase
3. Prueba con un URL de test primero
4. Reinstala la app

## ✨ Mejoras futuras

- Añadir Universal Links (https://) para mejor UX
- Validar expiración del token antes de mostrar la vista
- Añadir soporte para deep links adicionales (confirmación de email, etc.)
