//
//  ExpensesView.swift
//  BusinessHabitDashboardApp
//
//  Created by Maria Bravo Angulo on 10/2/26.
//

import SwiftUI

struct ExpensesView: View {
    @ObservedObject var viewModel: ExpenseViewModel
    let user: SessionUser

    @State private var showingAddSheet = false

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                if viewModel.expenses.isEmpty {
                    emptyStateView
                } else {
                    expensesList
                }
            }
        }
        .navigationTitle("Gastos")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppColors.accentGradient)
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddExpenseSheet(viewModel: viewModel, user: user)
        }
        .task {
            await viewModel.loadExpenses(user: user)
        }
    }

    private var expensesList: some View {
        ScrollView {
            LazyVStack(spacing: AppStyles.spacingMedium) {
                // Resumen total
                totalCard

                // Lista de gastos
                ForEach(Array(viewModel.expenses.enumerated()), id: \.element.id) { index, expense in
                    ExpenseCard(expense: expense, viewModel: viewModel, user: user)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        ))
                        .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(index) * 0.05), value: viewModel.expenses)
                }
            }
            .padding(AppStyles.spacingMedium)
        }
    }

    private var totalCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppStyles.spacingSmall) {
                Text("Total gastado")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)

                Text(totalAmount, format: .currency(code: "EUR"))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 60, height: 60)

                Image(systemName: "eurosign.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.white)
            }
        }
        .padding(AppStyles.spacingLarge)
        .background(AppColors.accentGradient)
        .cornerRadius(AppStyles.cornerRadiusLarge)
        .shadow(color: AppStyles.shadowColor, radius: 10, x: 0, y: 4)
    }

    private var totalAmount: Double {
        viewModel.expenses.reduce(0) { $0 + $1.amount }
    }

    private var emptyStateView: some View {
        VStack(spacing: AppStyles.spacingLarge) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppColors.accentGradient)
                    .frame(width: 120, height: 120)
                    .opacity(0.2)

                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(AppColors.accentGradient)
            }

            VStack(spacing: AppStyles.spacingSmall) {
                Text("Sin gastos registrados")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppColors.textPrimary)

                Text("Comienza a registrar tus gastos para mantener control de tus finanzas")
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
                    Text("Registrar gasto")
                }
            }
            .buttonStyle(AppStyles.PrimaryButtonStyle(gradient: AppColors.accentGradient))
            .padding(.horizontal, AppStyles.spacingXLarge)

            Spacer()
        }
    }
}

// MARK: - ExpenseCard

struct ExpenseCard: View {
    let expense: Expense
    @ObservedObject var viewModel: ExpenseViewModel
    let user: SessionUser

    var body: some View {
        HStack(spacing: AppStyles.spacingMedium) {
            // Icono de categoría
            ZStack {
                Circle()
                    .fill(categoryGradient)
                    .frame(width: 50, height: 50)

                Image(systemName: categoryIcon)
                    .font(.title3)
                    .foregroundStyle(.white)
            }

            // Información del gasto
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.category.capitalized)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)

                Text(formattedDate(expense.createdAt))
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            // Monto
            Text(expense.amount, format: .currency(code: "EUR"))
                .font(.title3.weight(.bold))
                .foregroundStyle(AppColors.textPrimary)
        }
        .padding()
        .cardStyle(shadow: true)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)
                Task {
                    await viewModel.deleteExpense(expense, user: user)
                }
            } label: {
                Label("Eliminar", systemImage: "trash.fill")
            }
        }
    }

    private var categoryIcon: String {
        switch expense.category.lowercased() {
        case "comida", "alimentación", "food":
            return "fork.knife"
        case "transporte", "transport":
            return "car.fill"
        case "compras", "shopping":
            return "cart.fill"
        case "entretenimiento", "entertainment":
            return "film.fill"
        case "salud", "health":
            return "heart.fill"
        case "educación", "education":
            return "book.fill"
        default:
            return "tag.fill"
        }
    }

    private var categoryGradient: LinearGradient {
        let colorIndex = abs(expense.category.hashValue) % AppColors.chartColors.count
        let color = AppColors.chartColors[colorIndex]
        return LinearGradient(
            colors: [color, color.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: date)
    }
}

// MARK: - AddExpenseSheet

struct AddExpenseSheet: View {
    @ObservedObject var viewModel: ExpenseViewModel
    let user: SessionUser
    @Environment(\.dismiss) private var dismiss

    @State private var category = ""
    @State private var amount = ""

    private let suggestedCategories = [
        "Comida", "Transporte", "Compras", "Entretenimiento",
        "Salud", "Educación", "Servicios", "Otros"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppStyles.spacingLarge) {
                        headerIcon

                        Text("Registra un nuevo gasto")
                            .font(.headline)
                            .foregroundStyle(AppColors.textSecondary)

                        formContent
                    }
                }
            }
            .navigationTitle("Nuevo gasto")
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

    private var headerIcon: some View {
        ZStack {
            Circle()
                .fill(AppColors.accentGradient)
                .frame(width: 80, height: 80)

            Image(systemName: "eurosign.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.white)
        }
        .padding(.top, AppStyles.spacingLarge)
    }

    private var formContent: some View {
        VStack(spacing: AppStyles.spacingLarge) {
            categorySection
            amountSection
            submitButton
        }
        .padding(AppStyles.spacingLarge)
        .cardStyle(shadow: true)
        .padding(.horizontal, AppStyles.spacingLarge)
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: AppStyles.spacingSmall) {
            Text("Categoría")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppColors.textSecondary)

            TextField("Ej: Comida", text: $category)
                .inputFieldStyle(icon: "tag.fill")

            categorySuggestions
        }
    }

    private var categorySuggestions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppStyles.spacingSmall) {
                ForEach(suggestedCategories, id: \.self) { suggested in
                    categoryButton(suggested)
                }
            }
        }
    }

    private func categoryButton(_ suggested: String) -> some View {
        Button(suggested) {
            category = suggested
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(category == suggested ? AnyShapeStyle(AppColors.accentGradient) : AnyShapeStyle(AppColors.cardBackground))
        .foregroundStyle(category == suggested ? .white : AppColors.textSecondary)
        .cornerRadius(AppStyles.cornerRadiusSmall)
    }

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: AppStyles.spacingSmall) {
            Text("Monto")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppColors.textSecondary)

            TextField("0.00", text: $amount)
                .keyboardType(.decimalPad)
                .inputFieldStyle(icon: "eurosign")
        }
    }

    private var submitButton: some View {
        Button {
            addExpense()
        } label: {
            HStack {
                Text("Registrar gasto")
                Image(systemName: "checkmark.circle.fill")
            }
        }
        .buttonStyle(AppStyles.PrimaryButtonStyle(
            gradient: AppColors.accentGradient,
            isDisabled: isButtonDisabled
        ))
        .disabled(isButtonDisabled)
    }

    private var isButtonDisabled: Bool {
        category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        Double(amount) == nil ||
        Double(amount) ?? 0 <= 0
    }

    private func addExpense() {
        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let amountValue = Double(amount), amountValue > 0, !trimmedCategory.isEmpty else {
            return
        }

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        Task {
            await viewModel.addExpense(category: trimmedCategory, amount: amountValue, user: user)
            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        ExpensesView(
            viewModel: ExpenseViewModel(),
            user: SessionUser(
                id: UUID(),
                email: "usuario@ejemplo.com",
                accessToken: "token"
            )
        )
    }
}
