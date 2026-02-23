//
//  HabitWidget.swift
//  HabitWidget
//
//  Created by Maria Bravo Angulo on 23/2/26.
//

import WidgetKit
import SwiftUI

// MARK: - Shared Data Model

/// Modelo ligero que se comparte entre la app principal y el widget
/// a través de UserDefaults con App Group.
struct WidgetHabit: Codable, Identifiable {
    let id: String
    let title: String
    let isCompleted: Bool
}

// MARK: - App Group Key

private enum WidgetSharedData {
    static let suiteName = "group.com.BusinessHabitDashboardApp.shared"
    static let habitsKey  = "widgetHabits"
}

// MARK: - Timeline Entry

struct HabitEntry: TimelineEntry {
    let date: Date
    let habits: [WidgetHabit]

    var completed: Int { habits.filter(\.isCompleted).count }
    var total: Int     { habits.count }

    /// Progreso entre 0.0 y 1.0
    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    /// Los primeros 3 hábitos para mostrar en medium
    var previewHabits: [WidgetHabit] { Array(habits.prefix(3)) }
}

// MARK: - Placeholder data

private extension HabitEntry {
    static var placeholder: HabitEntry {
        HabitEntry(
            date: Date(),
            habits: [
                WidgetHabit(id: "1", title: "Meditar 10 min", isCompleted: true),
                WidgetHabit(id: "2", title: "Ejercicio",      isCompleted: true),
                WidgetHabit(id: "3", title: "Leer 30 min",    isCompleted: false),
                WidgetHabit(id: "4", title: "Diario",         isCompleted: false),
                WidgetHabit(id: "5", title: "Agua 2L",        isCompleted: false)
            ]
        )
    }
}

// MARK: - Timeline Provider

struct HabitProvider: TimelineProvider {

    // Carga los hábitos guardados por la app principal en el App Group
    private func loadHabits() -> [WidgetHabit] {
        guard
            let defaults = UserDefaults(suiteName: WidgetSharedData.suiteName),
            let data = defaults.data(forKey: WidgetSharedData.habitsKey),
            let habits = try? JSONDecoder().decode([WidgetHabit].self, from: data)
        else { return [] }
        return habits
    }

    func placeholder(in context: Context) -> HabitEntry {
        HabitEntry.placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitEntry) -> Void) {
        let habits = loadHabits()
        let entry  = habits.isEmpty
            ? HabitEntry.placeholder
            : HabitEntry(date: Date(), habits: habits)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitEntry>) -> Void) {
        let habits = loadHabits()
        let entry  = HabitEntry(date: Date(), habits: habits)

        // Siguiente actualización: en 1 hora
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline   = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Colors (inline, sin importar el módulo principal)

private extension Color {
    /// Azul corporativo de la app
    static let habitBlue    = Color(red: 0.145, green: 0.388, blue: 0.922)  // #2563EB
    /// Verde éxito de la app
    static let habitGreen   = Color(red: 0.063, green: 0.725, blue: 0.506)  // #10B981
    /// Índigo
    static let habitIndigo  = Color(red: 0.388, green: 0.400, blue: 0.945)  // #6366F1
    /// Azul oscuro
    static let habitNavy    = Color(red: 0.118, green: 0.251, blue: 0.686)  // #1E40AF
}

// MARK: - Circular Progress Shape

/// Arco de progreso circular dibujado con Shape
struct CircularProgressShape: Shape {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let start  = Angle(degrees: -90)
        let end    = Angle(degrees: -90 + 360 * progress)

        var path = Path()
        path.addArc(center: center, radius: radius,
                    startAngle: start, endAngle: end, clockwise: false)
        return path
    }
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let entry: HabitEntry

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 6)
                    .frame(width: 68, height: 68)

                CircularProgressShape(progress: entry.progress)
                    .stroke(
                        entry.progress >= 1.0 ? Color.habitGreen : Color.white,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 68, height: 68)

                Text("\(entry.completed)/\(entry.total)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            Text("Habitos hoy")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.75))

            if entry.total > 0 {
                Text("\(Int(entry.progress * 100))%")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.55))
            }
        }
        .padding(12)
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let entry: HabitEntry

    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 6)
                        .frame(width: 64, height: 64)

                    CircularProgressShape(progress: entry.progress)
                        .stroke(
                            entry.progress >= 1.0 ? Color.habitGreen : Color.white,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 64, height: 64)

                    VStack(spacing: 0) {
                        Text("\(entry.completed)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("/ \(entry.total)")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.65))
                    }
                }

                Text("Habitos hoy")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(width: 80)

            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 1)
                .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 6) {
                if entry.habits.isEmpty {
                    Text("Abre la app para\nver tus habitos")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.65))
                } else {
                    ForEach(entry.previewHabits) { habit in
                        HabitRowView(habit: habit)
                    }
                    let remaining = entry.total - entry.previewHabits.count
                    if remaining > 0 {
                        Text("+ \(remaining) mas...")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.45))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - Habit Row (used in medium)

struct HabitRowView: View {
    let habit: WidgetHabit

    var body: some View {
        HStack(spacing: 6) {
            // Indicador de estado
            ZStack {
                Circle()
                    .fill(habit.isCompleted
                          ? Color.habitGreen
                          : Color.white.opacity(0.15))
                    .frame(width: 16, height: 16)

                if habit.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                }
            }

            // Título del hábito
            Text(habit.title)
                .font(.system(size: 11, weight: habit.isCompleted ? .regular : .medium))
                .foregroundColor(habit.isCompleted
                                 ? .white.opacity(0.6)
                                 : .white)
                .strikethrough(habit.isCompleted, color: .white.opacity(0.5))
                .lineLimit(1)

            Spacer()
        }
    }
}

// MARK: - Lock Screen (accessoryRectangular)

struct AccessoryRectangularView: View {
    let entry: HabitEntry

    var body: some View {
        HStack(spacing: 8) {
            // Barra de progreso lineal
            VStack(alignment: .leading, spacing: 3) {
                Text("Habitos hoy")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.primary)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.secondary.opacity(0.3))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.accentColor)
                            .frame(width: geo.size.width * entry.progress, height: 6)
                    }
                }
                .frame(height: 6)

                Text("\(entry.completed) de \(entry.total) completados")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Entry View (router by family)

struct HabitWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: HabitEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .accessoryRectangular:
            AccessoryRectangularView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Configuration

struct HabitWidget: Widget {
    let kind: String = "HabitWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitProvider()) { entry in
            HabitWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [.habitNavy, .habitBlue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("Habitos del dia")
        .description("Muestra tu progreso de habitos de hoy.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    HabitWidget()
} timeline: {
    HabitEntry.placeholder
}

#Preview("Medium", as: .systemMedium) {
    HabitWidget()
} timeline: {
    HabitEntry.placeholder
}

#Preview("Lock Screen", as: .accessoryRectangular) {
    HabitWidget()
} timeline: {
    HabitEntry.placeholder
}
