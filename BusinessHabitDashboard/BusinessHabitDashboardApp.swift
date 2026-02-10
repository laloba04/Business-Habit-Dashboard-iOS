import SwiftUI

// Punto de entrada de la app.
// Aquí decidimos cuál es la vista raíz que se renderiza al abrir la aplicación.

@main
struct BusinessHabitDashboardApp: App {
    // Scene principal de la app (una sola ventana en iPhone).
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
