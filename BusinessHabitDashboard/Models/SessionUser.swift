import Foundation

// Usuario autenticado que mantenemos en memoria y persistimos localmente.
// Incluye el `accessToken` JWT para llamadas autenticadas al backend.

struct SessionUser: Codable, Hashable {
    let id: UUID
    let email: String
    let accessToken: String
}
