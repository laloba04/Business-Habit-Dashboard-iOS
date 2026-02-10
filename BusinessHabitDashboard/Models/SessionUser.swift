import Foundation

struct SessionUser: Codable, Hashable {
    let id: UUID
    let email: String
    let accessToken: String
}
