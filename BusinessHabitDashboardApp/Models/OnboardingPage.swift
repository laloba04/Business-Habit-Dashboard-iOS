import SwiftUI

/// Modelo para páginas de onboarding
struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let iconName: String
    let gradient: LinearGradient
}

extension OnboardingPage {
    static let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Bienvenido a tu Dashboard",
            description: "Gestiona tus hábitos y gastos en un solo lugar. Visualiza tu progreso y toma mejores decisiones.",
            iconName: "chart.line.uptrend.xyaxis",
            gradient: AppColors.primaryGradient
        ),
        OnboardingPage(
            title: "Construye Hábitos",
            description: "Crea y sigue tus hábitos diarios. Marca como completados y observa tu racha de éxito crecer.",
            iconName: "checkmark.circle.fill",
            gradient: AppColors.secondaryGradient
        ),
        OnboardingPage(
            title: "Controla tus Gastos",
            description: "Registra tus gastos diarios y mensuales. Mantén el control de tus finanzas de forma simple.",
            iconName: "dollarsign.circle.fill",
            gradient: AppColors.accentGradient
        ),
        OnboardingPage(
            title: "Analiza tu Progreso",
            description: "Visualiza estadísticas detalladas con gráficos hermosos. Mejora continuamente.",
            iconName: "chart.bar.fill",
            gradient: AppColors.dashboardGradient
        )
    ]
}
