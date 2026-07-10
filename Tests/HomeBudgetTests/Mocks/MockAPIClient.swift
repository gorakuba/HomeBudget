import Foundation
@testable import HomeBudget

public class MockAPIClient: APIClientProtocol {
    public var shouldReturnError: Bool = false
    public var mockUUID: String = "11111111-2222-3333-4444-555555555555"
    public var mockExpenses: [Expense] = []
    public var delaySeconds: TimeInterval = 0.1
    
    public init() {}
    
    public func createExpense(title: String, amount: Double, category: String, date: Date) async throws -> String {
        if delaySeconds > 0 {
            try? await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
        }
        if shouldReturnError {
            throw NSError(domain: "MockAPIClient", code: 500, userInfo: [NSLocalizedDescriptionKey: "Symulowany błąd sieciowy"])
        }
        return mockUUID
    }
    
    public func fetchExpenses() async throws -> [Expense] {
        if delaySeconds > 0 {
            try? await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
        }
        if shouldReturnError {
            throw NSError(domain: "MockAPIClient", code: 500, userInfo: [NSLocalizedDescriptionKey: "Symulowany błąd pobierania"])
        }
        return mockExpenses
    }
    
    public func deleteExpense(id: String) async throws -> Bool {
        if shouldReturnError {
            throw NSError(domain: "MockAPIClient", code: 500, userInfo: [NSLocalizedDescriptionKey: "Symulowany błąd usuwania"])
        }
        return true
    }
}
