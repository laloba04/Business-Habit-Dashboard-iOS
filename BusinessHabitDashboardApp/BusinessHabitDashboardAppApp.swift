//
//  BusinessHabitDashboardAppApp.swift
//  BusinessHabitDashboardApp
//
//  Created by Maria Bravo Angulo on 10/2/26.
//

import SwiftUI

@main
struct BusinessHabitDashboardAppApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

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
