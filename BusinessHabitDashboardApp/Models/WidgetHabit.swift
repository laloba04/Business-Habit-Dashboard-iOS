//
//  WidgetHabit.swift
//  BusinessHabitDashboardApp
//
//  Created by Maria Bravo Angulo on 23/2/26.
//

import Foundation

/// Modelo ligero compartido entre la app principal y el widget de hábitos.
/// La app lo serializa en UserDefaults del App Group; el widget lo deserializa.
///
/// NOTA: El target HabitWidget define su propia copia idéntica de este struct
/// porque los targets de Swift no pueden importarse mutuamente de forma directa.
/// Ambas definiciones deben mantenerse en sincronía.
struct WidgetHabit: Codable, Identifiable {
    let id: String
    let title: String
    let isCompleted: Bool
}
