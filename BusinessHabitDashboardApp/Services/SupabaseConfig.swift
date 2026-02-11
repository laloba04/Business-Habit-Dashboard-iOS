//
//  SupabaseConfig.swift
//  BusinessHabitDashboardApp
//
//  Created by Maria Bravo Angulo on 10/2/26.
//

import Foundation

// 🔒 Configuración segura de Supabase
// Las credenciales reales están en SupabaseCredentials.swift (gitignored)
// Para configurar: copia SupabaseCredentials.template.swift → SupabaseCredentials.swift

enum SupabaseConfig {
    static var projectURL: URL {
        return SupabaseCredentials.projectURL
    }

    static var anonKey: String {
        return SupabaseCredentials.anonKey
    }
}
