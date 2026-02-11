//
//  SessionUser.swift
//  BusinessHabitDashboardApp
//
//  Created by Maria Bravo Angulo on 10/2/26.
//

import Foundation

// Usuario autenticado que mantenemos en memoria y persistimos localmente.
// Incluye el `accessToken` JWT para llamadas autenticadas al backend.

struct SessionUser: Codable, Hashable {
    let id: UUID
    let email: String
    let accessToken: String
}
