import XCTest
@testable import HomeBudget

final class BudgetViewModelTests: XCTestCase {
    
    @MainActor
    func testAddExpense_OptimisticUpdateAndSuccess() async throws {
        let mockClient = MockAPIClient()
        mockClient.delaySeconds = 0.05
        mockClient.mockUUID = "99999999-8888-7777-6666-555555555555"
        
        let viewModel = BudgetViewModel(apiClient: mockClient)
        let initialCount = viewModel.expenses.count
        
        // Trigger addExpense
        viewModel.addExpense(title: "Test Biedronka", amount: 150.0, category: .food)
        
        // Immediately verify optimistic insert
        XCTAssertEqual(viewModel.expenses.count, initialCount + 1)
        XCTAssertEqual(viewModel.expenses.first?.title, "Test Biedronka")
        XCTAssertEqual(viewModel.expenses.first?.syncStatus, .syncing)
        
        // Wait for async background task to complete
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2s
        
        XCTAssertEqual(viewModel.expenses.count, initialCount + 1)
        XCTAssertEqual(viewModel.expenses.first?.id.uuidString.lowercased(), mockClient.mockUUID.lowercased())
        XCTAssertEqual(viewModel.expenses.first?.syncStatus, .synced)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    @MainActor
    func testAddExpense_RollbackOnError() async throws {
        let mockClient = MockAPIClient()
        mockClient.delaySeconds = 0.05
        mockClient.shouldReturnError = true
        
        let viewModel = BudgetViewModel(apiClient: mockClient)
        let initialCount = viewModel.expenses.count
        
        // Trigger addExpense
        viewModel.addExpense(title: "Test Błąd", amount: 99.0, category: .other)
        
        // Verify optimistic insert happened
        XCTAssertEqual(viewModel.expenses.count, initialCount + 1)
        XCTAssertEqual(viewModel.expenses.first?.syncStatus, .syncing)
        
        // Wait for async task to fail and rollback
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2s
        
        // Verify rollback: count should be back to initial, and error message should be set
        XCTAssertEqual(viewModel.expenses.count, initialCount)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    @MainActor
    func testFetchBudget_Success() async throws {
        let mockClient = MockAPIClient()
        mockClient.delaySeconds = 0.0
        mockClient.mockBudgetAmount = 7500.0
        
        let viewModel = BudgetViewModel(apiClient: mockClient)
        viewModel.fetchExpensesFromServer()
        
        // Wait for async background task to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        
        XCTAssertEqual(viewModel.totalBudget, 7500.0)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    @MainActor
    func testUpdateBudget_Success() async throws {
        let mockClient = MockAPIClient()
        mockClient.delaySeconds = 0.0
        mockClient.mockBudgetAmount = 5000.0
        
        let viewModel = BudgetViewModel(apiClient: mockClient)
        viewModel.updateBudget(6200.0)
        
        // Wait for async background task to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        
        XCTAssertEqual(viewModel.totalBudget, 6200.0)
        XCTAssertEqual(mockClient.mockBudgetAmount, 6200.0)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    @MainActor
    func testInitialBudgetIsZero() async throws {
        let mockClient = MockAPIClient()
        mockClient.delaySeconds = 0.0
        mockClient.mockBudgetAmount = 0.0
        
        let viewModel = BudgetViewModel(apiClient: mockClient)
        XCTAssertEqual(viewModel.totalBudget, 0.0)
        
        viewModel.fetchExpensesFromServer()
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        
        XCTAssertEqual(viewModel.totalBudget, 0.0)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    @MainActor
    func testChangeMonthAndFiltering() async throws {
        let mockClient = MockAPIClient()
        mockClient.delaySeconds = 0.0
        mockClient.mockBudgetAmount = 1200.0
        
        let viewModel = BudgetViewModel(apiClient: mockClient)
        // Add an expense in current month
        viewModel.addExpense(title: "Wydatki ten miesiąc", amount: 100.0, category: .food, date: Date())
        
        // Add an expense in previous month
        let lastMonthDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        viewModel.addExpense(title: "Wydatki poprzedni miesiąc", amount: 300.0, category: .transport, date: lastMonthDate)
        
        // Currently on current month -> should see only current month's expense (plus any mock data if loaded, but here we only added via addExpense)
        XCTAssertEqual(viewModel.filteredExpenses.count, 1)
        XCTAssertEqual(viewModel.spentAmount, 100.0)
        
        // Change to previous month
        viewModel.changeMonth(by: -1)
        try await Task.sleep(nanoseconds: 100_000_000) // wait for fetchBudgetForSelectedMonth
        
        XCTAssertEqual(viewModel.filteredExpenses.count, 1)
        XCTAssertEqual(viewModel.filteredExpenses.first?.title, "Wydatki poprzedni miesiąc")
        XCTAssertEqual(viewModel.spentAmount, 300.0)
    }
}
