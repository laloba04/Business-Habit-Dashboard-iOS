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

    var body: some View {
        List {
            Section("Nuevo hábito") {
                HStack {
                    TextField("Ej: Leer 20 min", text: $newHabitTitle)
                    Button("Agregar") {
                        let title = newHabitTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !title.isEmpty else { return }
                        Task {
                            await viewModel.addHabit(title: title, user: user)
                            newHabitTitle = ""
                        }
                    }
                }
            }

            Section("Tus hábitos") {
                ForEach(viewModel.habits) { habit in
                    Button {
                        Task { await viewModel.toggleCompletion(habit, user: user) }
                    } label: {
                        HStack {
                            Image(systemName: habit.completed ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(habit.completed ? .green : .secondary)
                            Text(habit.title)
                        }
                    }
                }
            }
        }
        .navigationTitle("Hábitos")
        .task {
            await viewModel.loadHabits(user: user)
        }
    }
}
