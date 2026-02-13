import SwiftUI

/// Vista de onboarding que se muestra la primera vez
struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0

    private let pages = OnboardingPage.pages

    var body: some View {
        ZStack {
            // Fondo con gradiente animado
            pages[currentPage].gradient
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: currentPage)

            VStack(spacing: 0) {
                // Páginas con TabView
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Indicadores de página personalizados
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.white : Color.white.opacity(0.5))
                            .frame(width: index == currentPage ? 10 : 8, height: index == currentPage ? 10 : 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.top, AppStyles.spacingLarge)

                // Botones de navegación
                HStack(spacing: AppStyles.spacingMedium) {
                    if currentPage > 0 {
                        Button(action: previousPage) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Anterior")
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, AppStyles.spacingLarge)
                            .padding(.vertical, AppStyles.spacingMedium)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(AppStyles.cornerRadiusMedium)
                        }
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    }

                    Spacer()

                    if currentPage < pages.count - 1 {
                        Button(action: nextPage) {
                            HStack {
                                Text("Siguiente")
                                Image(systemName: "chevron.right")
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, AppStyles.spacingLarge)
                            .padding(.vertical, AppStyles.spacingMedium)
                            .background(Color.white.opacity(0.3))
                            .cornerRadius(AppStyles.cornerRadiusMedium)
                        }
                    } else {
                        Button(action: completeOnboarding) {
                            HStack {
                                Text("Comenzar")
                                Image(systemName: "arrow.right.circle.fill")
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, AppStyles.spacingLarge)
                            .padding(.vertical, AppStyles.spacingMedium)
                            .background(Color.white)
                            .foregroundStyle(AppColors.textPrimary)
                            .cornerRadius(AppStyles.cornerRadiusMedium)
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, AppStyles.spacingLarge)
                .padding(.vertical, AppStyles.spacingLarge)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
            }
        }
    }

    private func nextPage() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            if currentPage < pages.count - 1 {
                currentPage += 1
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
        }
    }

    private func previousPage() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            if currentPage > 0 {
                currentPage -= 1
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
        }
    }

    private func completeOnboarding() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            hasCompletedOnboarding = true
        }
    }
}

/// Vista individual de página de onboarding
struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: AppStyles.spacingXLarge) {
            Spacer()

            // Icono grande con animación
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 160, height: 160)

                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 200, height: 200)

                Image(systemName: page.iconName)
                    .font(.system(size: 80))
                    .foregroundStyle(.white)
            }
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)

            // Texto
            VStack(spacing: AppStyles.spacingMedium) {
                Text(page.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppStyles.spacingLarge)
            }

            Spacer()
        }
        .padding(AppStyles.spacingLarge)
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
