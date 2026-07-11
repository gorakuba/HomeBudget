import Foundation

public protocol APIClientProtocol {
    func createExpense(title: String, amount: Double, category: String, date: Date) async throws -> String
    func fetchExpenses() async throws -> [Expense]
    func deleteExpense(id: String) async throws -> Bool
    func fetchBudget(month: String) async throws -> Double
    func updateBudget(month: String, amount: Double) async throws -> Bool
}
