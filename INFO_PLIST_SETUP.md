# ⚠️ CONFIGURACIÓN REQUERIDA: URL Scheme en Info.plist

## 🎯 Acción requerida

Para que los deep links de recuperación de contraseña funcionen, **DEBES** configurar el URL scheme en Xcode.

## 📝 Pasos para configurar

### Usando Xcode (Método Recomendado):

1. Abre el proyecto `BusinessHabitDashboardApp.xcodeproj` en Xcode
2. En el navegador de proyecto (panel izquierdo), selecciona el proyecto
3. Selecciona el target **BusinessHabitDashboardApp**
4. Ve a la pestaña **Info**
5. Busca **URL Types** y expándelo (si no existe, créalo)
6. Haz clic en el botón **+** para añadir un nuevo URL Type
7. Configura:
   - **Identifier:** `com.businesshabit.auth`
   - **URL Schemes:** `businesshabit`
8. Guarda (Cmd + S)

### Editando Info.plist directamente:

Si prefieres editar el archivo `Info.plist` manualmente:

1. Localiza el archivo `Info.plist` en tu proyecto
2. Haz clic derecho → Open As → Source Code
3. Añade este bloque XML antes del `</dict>` final:

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

1. Abre `Info.plist` en Xcode
2. Busca `CFBundleURLTypes`
3. Verifica que aparezca:
   - URL Schemes: businesshabit
   - URL identifier: com.businesshabit.auth

## 🧪 Probar que funciona

Desde Safari en el simulador, escribe en la barra de direcciones:

```
businesshabit://reset-password#access_token=test&type=recovery
```

Safari debería preguntar si quieres abrir la app. Si lo hace, ¡la configuración está correcta!

## 📱 También necesitas configurar Supabase

En el dashboard de Supabase (https://app.supabase.com):

1. Ve a **Authentication** → **URL Configuration**
2. En **Redirect URLs**, añade:
   ```
   businesshabit://reset-password
   ```
3. Guarda los cambios

Sin esto, Supabase no permitirá el redirect a la app.

## ❓ ¿Por qué no se puede configurar automáticamente?

Los URL schemes requieren modificar el archivo `Info.plist` del bundle de la aplicación, lo cual solo se puede hacer a través de Xcode o editando manualmente el archivo. No es posible configurarlo programáticamente en Swift.

## 📚 Más información

Consulta `/Docs/DEEP_LINKS_SETUP.md` para documentación completa sobre deep links.
