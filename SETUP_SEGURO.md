# 🔒 Configuración Segura de Credenciales Supabase

## ✅ Archivos creados

- ✅ `.gitignore` - Previene que se suban credenciales a git
- ✅ `Secrets.xcconfig` - Contiene tus credenciales (YA configurado con tus keys)
- ✅ `Secrets-template.xcconfig` - Plantilla para otros desarrolladores
- ✅ `SupabaseConfig.swift` - Modificado para leer credenciales de forma segura

## 📋 Pasos para configurar Xcode (IMPORTANTE)

### 1. Agregar Secrets.xcconfig al proyecto Xcode

1. Abre `BusinessHabitDashboardApp.xcodeproj` en Xcode
2. En el Project Navigator (panel izquierdo), **arrastra** el archivo `Secrets.xcconfig` desde Finder al proyecto
   - O haz clic derecho en la raíz del proyecto → "Add Files to BusinessHabitDashboardApp..."
   - Navega a la raíz del proyecto y selecciona `Secrets.xcconfig`
   - ⚠️ **IMPORTANTE**: Desmarca "Copy items if needed" (el archivo ya está en el lugar correcto)
   - Asegúrate de que "Add to targets" incluya tu app target

### 2. Configurar el target para usar Secrets.xcconfig

1. Selecciona el proyecto en el Project Navigator (icono azul superior)
2. En la sección "PROJECT" (no TARGETS), selecciona `BusinessHabitDashboardApp`
3. Ve a la pestaña **"Info"**
4. En "Configurations", expande "Debug" y "Release"
5. Para **Debug** y **Release**:
   - Haz clic en el dropdown que dice "None"
   - Selecciona **"Secrets"** (aparecerá si agregaste correctamente el .xcconfig)

   Debería verse así:
   ```
   Debug   → Secrets
   Release → Secrets
   ```

### 3. Agregar las variables al Info.plist

1. Selecciona tu target `BusinessHabitDashboardApp` en TARGETS
2. Ve a la pestaña **"Info"**
3. Haz clic derecho en cualquier fila → **"Add Row"**
4. Agrega estas dos keys:

   | Key | Type | Value |
   |-----|------|-------|
   | `SUPABASE_URL` | String | `$(SUPABASE_URL)` |
   | `SUPABASE_ANON_KEY` | String | `$(SUPABASE_ANON_KEY)` |

   ⚠️ **IMPORTANTE**: Escribe exactamente `$(SUPABASE_URL)` y `$(SUPABASE_ANON_KEY)` incluyendo los paréntesis y símbolo de dólar. Estas son referencias a las variables del .xcconfig.

### 4. Verificar que funciona

1. **Limpia el build**: Product → Clean Build Folder (⇧⌘K)
2. **Compila el proyecto**: Product → Build (⌘B)
3. Si hay errores de "SUPABASE_URL no encontrada", revisa los pasos anteriores

## 🧪 Prueba rápida

Puedes verificar que las credenciales se cargan correctamente agregando un print temporal:

```swift
// En BusinessHabitDashboardAppApp.swift, dentro de init()
print("✅ Supabase URL:", SupabaseConfig.projectURL)
print("✅ Anon Key:", String(SupabaseConfig.anonKey.prefix(20)) + "...")
```

## 🔐 Seguridad garantizada

### ✅ Lo que SÍ se sube a git:
- `Secrets-template.xcconfig` (plantilla sin credenciales reales)
- `SupabaseConfig.swift` (código que lee variables, sin credenciales hardcodeadas)
- `.gitignore` (protección)
- Este archivo de instrucciones

### ❌ Lo que NUNCA se sube a git:
- `Secrets.xcconfig` (contiene tus credenciales reales)
- Archivos `.env`, `.key`, `.pem`

## 👥 Configuración para otros desarrolladores

Si alguien más clona el repositorio:

1. Copiar `Secrets-template.xcconfig` → `Secrets.xcconfig`
2. Reemplazar las credenciales con sus propias keys de Supabase
3. Seguir los pasos de configuración Xcode arriba

## 🚀 Para CI/CD (GitHub Actions, Xcode Cloud)

Cuando configures CI/CD en el futuro:

1. Agrega `SUPABASE_URL` y `SUPABASE_ANON_KEY` como **Secrets** en tu plataforma CI
2. El workflow generará un `Secrets.xcconfig` automáticamente antes del build
3. Ejemplo para GitHub Actions:

```yaml
- name: Create Secrets.xcconfig
  env:
    SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
    SUPABASE_ANON_KEY: ${{ secrets.SUPABASE_ANON_KEY }}
  run: |
    cat > Secrets.xcconfig <<EOF
    SUPABASE_URL = $SUPABASE_URL
    SUPABASE_ANON_KEY = $SUPABASE_ANON_KEY
    EOF
```

## ❓ Solución de problemas

### Error: "SUPABASE_URL no encontrada"

1. Verifica que `Secrets.xcconfig` está agregado al proyecto en Xcode
2. Verifica que el proyecto usa `Secrets` en Configurations (Debug/Release)
3. Verifica que agregaste las keys al Info.plist con la sintaxis `$(VARIABLE)`
4. Limpia y recompila (⇧⌘K, luego ⌘B)

### El archivo Secrets.xcconfig no aparece en el dropdown

1. Asegúrate de haberlo agregado al proyecto (no solo al filesystem)
2. Debe estar en la raíz del proyecto, al mismo nivel que el .xcodeproj
3. Haz Product → Clean Build Folder y reinicia Xcode

## 📚 Referencias

- [Apple Docs: Build Configuration](https://developer.apple.com/documentation/xcode/adding-a-build-configuration-file-to-your-project)
- [Supabase Security Best Practices](https://supabase.com/docs/guides/api/api-keys)

---

✅ **Configuración completada** - Tus credenciales ahora están protegidas y no se subirán a git.
