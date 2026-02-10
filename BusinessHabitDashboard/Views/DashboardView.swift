import Charts
import SwiftUI

struct DashboardView: View {
    let habits: [Habit]
    let expenses: [Expense]

    private var completedHabits: Int {
        habits.filter(\.completed).count
    }

    private var pendingHabits: Int {
        habits.count - completedHabits
    }

    private var expensesByCategory: [(String, Double)] {
        Dictionary(grouping: expenses, by: \.category)
            .map { ($0.key, $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.1 > $1.1 }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    StatCard(title: "Completados", value: "\(completedHabits)", color: .green)
                    StatCard(title: "Pendientes", value: "\(pendingHabits)", color: .orange)
                }

                Text("Gastos por categoría")
                    .font(.headline)

                Chart(expensesByCategory, id: \.0) { item in
                    BarMark(
                        x: .value("Categoría", item.0),
                        y: .value("Monto", item.1)
                    )
                }
                .frame(height: 240)
                .padding(.top, 4)
            }
            .padding()
        }
        .navigationTitle("Dashboard")
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title.bold())
                .foregroundStyle(color)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
