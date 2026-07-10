import Foundation
import SwiftUI

public enum SyncStatus: String, Codable, Equatable {
    case syncing
    case synced
    case failed
}

public struct Expense: Identifiable, Codable, Equatable {
    public var id: UUID
    public var title: String
    public var amount: Double
    public var category: Category
    public var date: Date
    public var syncStatus: SyncStatus
    
    public init(id: UUID = UUID(), title: String, amount: Double, category: Category, date: Date = Date(), syncStatus: SyncStatus = .synced) {
        self.id = id
        self.title = title
        self.amount = amount
        self.category = category
        self.date = date
        self.syncStatus = syncStatus
    }
}

public enum Category: String, CaseIterable, Identifiable, Codable {
    case food
    case housing
    case transport
    case entertainment
    case other
    
    public var id: String { self.rawValue }
    
    public var localizedName: String {
        switch self {
        case .food:
            return "Spożywcze"
        case .housing:
            return "Mieszkanie"
        case .transport:
            return "Transport"
        case .entertainment:
            return "Rozrywka"
        case .other:
            return "Inne"
        }
    }
    
    public var iconName: String {
        switch self {
        case .food:
            return "cart.fill"
        case .housing:
            return "house.fill"
        case .transport:
            return "car.fill"
        case .entertainment:
            return "gamecontroller.fill"
        case .other:
            return "creditcard.fill"
        }
    }
    
    public var color: Color {
        switch self {
        case .food:
            return .green
        case .housing:
            return .blue
        case .transport:
            return .orange
        case .entertainment:
            return .purple
        case .other:
            return .gray
        }
    }
}
