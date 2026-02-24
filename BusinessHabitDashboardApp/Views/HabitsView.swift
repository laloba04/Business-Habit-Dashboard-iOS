//
//  HabitsView.swift
//  BusinessHabitDashboardApp
//
//  Created by Maria Bravo Angulo on 10/2/26.
//

import SwiftUI

struct HabitsView: View {
    @ObservedObject var viewModel: HabitViewModel
    let user: SessionUser

    @State private var newHabitTitle = ""
    @State private var showingAddSheet = false

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                if viewModel.habits.isEmpty {
                    emptyStateView
                } else {
                    habitsList
                }
            }
        }
        .navigationTitle("Hábitos")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppColors.primaryGradient)
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddHabitSheet(viewModel: viewModel, user: user)
        }
        .task {
            await viewModel.loadHabits(user: user)
        }
    }

    private var habitsList: some View {
        List {
            ForEach(viewModel.habits) { habit in
                HabitCard(habit: habit, viewModel: viewModel, user: user)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(
                        top: AppStyles.spacingSmall,
                        leading: AppStyles.spacingMedium,
                        bottom: AppStyles.spacingSmall,
                        trailing: AppStyles.spacingMedium
                    ))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var emptyStateView: some View {
        VStack(spacing: AppStyles.spacingLarge) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppColors.secondaryGradient)
                    .frame(width: 120, height: 120)
                    .opacity(0.2)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(AppColors.secondaryGradient)
            }

            VStack(spacing: AppStyles.spacingSmall) {
                Text("Sin hábitos aún")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppColors.textPrimary)

                Text("Crea tu primer hábito y comienza a construir una mejor versión de ti")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppStyles.spacingXLarge)
            }

            Button {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                showingAddSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Crear hábito")
                }
            }
            .buttonStyle(AppStyles.PrimaryButtonStyle(gradient: AppColors.secondaryGradient))
            .padding(.horizontal, AppStyles.spacingXLarge)

            Spacer()
        }
    }
}

// MARK: - HabitCard

struct HabitCard: View {
    let habit: Habit
    @ObservedObject var viewModel: HabitViewModel
    let user: SessionUser

    @State private var showReminderSheet = false

    var body: some View {
        HStack(spacing: AppStyles.spacingMedium) {
            // Círculo de estado (clickeable para toggle)
            Button {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                Task {
                    await viewModel.toggleCompletion(habit, user: user)
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(habit.completed ? AnyShapeStyle(AppColors.successGradient) : AnyShapeStyle(AppColors.cardBackground))
                        .frame(width: 50, height: 50)

                    Image(systemName: habit.completed ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(habit.completed ? .white : AppColors.textSecondary)
                }
                .scaleEffect(habit.completed ? 1.05 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: habit.completed)
            }

            // Texto
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .strikethrough(habit.completed)

                Text(habit.completed ? "Completado" : "Pendiente")
                    .font(.caption)
                    .foregroundStyle(habit.completed ? AppColors.success : AppColors.textSecondary)
            }

            Spacer()

            // Botón de recordatorio
            Button {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                showReminderSheet = true
            } label: {
                Image(systemName: habit.hasValidReminder ? "bell.fill" : "bell")
                    .font(.title3)
                    .foregroundStyle(habit.hasValidReminder ? Color(hex: "0891B2") : AppColors.textSecondary)
                    .frame(width: 40, height: 40)
            }
        }
        .padding()
        .cardStyle(shadow: true)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)
                Task {
                    await viewModel.deleteHabit(habit, user: user)
                }
            } label: {
                Label("Eliminar", systemImage: "trash.fill")
            }
        }
        .sheet(isPresented: $showReminderSheet) {
            HabitReminderView(habit: habit, viewModel: viewModel, user: user)
        }
    }
}

// MARK: - AddHabitSheet

struct AddHabitSheet: View {
    @ObservedObject var viewModel: HabitViewModel
    let user: SessionUser
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                VStack(spacing: AppStyles.spacingLarge) {
                    // Icono
                    ZStack {
                        Circle()
                            .fill(AppColors.secondaryGradient)
                            .frame(width: 80, height: 80)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.white)
                    }
                    .padding(.top, AppStyles.spacingLarge)

                    Text("Crea un nuevo hábito")
                        .font(.headline)
                        .foregroundStyle(AppColors.textSecondary)

                    // Formulario
                    VStack(spacing: AppStyles.spacingLarge) {
                        VStack(alignment: .leading, spacing: AppStyles.spacingSmall) {
                            Text("Título del hábito")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(AppColors.textSecondary)

                            TextField("Ej: Leer 20 minutos", text: $title)
                                .inputFieldStyle(icon: "text.alignleft")
                        }

                        Button {
                            addHabit()
                        } label: {
                            HStack {
                                Text("Crear hábito")
                                Image(systemName: "checkmark.circle.fill")
                            }
                        }
                        .buttonStyle(AppStyles.PrimaryButtonStyle(
                            gradient: AppColors.secondaryGradient,
                            isDisabled: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ))
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(AppStyles.spacingLarge)
                    .cardStyle(shadow: true)
                    .padding(.horizontal, AppStyles.spacingLarge)

                    Spacer()
                }
            }
            .navigationTitle("Nuevo hábito")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func addHabit() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        Task {
            await viewModel.addHabit(title: trimmedTitle, user: user)
            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        HabitsView(
            viewModel: HabitViewModel(),
            user: SessionUser(
                id: UUID(),
                email: "usuario@ejemplo.com",
                accessToken: "token"
            )
        )
    }
}
