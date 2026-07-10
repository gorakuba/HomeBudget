import Foundation

public protocol APIClientProtocol {
    func createExpense(title: String, amount: Double, category: String, date: Date) async throws -> String
    func fetchExpenses() async throws -> [Expense]
    func deleteExpense(id: String) async throws -> Bool
}
