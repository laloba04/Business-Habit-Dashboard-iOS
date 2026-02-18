//
//  HabitReminderView.swift
//  BusinessHabitDashboardApp
//
//  Created by Maria Bravo Angulo on 18/2/26.
//

import SwiftUI

struct HabitReminderView: View {
    let habit: Habit
    @ObservedObject var viewModel: HabitViewModel
    let user: SessionUser
    @Environment(\.dismiss) private var dismiss

    // Estado local del formulario
    @State private var reminderEnabled: Bool
    @State private var reminderTime: Date
    @State private var selectedDays: Set<Int>

    // Estados de UI
    @State private var isSaving = false
    @State private var showSuccess = false
    @State private var showPermissionAlert = false
    @State private var animateContent = false

    init(habit: Habit, viewModel: HabitViewModel, user: SessionUser) {
        self.habit = habit
        self.viewModel = viewModel
        self.user = user

        // Inicializar estados desde el hábito
        _reminderEnabled = State(initialValue: habit.reminderEnabled ?? false)
        _reminderTime = State(initialValue: habit.reminderTime ?? Date())
        _selectedDays = State(initialValue: Set(habit.reminderDays ?? []))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppStyles.spacingLarge) {
                        // Header con icono
                        headerSection
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : -20)

                        // Toggle principal
                        toggleSection
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 20)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: animateContent)

                        // Configuración de hora y días (solo si está habilitado)
                        if reminderEnabled {
                            configurationSection
                                .opacity(animateContent ? 1 : 0)
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .opacity
                                ))
                                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: reminderEnabled)
                        }

                        // Botón guardar
                        saveButton
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 20)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: animateContent)
                    }
                    .padding(AppStyles.spacingLarge)
                }
            }
            .navigationTitle("Configurar recordatorio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
            .alert("Permisos necesarios", isPresented: $showPermissionAlert) {
                Button("Cancelar", role: .cancel) { }
                Button("Ir a Ajustes") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text("Para recibir recordatorios, necesitas habilitar las notificaciones en Ajustes.")
            }
            .overlay {
                if showSuccess {
                    successOverlay
                }
            }
            .onAppear {
                withAnimation {
                    animateContent = true
                }
            }
        }
    }

    // MARK: - Secciones de la vista

    private var headerSection: some View {
        VStack(spacing: AppStyles.spacingMedium) {
            ZStack {
                Circle()
                    .fill(AppColors.accentGradient)
                    .frame(width: 80, height: 80)

                Image(systemName: "bell.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
            }

            VStack(spacing: AppStyles.spacingXSmall) {
                Text(habit.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Configura cuándo quieres recibir recordatorios")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, AppStyles.spacingMedium)
    }

    private var toggleSection: some View {
        VStack(alignment: .leading, spacing: AppStyles.spacingMedium) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Activar recordatorio")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppColors.textPrimary)

                    Text(reminderEnabled ? "Recibirás notificaciones" : "No recibirás notificaciones")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                Toggle("", isOn: $reminderEnabled)
                    .labelsHidden()
                    .tint(Color(hex: "4A90E2"))
                    .onChange(of: reminderEnabled) { _, newValue in
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()

                        // Si se activa y no hay días seleccionados, seleccionar todos por defecto
                        if newValue && selectedDays.isEmpty {
                            selectedDays = Set(1...5) // Lunes a Viernes por defecto
                        }
                    }
            }
        }
        .padding()
        .cardStyle(shadow: true)
    }

    private var configurationSection: some View {
        VStack(spacing: AppStyles.spacingLarge) {
            // Selector de hora
            VStack(alignment: .leading, spacing: AppStyles.spacingMedium) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(AppColors.accentGradient)
                    Text("Hora del recordatorio")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppColors.textPrimary)
                }

                DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .onChange(of: reminderTime) { _, _ in
                        let generator = UISelectionFeedbackGenerator()
                        generator.selectionChanged()
                    }
            }
            .padding()
            .cardStyle(shadow: true)

            // Selector de días
            VStack(alignment: .leading, spacing: AppStyles.spacingMedium) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(AppColors.accentGradient)
                    Text("Días de la semana")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppColors.textPrimary)
                }

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: AppStyles.spacingSmall) {
                    ForEach(weekdays, id: \.value) { weekday in
                        DayButton(
                            day: weekday.label,
                            value: weekday.value,
                            isSelected: selectedDays.contains(weekday.value)
                        ) {
                            toggleDay(weekday.value)
                        }
                    }
                }
            }
            .padding()
            .cardStyle(shadow: true)
        }
    }

    private var saveButton: some View {
        Button {
            saveReminder()
        } label: {
            HStack {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Guardar recordatorio")
                    Image(systemName: "checkmark.circle.fill")
                }
            }
        }
        .buttonStyle(AppStyles.PrimaryButtonStyle(
            gradient: AppColors.accentGradient,
            isDisabled: isButtonDisabled
        ))
        .disabled(isButtonDisabled)
    }

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: AppStyles.spacingLarge) {
                ZStack {
                    Circle()
                        .fill(AppColors.successGradient)
                        .frame(width: 80, height: 80)

                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(.white)
                }

                Text("Recordatorio configurado")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
            }
            .padding(AppStyles.spacingXLarge)
            .background(
                RoundedRectangle(cornerRadius: AppStyles.cornerRadiusLarge)
                    .fill(.ultraThinMaterial)
            )
            .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Datos

    private let weekdays = [
        (label: "L", value: 1),  // Lunes
        (label: "M", value: 2),  // Martes
        (label: "X", value: 3),  // Miércoles
        (label: "J", value: 4),  // Jueves
        (label: "V", value: 5),  // Viernes
        (label: "S", value: 6),  // Sábado
        (label: "D", value: 0)   // Domingo
    ]

    // MARK: - Computed Properties

    private var isButtonDisabled: Bool {
        if !reminderEnabled {
            return false // Permitir guardar para desactivar
        }
        return selectedDays.isEmpty || isSaving
    }

    // MARK: - Acciones

    private func toggleDay(_ day: Int) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }

    private func saveReminder() {
        Task {
            // Verificar permisos de notificación
            let status = await NotificationManager.shared.checkAuthorizationStatus()

            if reminderEnabled && status != .authorized {
                // Solicitar permisos
                let granted = await NotificationManager.shared.requestAuthorization()

                if !granted {
                    await MainActor.run {
                        showPermissionAlert = true
                    }
                    return
                }
            }

            // Guardar
            await MainActor.run {
                isSaving = true
            }

            let days = reminderEnabled ? Array(selectedDays).sorted() : nil
            let time = reminderEnabled ? reminderTime : nil

            await viewModel.updateReminder(
                for: habit,
                enabled: reminderEnabled,
                time: time,
                days: days,
                user: user
            )

            await MainActor.run {
                isSaving = false

                // Mostrar confirmación
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)

                withAnimation {
                    showSuccess = true
                }

                // Cerrar después de 1.5 segundos
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        showSuccess = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - DayButton

struct DayButton: View {
    let day: String
    let value: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(day)
                .font(.body.weight(.semibold))
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: AppStyles.cornerRadiusMedium)
                        .fill(isSelected ? AnyShapeStyle(AppColors.accentGradient) : AnyShapeStyle(AppColors.cardBackground))
                )
                .foregroundStyle(isSelected ? .white : AppColors.textSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: AppStyles.cornerRadiusMedium)
                        .stroke(isSelected ? Color.clear : AppColors.textSecondary.opacity(0.2), lineWidth: 1)
                )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}

#Preview {
    HabitReminderView(
        habit: Habit(
            id: UUID(),
            userID: UUID(),
            title: "Leer 20 minutos",
            completed: false,
            createdAt: Date()
        ),
        viewModel: HabitViewModel(),
        user: SessionUser(
            id: UUID(),
            email: "usuario@ejemplo.com",
            accessToken: "token"
        )
    )
}
