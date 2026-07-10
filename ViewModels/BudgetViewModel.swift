import Foundation
import SwiftUI

public final class BudgetViewModel: ObservableObject {
    @Published public var totalBudget: Double = 5000.0
    @Published public var expenses: [Expense] = []
    @Published public var errorMessage: String? = nil
    
    private let apiClient: APIClientProtocol
    
    public init(apiClient: APIClientProtocol = GRPCExpenseClient()) {
        self.apiClient = apiClient
        loadMockData()
    }
    
    private func loadMockData() {
        let calendar = Calendar.current
        let today = Date()
        
        let date1 = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let date2 = calendar.date(byAdding: .day, value: -3, to: today) ?? today
        let date3 = calendar.date(byAdding: .day, value: -5, to: today) ?? today
        let date4 = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        
        self.expenses = [
            Expense(title: "Czynsz za mieszkanie", amount: 2100.0, category: .housing, date: date1, syncStatus: .synced),
            Expense(title: "Zakupy w Lidlu", amount: 420.50, category: .food, date: date2, syncStatus: .synced),
            Expense(title: "Paliwo Orlen", amount: 250.0, category: .transport, date: date3, syncStatus: .synced),
            Expense(title: "Bilety do kina", amount: 95.0, category: .entertainment, date: date4, syncStatus: .synced)
        ]
    }
    
    public var spentAmount: Double {
        expenses.reduce(0.0) { $0 + $1.amount }
    }
    
    public var remainingBudget: Double {
        totalBudget - spentAmount
    }
    
    public func addExpense(title: String, amount: Double, category: Category, date: Date = Date()) {
        let tempId = UUID()
        let newExpense = Expense(id: tempId, title: title, amount: amount, category: category, date: date, syncStatus: .syncing)
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            self.expenses.insert(newExpense, at: 0)
        }
        
        Task {
            do {
                let serverId = try await apiClient.createExpense(title: title, amount: amount, category: category.rawValue, date: date)
                await MainActor.run {
                    if let index = self.expenses.firstIndex(where: { $0.id == tempId }) {
                        if let newUUID = UUID(uuidString: serverId) {
                            self.expenses[index].id = newUUID
                        }
                        self.expenses[index].syncStatus = .synced
                    }
                }
            } catch {
                await MainActor.run {
                    withAnimation {
                        self.expenses.removeAll(where: { $0.id == tempId })
                    }
                    self.errorMessage = "Nie udało się zapisać wydatku na serwerze: \(error.localizedDescription)"
                }
            }
        }
    }
    
    public func fetchExpensesFromServer() {
        Task {
            do {
                let serverExpenses = try await apiClient.fetchExpenses()
                await MainActor.run {
                    withAnimation(.easeInOut) {
                        self.expenses = serverExpenses
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Nie udało się pobrać danych z serwera."
                }
            }
        }
    }
    
    // MARK: - Polish Localized Helpers
    
    public func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pl_PL")
        formatter.currencySymbol = "zł"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        
        // Remove non-breaking spaces or customize styling if needed
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f zł", value)
    }
    
    public func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pl_PL")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // Helper structural model for visual charts
    public struct CategorySum: Identifiable {
        public let category: Category
        public let amount: Double
        public var id: String { category.id }
    }
    
    public var categorySums: [CategorySum] {
        Category.allCases.map { category in
            let sum = expenses.filter { $0.category == category }.reduce(0.0) { $0 + $1.amount }
            return CategorySum(category: category, amount: sum)
        }
    }
}
