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

    @State private var category = ""
    @State private var amount = ""

    var body: some View {
        List {
            Section("Nuevo gasto") {
                TextField("Categoría", text: $category)
                TextField("Monto", text: $amount)
                    .keyboardType(.decimalPad)

                Button("Agregar") {
                    guard let amountValue = Double(amount), !category.isEmpty else { return }
                    Task {
                        await viewModel.addExpense(category: category, amount: amountValue, user: user)
                        category = ""
                        amount = ""
                    }
                }
            }

            Section("Recientes") {
                ForEach(viewModel.expenses) { expense in
                    HStack {
                        Text(expense.category)
                        Spacer()
                        Text(expense.amount, format: .currency(code: "EUR"))
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.deleteExpense(expense, user: user)
                            }
                        } label: {
                            Label("Eliminar", systemImage: "trash.fill")
                        }
                    }
                }
            }
        }
        .navigationTitle("Gastos")
        .task {
            await viewModel.loadExpenses(user: user)
        }
    }
}
