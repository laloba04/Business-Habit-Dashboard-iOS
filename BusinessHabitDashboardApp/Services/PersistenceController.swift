//
//  PersistenceController.swift
//  BusinessHabitDashboardApp
//
//  Created by Maria Bravo Angulo on 24/2/26.
//

import CoreData
import Foundation

// Controlador de persistencia CoreData para caché offline.
// Actúa como fuente de verdad local cuando no hay conexión a internet.
//
// Entidades configuradas en Model.xcdatamodeld:
//   • HabitEntity   — id, userID, title, completed, createdAt,
//                     reminderEnabled, reminderTime, reminderDays (Transformable)
//   • ExpenseEntity — id, userID, category, amount, createdAt

final class PersistenceController {

    // MARK: - Singleton

    static let shared = PersistenceController()

    // MARK: - Stack

    let container: NSPersistentContainer

    private init() {
        container = NSPersistentContainer(name: "Model")

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // El fallo al cargar el store es irrecuperable en producción.
                // En debug se imprime para facilitar el diagnóstico.
                print("[PersistenceController] Error cargando persistent store: \(error), \(error.userInfo)")
            }
        }

        // Fusiona automáticamente cambios del store hacia el viewContext.
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    // MARK: - Context

    var context: NSManagedObjectContext {
        container.viewContext
    }

    // MARK: - Save

    /// Persiste los cambios pendientes del viewContext.
    /// Llama a este método tras cada mutación que quieras guardar en disco.
    func saveContext() {
        let ctx = context
        guard ctx.hasChanges else { return }

        do {
            try ctx.save()
        } catch {
            print("[PersistenceController] Error al guardar contexto: \(error)")
        }
    }

    // MARK: - Habits

    /// Sustituye todos los HabitEntity del usuario con los hábitos proporcionados.
    /// Se usa una estrategia delete-then-insert para mantener los datos sincronizados con Supabase.
    func saveHabits(_ habits: [Habit]) {
        guard let userID = habits.first?.userID else {
            // Si la lista está vacía no hay nada que persistir.
            return
        }

        let ctx = context

        // 1. Borrar registros existentes del usuario para evitar duplicados.
        let deleteRequest = NSFetchRequest<NSManagedObject>(entityName: "HabitEntity")
        deleteRequest.predicate = NSPredicate(format: "userID == %@", userID as CVarArg)

        do {
            let existing = try ctx.fetch(deleteRequest)
            existing.forEach { ctx.delete($0) }
        } catch {
            print("[PersistenceController] Error borrando HabitEntity existentes: \(error)")
        }

        // 2. Insertar los hábitos frescos.
        for habit in habits {
            let entity = NSEntityDescription.insertNewObject(forEntityName: "HabitEntity", into: ctx)
            entity.setValue(habit.id, forKey: "id")
            entity.setValue(habit.userID, forKey: "userID")
            entity.setValue(habit.title, forKey: "title")
            entity.setValue(habit.completed, forKey: "completed")
            entity.setValue(habit.createdAt, forKey: "createdAt")
            entity.setValue(habit.reminderEnabled ?? false, forKey: "reminderEnabled")
            entity.setValue(habit.reminderTime, forKey: "reminderTime")
            // reminderDays es Transformable (NSSecureUnarchiveFromData); se almacena como NSArray.
            entity.setValue(habit.reminderDays as NSArray?, forKey: "reminderDays")
        }

        saveContext()
    }

    /// Devuelve los hábitos en caché para un usuario dado, ordenados por fecha descendente.
    func fetchHabits(userID: UUID) -> [Habit] {
        let ctx = context
        let request = NSFetchRequest<NSManagedObject>(entityName: "HabitEntity")
        request.predicate = NSPredicate(format: "userID == %@", userID as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        do {
            let entities = try ctx.fetch(request)
            return entities.compactMap { habitFrom(entity: $0) }
        } catch {
            print("[PersistenceController] Error leyendo HabitEntity: \(error)")
            return []
        }
    }

    /// Convierte un NSManagedObject de tipo HabitEntity en un Habit de dominio.
    private func habitFrom(entity: NSManagedObject) -> Habit? {
        guard
            let id         = entity.value(forKey: "id")        as? UUID,
            let userID     = entity.value(forKey: "userID")    as? UUID,
            let title      = entity.value(forKey: "title")     as? String,
            let completed  = entity.value(forKey: "completed") as? Bool,
            let createdAt  = entity.value(forKey: "createdAt") as? Date
        else {
            print("[PersistenceController] HabitEntity con datos incompletos, ignorando.")
            return nil
        }

        let reminderEnabled = entity.value(forKey: "reminderEnabled") as? Bool
        let reminderTime    = entity.value(forKey: "reminderTime")    as? Date
        // El Transformable se recupera como [Int] directamente gracias al transformer NSSecureUnarchiveFromData.
        let reminderDays    = entity.value(forKey: "reminderDays")    as? [Int]

        return Habit(
            id: id,
            userID: userID,
            title: title,
            completed: completed,
            createdAt: createdAt,
            reminderEnabled: reminderEnabled,
            reminderTime: reminderTime,
            reminderDays: reminderDays
        )
    }

    // MARK: - Expenses

    /// Sustituye todos los ExpenseEntity del usuario con los gastos proporcionados.
    func saveExpenses(_ expenses: [Expense]) {
        guard let userID = expenses.first?.userID else {
            return
        }

        let ctx = context

        // 1. Borrar registros existentes del usuario.
        let deleteRequest = NSFetchRequest<NSManagedObject>(entityName: "ExpenseEntity")
        deleteRequest.predicate = NSPredicate(format: "userID == %@", userID as CVarArg)

        do {
            let existing = try ctx.fetch(deleteRequest)
            existing.forEach { ctx.delete($0) }
        } catch {
            print("[PersistenceController] Error borrando ExpenseEntity existentes: \(error)")
        }

        // 2. Insertar los gastos frescos.
        for expense in expenses {
            let entity = NSEntityDescription.insertNewObject(forEntityName: "ExpenseEntity", into: ctx)
            entity.setValue(expense.id,        forKey: "id")
            entity.setValue(expense.userID,    forKey: "userID")
            entity.setValue(expense.category,  forKey: "category")
            entity.setValue(expense.amount,    forKey: "amount")
            entity.setValue(expense.createdAt, forKey: "createdAt")
        }

        saveContext()
    }

    /// Devuelve los gastos en caché para un usuario dado, ordenados por fecha descendente.
    func fetchExpenses(userID: UUID) -> [Expense] {
        let ctx = context
        let request = NSFetchRequest<NSManagedObject>(entityName: "ExpenseEntity")
        request.predicate = NSPredicate(format: "userID == %@", userID as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        do {
            let entities = try ctx.fetch(request)
            return entities.compactMap { expenseFrom(entity: $0) }
        } catch {
            print("[PersistenceController] Error leyendo ExpenseEntity: \(error)")
            return []
        }
    }

    /// Convierte un NSManagedObject de tipo ExpenseEntity en un Expense de dominio.
    private func expenseFrom(entity: NSManagedObject) -> Expense? {
        guard
            let id        = entity.value(forKey: "id")        as? UUID,
            let userID    = entity.value(forKey: "userID")    as? UUID,
            let category  = entity.value(forKey: "category")  as? String,
            let amount    = entity.value(forKey: "amount")    as? Double,
            let createdAt = entity.value(forKey: "createdAt") as? Date
        else {
            print("[PersistenceController] ExpenseEntity con datos incompletos, ignorando.")
            return nil
        }

        return Expense(
            id: id,
            userID: userID,
            category: category,
            amount: amount,
            createdAt: createdAt
        )
    }
}
