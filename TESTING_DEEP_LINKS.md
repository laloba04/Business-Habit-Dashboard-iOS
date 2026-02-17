# 🧪 Guía de Testing - Deep Links para Reset Password

## ⚠️ Antes de comenzar

**IMPORTANTE:** Debes configurar el URL scheme antes de poder probar. Ver `INFO_PLIST_SETUP.md`

## 📋 Checklist de Configuración

- [ ] URL scheme "businesshabit" configurado en Info.plist
- [ ] Redirect URL configurado en Supabase dashboard
- [ ] App compilada y ejecutándose sin errores
- [ ] Email de prueba configurado en Supabase

## 🧪 Test 1: Verificar URL Scheme

**Objetivo:** Confirmar que iOS reconoce el URL scheme

**Pasos:**
1. Ejecuta la app en el simulador
2. Abre Safari en el simulador
3. En la barra de direcciones, escribe:
   ```
   businesshabit://reset-password#access_token=test123&type=recovery
   ```
4. Presiona Enter

**Resultado esperado:**
- Safari muestra un diálogo: "Abrir en Business & Habit Dashboard?"
- Al aceptar, la app se abre
- Aparece ResetPasswordView
- En la consola de Xcode: `✅ Deep link procesado: Token de recuperación recibido`

**Si falla:**
- Verifica que el URL scheme esté configurado correctamente
- Reinstala la app (a veces Xcode no actualiza la configuración)
- Revisa la consola de Xcode para errores

---

## 🧪 Test 2: Parsing de Parámetros

**Objetivo:** Verificar que el token se extrae correctamente

**Pasos:**
1. Abre Safari en el simulador
2. Prueba diferentes formatos de URL:
   ```
   businesshabit://reset-password#access_token=ABC123&type=recovery
   businesshabit://reset-password#type=recovery&access_token=XYZ789
   ```

**Resultado esperado:**
- Ambas URLs deben funcionar
- El token se extrae correctamente sin importar el orden
- La app navega a ResetPasswordView

**Si falla:**
- Revisa el método `parseURLFragment()` en RootView
- Añade prints para debuggear: `print("Fragment:", fragment)`

---

## 🧪 Test 3: Validación de URL

**Objetivo:** Verificar que URLs inválidas se ignoran

**Pasos:**
1. Abre Safari en el simulador
2. Prueba URLs inválidas:
   ```
   businesshabit://reset-password
   businesshabit://other-path#access_token=test
   http://example.com/reset
   ```

**Resultado esperado:**
- La app NO se abre (o no navega a ResetPasswordView)
- En consola: mensajes de warning sobre URL inválida

**Si falla:**
- Revisa las validaciones en `handleDeepLink()`:
  - `url.scheme == "businesshabit"`
  - `url.host == "reset-password"`
  - `params["access_token"]` exists
  - `params["type"] == "recovery"`

---

## 🧪 Test 4: UI de ResetPasswordView

**Objetivo:** Verificar que la vista se muestra correctamente

**Pasos:**
1. Abre la app con deep link válido
2. Verifica los elementos visuales:
   - [ ] Gradiente de fondo (azul)
   - [ ] Icono lock.rotation animado
   - [ ] Título "Nueva contraseña"
   - [ ] Card con efecto .ultraThinMaterial
   - [ ] Campo "Nueva contraseña" con icono de candado
   - [ ] Botón show/hide contraseña funciona
   - [ ] Campo "Confirmar contraseña"
   - [ ] Botón "Cambiar contraseña" deshabilitado inicialmente

**Resultado esperado:**
- Todos los elementos presentes y bien alineados
- Animaciones suaves al aparecer
- Colores consistentes con el resto de la app

---

## 🧪 Test 5: Validación de Contraseña

**Objetivo:** Verificar validaciones en tiempo real

**Pasos:**
1. En ResetPasswordView, ingresa contraseñas:

   | Nueva contraseña | Confirmar contraseña | Resultado esperado |
   |------------------|----------------------|-------------------|
   | `abc` | (vacío) | Indicador rojo "Débil", botón deshabilitado |
   | `abc123` | `abc123` | Indicador naranja "Aceptable", checkmark verde, botón habilitado |
   | `password123` | `password` | Indicador naranja/verde, ❌ rojo "No coinciden", botón deshabilitado |
   | `MySecurePass123` | `MySecurePass123` | Indicador verde "Excelente", checkmark verde, botón habilitado |

**Resultado esperado:**
- Indicador de fortaleza actualiza en tiempo real
- Validación de coincidencia funciona correctamente
- Botón solo se habilita cuando todo es válido

---

## 🧪 Test 6: Flujo Completo con Email

**Objetivo:** Probar el flujo completo desde el email de Supabase

**Preparación:**
1. Configura un email de prueba en Supabase
2. Asegúrate de tener acceso a esa bandeja de entrada

**Pasos:**
1. Abre la app
2. En LoginView, toca "¿Olvidaste tu contraseña?"
3. Ingresa tu email de prueba
4. Toca "Enviar instrucciones"
5. Espera el email (puede tomar 1-2 minutos)
6. **EN TU DISPOSITIVO FÍSICO (no simulador):**
   - Abre el email en Mail/Gmail
   - Toca el link de recuperación

**Resultado esperado:**
1. Email llega con link de recuperación
2. Link tiene formato: `businesshabit://reset-password#access_token=...`
3. Al tocar el link, iOS pregunta si abrir la app
4. La app se abre automáticamente
5. Aparece ResetPasswordView con el token cargado
6. Puedes cambiar la contraseña exitosamente

**Si falla:**
- Verifica que Supabase tenga configurado el redirect URL
- Revisa el email: ¿tiene el link correcto?
- Prueba desde un dispositivo real (no simulador)
- Revisa logs de Supabase para ver si el email se envió

