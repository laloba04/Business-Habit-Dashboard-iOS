//
//  ExportView.swift
//  BusinessHabitDashboardApp
//
//  Created by Maria Bravo Angulo on 22/2/26.
//

import SwiftUI

// Opciones de exportación disponibles para el usuario
enum ExportOption: String, CaseIterable, Identifiable {
    case habits    = "Hábitos"
    case expenses  = "Gastos"
    case all       = "Todo"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .habits:   return "checklist"
        case .expenses: return "dollarsign.circle.fill"
        case .all:      return "square.and.arrow.up.on.square.fill"
        }
    }

    var description: String {
        switch self {
        case .habits:
            return "Exporta todos tus hábitos con estado, fechas y configuración de recordatorios."
        case .expenses:
            return "Exporta todos tus gastos con monto, categoría y fecha."
        case .all:
            return "Exporta hábitos y gastos en un único archivo CSV con secciones separadas."
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .habits:   return AppColors.primaryGradient
        case .expenses: return AppColors.secondaryGradient
        case .all:      return AppColors.accentGradient
        }
    }

    var fileName: String {
        switch self {
        case .habits:   return "habitos"
        case .expenses: return "gastos"
        case .all:      return "datos_completos"
        }
    }
}

/// Vista modal para exportar datos de la app a CSV.
/// Se presenta como sheet desde ProfileView.
struct ExportView: View {
    let habits: [Habit]
    let expenses: [Expense]

    @Environment(\.dismiss) private var dismiss

    // Opción seleccionada actualmente
    @State private var selectedOption: ExportOption = .all

    // Estado de generación
    @State private var isGenerating = false
    @State private var generatedFileURL: URL?
    @State private var errorMessage: String?

