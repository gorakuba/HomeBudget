import Foundation
import SwiftUI

public final class BudgetViewModel: ObservableObject {
    @Published public var totalBudget: Double = 0.0
    @Published public var selectedDate: Date = Date()
    @Published public var expenses: [Expense] = []
    @Published public var isMovingForward: Bool = true
    @Published public var errorMessage: String? = nil
    
    private let apiClient: APIClientProtocol
    
    public init(apiClient: APIClientProtocol = GRPCExpenseClient()) {
        self.apiClient = apiClient
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
    
    public var filteredExpenses: [Expense] {
        let calendar = Calendar.current
        return expenses.filter { expense in
            calendar.isDate(expense.date, equalTo: selectedDate, toGranularity: .month) &&
            calendar.isDate(expense.date, equalTo: selectedDate, toGranularity: .year)
        }
    }
    
    public var spentAmount: Double {
        filteredExpenses.reduce(0.0) { $0 + $1.amount }
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
    
    public var selectedMonthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: selectedDate)
    }
    
    public var selectedMonthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pl_PL")
        formatter.dateFormat = "LLLL yyyy"
        let raw = formatter.string(from: selectedDate)
        return raw.prefix(1).uppercased() + raw.dropFirst()
    }
    
    public func changeMonth(by months: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: months, to: selectedDate) {
            self.selectedDate = newDate
            fetchBudgetForSelectedMonth()
        }
    }
    
    public func fetchBudgetForSelectedMonth() {
        let monthString = selectedMonthString
        Task {
            do {
                let serverBudget = try await apiClient.fetchBudget(month: monthString)
                await MainActor.run {
                    withAnimation {
                        self.totalBudget = serverBudget
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Nie udało się pobrać budżetu dla miesiąca \(monthString)."
                }
            }
        }
    }
    
    public func fetchExpensesFromServer() {
        let monthString = selectedMonthString
        Task {
            do {
                let serverExpenses = try await apiClient.fetchExpenses()
                let serverBudget = try await apiClient.fetchBudget(month: monthString)
                
                await MainActor.run {
                    withAnimation(.easeInOut) {
                        self.expenses = serverExpenses
                        self.totalBudget = serverBudget
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Nie udało się pobrać danych z serwera."
                }
            }
        }
    }
    
    public func updateBudget(_ amount: Double) {
        let monthString = selectedMonthString
        Task {
            do {
                let success = try await apiClient.updateBudget(month: monthString, amount: amount)
                if success {
                    await MainActor.run {
                        withAnimation {
                            self.totalBudget = amount
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Nie udało się zaktualizować budżetu: \(error.localizedDescription)"
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
            let sum = filteredExpenses.filter { $0.category == category }.reduce(0.0) { $0 + $1.amount }
            return CategorySum(category: category, amount: sum)
        }
    }
}