---

## 🧪 Test 7: Cambio de Contraseña

**Objetivo:** Verificar que la contraseña se actualiza en Supabase

**Pasos:**
1. Llega a ResetPasswordView (usando deep link o email)
2. Ingresa una nueva contraseña válida (ej: `newpass123`)
3. Confirma la contraseña
4. Toca "Cambiar contraseña"

**Resultado esperado:**
1. Botón muestra ProgressView
2. Después de ~1-2 segundos, aparece vista de éxito:
   - Checkmark verde
   - "¡Contraseña actualizada!"
   - Botón "Ir al inicio de sesión"
3. Haptic feedback de éxito
4. Al tocar "Ir al inicio de sesión", vuelve a LoginView
5. Puedes hacer login con la nueva contraseña

**Si falla:**
- Revisa la consola para errores de red
- Verifica que el token sea válido (no expirado)
- Revisa que AuthService.confirmPasswordReset() esté usando el endpoint correcto
- Verifica que el token se esté enviando en el header Authorization

---

## 🧪 Test 8: Manejo de Errores

**Objetivo:** Verificar que los errores se manejan correctamente

**Casos a probar:**

### Token expirado
1. Usa un deep link con un token antiguo (>1 hora)
2. Intenta cambiar la contraseña

**Resultado esperado:**
- Mensaje de error: "Error al cambiar contraseña" o similar
- Haptic feedback de error
- Vista NO cambia a success

### Token inválido
1. Usa un deep link con token falso: `businesshabit://reset-password#access_token=fake&type=recovery`
2. Intenta cambiar la contraseña

**Resultado esperado:**
- Mensaje de error
- No se actualiza la contraseña

### Sin conexión a internet
1. Desactiva WiFi/datos
2. Intenta cambiar la contraseña

**Resultado esperado:**
- Mensaje de error de red
- Botón vuelve a estado normal

---

## 🧪 Test 9: Experiencia de Usuario

**Objetivo:** Verificar que la UX sea fluida

**Aspectos a verificar:**
- [ ] Animaciones suaves al mostrar ResetPasswordView
- [ ] Transiciones entre estados (form → success)
- [ ] Haptic feedback en todos los botones
- [ ] Show/hide password funciona sin glitches
- [ ] Teclado se cierra al tocar fuera
- [ ] Scroll funciona correctamente en pantallas pequeñas
- [ ] Colores consistentes (gradientes, textos, errores)
- [ ] Indicador de fortaleza se actualiza sin lag
- [ ] ProgressView se muestra durante la carga
- [ ] Success state es claro y celebratorio

---

## 🧪 Test 10: Edge Cases

**Objetivo:** Probar casos límite

**Casos a probar:**

1. **Usuario ya logueado:**
   - Deep link llega mientras está en la app (logueado)
   - ¿Qué pasa?
   - **Resultado esperado:** Deep link se ignora o muestra advertencia

2. **Deep link llega en background:**
   - App en background
   - Toca link en email
   - **Resultado esperado:** App pasa a foreground y muestra ResetPasswordView

3. **Múltiples deep links rápidos:**
   - Toca varios links de reset seguidos
   - **Resultado esperado:** Solo procesa uno, sin crashes

4. **Contraseña muy larga:**
   - Ingresa contraseña de 100+ caracteres
   - **Resultado esperado:** Se acepta o hay límite razonable

5. **Caracteres especiales:**
   - Contraseña con emojis: `Pass🔒word123`
   - **Resultado esperado:** Se acepta o se rechaza con mensaje claro

---

## 📊 Checklist Final

Antes de considerar el feature completo, verifica:

- [ ] URL scheme configurado en Info.plist
- [ ] Redirect URL configurado en Supabase
- [ ] Deep link abre la app correctamente
- [ ] Token se extrae del URL
- [ ] ResetPasswordView se muestra
- [ ] Validaciones funcionan
- [ ] Contraseña se actualiza en Supabase
- [ ] Puedes loguearte con nueva contraseña
- [ ] Errores se manejan correctamente
- [ ] Animaciones son fluidas
- [ ] Haptic feedback funciona
- [ ] Mensajes en español
- [ ] Documentación completa
- [ ] Sin warnings en consola
- [ ] Sin crashes

---

## 🐛 Debugging Tips

### Ver logs de deep links:
Busca en la consola de Xcode:
```
✅ Deep link procesado: Token de recuperación recibido
⚠️ Deep link: No se encontró access_token o type válido
⚠️ Deep link: No se encontró fragment en URL
```

### Debugging del token:
Añade un print temporal en RootView:
```swift
if let accessToken = params["access_token"] {
    print("🔑 Token recibido:", accessToken)
    authViewModel.resetToken = accessToken
}
```

### Debugging de AuthService:
Añade prints en confirmPasswordReset:
```swift
print("📡 Enviando request a:", endpoint)
print("🔐 Token:", accessToken.prefix(10) + "...")
```

### Ver respuesta de Supabase:
```swift
if let responseString = String(data: data, encoding: .utf8) {
    print("📨 Respuesta:", responseString)
}
```

---

## 📞 Soporte

Si encuentras problemas:

1. Revisa la consola de Xcode para errores
2. Verifica la configuración (Info.plist, Supabase)
3. Prueba con deep links de test primero
4. Consulta `/Docs/DEEP_LINKS_SETUP.md`
5. Revisa los logs de Supabase dashboard

---

## ✅ Test Exitoso

Si todos los tests pasan:
- ✅ Deep links funcionando correctamente
- ✅ Flujo de reset password completo
- ✅ UX profesional y fluida
- ✅ Errores manejados correctamente
- ✅ Código listo para producción

¡Felicidades! 🎉