    // Control del ShareSheet
    @State private var showingShareSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppStyles.spacingLarge) {

                        // Header con icono
                        headerSection

                        // Selector de tipo de exportación
                        exportOptionsSection

                        // Descripción de la opción seleccionada
                        optionDescriptionCard

                        // Resumen de datos disponibles
                        dataSummaryCard

                        // Mensaje de error si existe
                        if let error = errorMessage {
                            errorCard(message: error)
                        }

                        // Botón de exportar / ShareLink
                        exportButton

                        Spacer(minLength: AppStyles.spacingLarge)
                    }
                    .padding(.horizontal, AppStyles.spacingLarge)
                    .padding(.top, AppStyles.spacingLarge)
                }
            }
            .navigationTitle("Exportar datos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Subvistas

    private var headerSection: some View {
        VStack(spacing: AppStyles.spacingMedium) {
            ZStack {
                Circle()
                    .fill(AppColors.accentGradient)
                    .frame(width: 80, height: 80)
                    .shadow(color: AppStyles.shadowColor, radius: 10, x: 0, y: 4)

                Image(systemName: "arrow.down.doc.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
            }

            Text("Selecciona qué datos exportar")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var exportOptionsSection: some View {
        VStack(alignment: .leading, spacing: AppStyles.spacingSmall) {
            Text("Tipo de exportación")
                .font(.headline)
                .foregroundStyle(AppColors.textSecondary)

            // Tarjetas de selección horizontales
            HStack(spacing: AppStyles.spacingSmall) {
                ForEach(ExportOption.allCases) { option in
                    ExportOptionCard(
                        option: option,
                        isSelected: selectedOption == option
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedOption = option
                            // Limpiar estado previo al cambiar opción
                            generatedFileURL = nil
                            errorMessage = nil
                        }
                        let generator = UISelectionFeedbackGenerator()
                        generator.selectionChanged()
                    }
                }
            }
        }
    }

    private var optionDescriptionCard: some View {
        HStack(alignment: .top, spacing: AppStyles.spacingSmall) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(AppColors.info)
                .font(.subheadline)
                .padding(.top, 2)

            Text(selectedOption.description)
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppStyles.spacingMedium)
        .cardStyle(shadow: false)
        .animation(.easeInOut(duration: AppStyles.animationFast), value: selectedOption)
    }

    private var dataSummaryCard: some View {
        VStack(alignment: .leading, spacing: AppStyles.spacingMedium) {
            Text("Datos disponibles")
                .font(.headline)
                .foregroundStyle(AppColors.textSecondary)

            HStack(spacing: AppStyles.spacingMedium) {
                DataCountBadge(
                    count: habits.count,
                    label: "Hábitos",
                    icon: "checklist",
                    gradient: AppColors.primaryGradient
                )

                DataCountBadge(
                    count: expenses.count,
                    label: "Gastos",
                    icon: "dollarsign.circle.fill",
                    gradient: AppColors.secondaryGradient
                )
            }
        }
    }

    private func errorCard(message: String) -> some View {
        HStack(spacing: AppStyles.spacingSmall) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppColors.error)

            Text(message)
                .font(.callout)
                .foregroundStyle(AppColors.error)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppStyles.spacingMedium)
        .cardStyle(shadow: false)
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Botón de exportación

    // El botón genera el archivo de forma síncrona (la escritura en disco es rápida)
    // y usa ShareLink de SwiftUI para invocar el sistema de compartir nativo de iOS.
    // Si la generación falla, se muestra el mensaje de error en lugar del botón de compartir.
    @ViewBuilder
    private var exportButton: some View {
        if let fileURL = generatedFileURL, !isGenerating {
            // El archivo ya está listo: mostrar ShareLink
            ShareLink(
                item: fileURL,
                preview: SharePreview(
                    sharePreviewTitle,
                    icon: Image(systemName: "doc.text.fill")
                )
            ) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Compartir archivo")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedOption.gradient)
                .cornerRadius(AppStyles.cornerRadiusMedium)
                .shadow(color: AppStyles.shadowColor, radius: 10, x: 0, y: 4)
            }
            .transition(.scale.combined(with: .opacity))

            // Botón secundario para generar de nuevo
            Button {
                withAnimation {
                    generatedFileURL = nil
                    errorMessage = nil
                }
            } label: {
                Text("Generar de nuevo")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(.top, AppStyles.spacingXSmall)

        } else {
            // El archivo no está generado aún: mostrar botón de generar
            Button {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                generateFile()
            } label: {
                if isGenerating {
                    HStack {
                        ProgressView()
                            .tint(.white)
                        Text("Generando archivo…")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    HStack {
                        Image(systemName: "doc.badge.plus")
                        Text("Generar CSV")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(AppStyles.PrimaryButtonStyle(
                gradient: selectedOption.gradient,
                isDisabled: isGenerating
            ))
            .disabled(isGenerating)
        }
    }

    // MARK: - Lógica de generación

    private var sharePreviewTitle: String {
        switch selectedOption {
        case .habits:   return "Hábitos.csv"
        case .expenses: return "Gastos.csv"
        case .all:      return "Datos completos.csv"
        }
    }

    /// Genera el archivo CSV de forma síncrona (operación de disco rápida, no necesita async).
    /// Actualiza el estado en el hilo principal al finalizar.
    private func generateFile() {
        isGenerating = true
        errorMessage = nil
        generatedFileURL = nil

        // Usamos Task para no bloquear el hilo principal, aunque la operación
        // de escritura en disco es muy rápida en práctica.
        Task { @MainActor in
            do {
                let url: URL
                switch selectedOption {
                case .habits:
                    url = try ExportService.shared.exportHabits(habits)
                case .expenses:
                    url = try ExportService.shared.exportExpenses(expenses)
                case .all:
                    url = try ExportService.shared.exportAll(habits: habits, expenses: expenses)
                }

                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    generatedFileURL = url
                    isGenerating = false
                }

                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)

            } catch {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    errorMessage = error.localizedDescription
                    isGenerating = false
                }

                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
            }
        }
    }
}

// MARK: - ExportOptionCard

/// Tarjeta compacta que representa una opción de exportación seleccionable.
private struct ExportOptionCard: View {
    let option: ExportOption
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: AppStyles.spacingSmall) {
                ZStack {
                    Circle()
                        .fill(isSelected ? option.gradient : LinearGradient(
                            colors: [AppColors.cardBackground, AppColors.cardBackground],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 44, height: 44)

                    Image(systemName: option.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : AppColors.textSecondary)
                }

                Text(option.rawValue)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isSelected ? AppColors.textPrimary : AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppStyles.spacingMedium)
            .background(AppColors.cardBackground)
            .cornerRadius(AppStyles.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: AppStyles.cornerRadiusMedium)
                    .stroke(
                        isSelected ? Color(hex: "2563EB") : Color.clear,
                        lineWidth: 2
                    )
            )
            .shadow(
                color: isSelected ? AppStyles.shadowColor : .clear,
                radius: 6,
                x: 0,
                y: 3
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - DataCountBadge

/// Insignia que muestra el número de registros disponibles de un tipo de dato.
private struct DataCountBadge: View {
    let count: Int
    let label: String
    let icon: String
    let gradient: LinearGradient

    var body: some View {
        HStack(spacing: AppStyles.spacingSmall) {
            ZStack {
                Circle()
                    .fill(gradient)
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(count)")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppColors.textPrimary)

                Text(label)
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()
        }
        .padding(AppStyles.spacingMedium)
        .cardStyle(shadow: true)
    }
}

#Preview {
    ExportView(
        habits: [
            Habit(
                id: UUID(),
                userID: UUID(),
                title: "Meditar 10 minutos",
                completed: true,
                createdAt: Date(),
                reminderEnabled: true,
                reminderTime: Date(),
                reminderDays: [1, 3, 5]
            )
        ],
        expenses: [
            Expense(
                id: UUID(),
                userID: UUID(),
                category: "Alimentación",
                amount: 45.50,
                createdAt: Date()
            )
        ]
    )
}
