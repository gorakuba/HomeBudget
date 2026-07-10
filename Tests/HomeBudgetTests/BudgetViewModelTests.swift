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
}
