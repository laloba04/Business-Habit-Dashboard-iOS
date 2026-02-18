//
//  BusinessHabitDashboardAppApp.swift
//  BusinessHabitDashboardApp
//
//  Created by Maria Bravo Angulo on 10/2/26.
//

import SwiftUI
import UserNotifications

@main
struct BusinessHabitDashboardAppApp: App {
    init() {
        // Configurar el delegate de notificaciones para manejar interacciones
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

// Delegate para manejar notificaciones
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    // Mostrar notificaciones incluso cuando la app está en primer plano
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    // Manejar cuando el usuario toca una notificación
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Aquí podrías navegar a la vista de hábitos si lo deseas
        print("Notificación tocada: \(response.notification.request.identifier)")
        completionHandler()
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
