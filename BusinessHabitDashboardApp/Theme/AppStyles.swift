import SwiftUI

/// Estilos consistentes para la aplicación
struct AppStyles {

    // MARK: - Corner Radius

    static let cornerRadiusSmall: CGFloat = 8
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 16
    static let cornerRadiusXLarge: CGFloat = 24

    // MARK: - Spacing

    static let spacingXSmall: CGFloat = 4
    static let spacingSmall: CGFloat = 8
    static let spacingMedium: CGFloat = 16
    static let spacingLarge: CGFloat = 24
    static let spacingXLarge: CGFloat = 32

    // MARK: - Shadow

    static let shadowRadius: CGFloat = 10
    static let shadowColor = Color.black.opacity(0.1)

    // MARK: - Animation Duration

    static let animationFast: Double = 0.2
    static let animationMedium: Double = 0.3
    static let animationSlow: Double = 0.5

    // MARK: - Card Style

    struct CardStyle: ViewModifier {
        let gradient: LinearGradient?
        let shadow: Bool

        init(gradient: LinearGradient? = nil, shadow: Bool = true) {
            self.gradient = gradient
            self.shadow = shadow
        }

        func body(content: Content) -> some View {
            content
                .background(
                    Group {
                        if let gradient = gradient {
                            gradient
                        } else {
                            AppColors.cardBackground
                        }
                    }
                )
                .cornerRadius(cornerRadiusMedium)
                .shadow(
                    color: shadow ? shadowColor : .clear,
                    radius: shadow ? shadowRadius : 0,
                    x: 0,
                    y: shadow ? 4 : 0
                )
        }
    }

    // MARK: - Button Styles

    struct PrimaryButtonStyle: ButtonStyle {
        let gradient: LinearGradient
        let isDisabled: Bool

        init(gradient: LinearGradient = AppColors.primaryGradient, isDisabled: Bool = false) {
            self.gradient = gradient
            self.isDisabled = isDisabled
        }

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    Group {
                        if isDisabled {
                            Color.gray
                        } else {
                            gradient
                        }
                    }
                )
                .cornerRadius(cornerRadiusMedium)
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
                .shadow(
                    color: isDisabled ? .clear : shadowColor,
                    radius: configuration.isPressed ? 5 : 10,
                    x: 0,
                    y: configuration.isPressed ? 2 : 4
                )
        }
    }

    struct SecondaryButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.headline)
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.cardBackground)
                .cornerRadius(cornerRadiusMedium)
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
        }
    }

    // MARK: - Input Field Style

    struct InputFieldStyle: ViewModifier {
        let icon: String?

        init(icon: String? = nil) {
            self.icon = icon
        }

        func body(content: Content) -> some View {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(width: 20)
                }
                content
            }
            .padding()
            .background(AppColors.cardBackground)
            .cornerRadius(cornerRadiusMedium)
        }
    }

    // MARK: - Loading Style

    struct LoadingView: View {
        let text: String

        var body: some View {
            VStack(spacing: spacingMedium) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }
            .padding(spacingLarge)
            .background(
                RoundedRectangle(cornerRadius: cornerRadiusMedium)
                    .fill(.ultraThinMaterial)
            )
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Aplica el estilo de tarjeta
    func cardStyle(gradient: LinearGradient? = nil, shadow: Bool = true) -> some View {
        self.modifier(AppStyles.CardStyle(gradient: gradient, shadow: shadow))
    }

    /// Aplica el estilo de campo de entrada
    func inputFieldStyle(icon: String? = nil) -> some View {
        self.modifier(AppStyles.InputFieldStyle(icon: icon))
    }

    /// Añade haptic feedback
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred()
        }
    }

    /// Animación de aparición
    func appearAnimation(delay: Double = 0) -> some View {
        self
            .opacity(1)
            .transition(.asymmetric(
                insertion: .scale.combined(with: .opacity),
                removal: .opacity
            ))
            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay), value: UUID())
    }
}
