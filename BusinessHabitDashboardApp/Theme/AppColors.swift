import SwiftUI

/// Sistema de colores centralizado de la app con soporte para modo claro y oscuro
struct AppColors {

    // MARK: - Primary Colors

    /// Color primario principal - Azul vibrante
    static let primary = Color("Primary", bundle: nil)

    /// Color secundario - Púrpura
    static let secondary = Color("Secondary", bundle: nil)

    /// Color de acento - Verde menta
    static let accent = Color("Accent", bundle: nil)

    // MARK: - Gradient Colors (Profesionales)

    /// Gradiente principal (azul corporativo)
    static let primaryGradient = LinearGradient(
        colors: [Color(hex: "2563EB"), Color(hex: "1E40AF")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Gradiente secundario (verde profesional)
    static let secondaryGradient = LinearGradient(
        colors: [Color(hex: "059669"), Color(hex: "047857")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Gradiente de acento (azul a teal)
    static let accentGradient = LinearGradient(
        colors: [Color(hex: "0891B2"), Color(hex: "0E7490")],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Gradiente de éxito (verde)
    static let successGradient = LinearGradient(
        colors: [Color(hex: "10B981"), Color(hex: "059669")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Gradiente de fondo para login/signup (azul sutil)
    static let authBackgroundGradient = LinearGradient(
        colors: [Color(hex: "1E40AF"), Color(hex: "3B82F6")],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Gradiente de dashboard (azul a índigo)
    static let dashboardGradient = LinearGradient(
        colors: [Color(hex: "4F46E5"), Color(hex: "6366F1")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Status Colors

    /// Color de éxito
    static let success = Color(hex: "10B981")

    /// Color de advertencia
    static let warning = Color(hex: "F59E0B")

    /// Color de error
    static let error = Color(hex: "EF4444")

    /// Color de información
    static let info = Color(hex: "3B82F6")

    // MARK: - Background Colors

    /// Fondo principal
    static let background = Color(.systemBackground)

    /// Fondo secundario
    static let secondaryBackground = Color(.secondarySystemBackground)

    /// Fondo de tarjetas
    static let cardBackground = Color(.systemGray6)

    // MARK: - Text Colors

    /// Texto primario
    static let textPrimary = Color(.label)

    /// Texto secundario
    static let textSecondary = Color(.secondaryLabel)

    /// Texto terciario
    static let textTertiary = Color(.tertiaryLabel)

    // MARK: - Chart Colors (Profesionales)

    /// Colores para gráficos
    static let chartColors: [Color] = [
        Color(hex: "2563EB"), // Azul corporativo
        Color(hex: "10B981"), // Verde profesional
        Color(hex: "0891B2"), // Teal
        Color(hex: "6366F1"), // Índigo
        Color(hex: "8B5CF6"), // Violeta
        Color(hex: "059669"), // Verde oscuro
        Color(hex: "0E7490")  // Cian oscuro
    ]

    // MARK: - Category Colors (Profesionales)

    static let categoryColors: [String: Color] = [
        "trabajo": Color(hex: "2563EB"),      // Azul corporativo
        "salud": Color(hex: "10B981"),        // Verde salud
        "finanzas": Color(hex: "059669"),     // Verde dinero
        "personal": Color(hex: "6366F1"),     // Índigo
        "ejercicio": Color(hex: "0891B2"),    // Teal activo
        "alimentación": Color(hex: "F59E0B"), // Naranja suave
        "educación": Color(hex: "8B5CF6"),    // Violeta
        "default": Color(hex: "2563EB")       // Azul por defecto
    ]
}

// MARK: - Color Extension para Hex

extension Color {
    /// Inicializa un Color desde un string hexadecimal
    /// - Parameter hex: String en formato "RRGGBB" o "#RRGGBB"
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
