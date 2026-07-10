import Foundation

public struct ExpenseMapper {
    public static func toDomain(_ proto: ExpenseProtoMessage) -> Expense {
        let uuid = UUID(uuidString: proto.id) ?? UUID()
        let category = Category(rawValue: proto.category) ?? .other
        let date = Date(timeIntervalSince1970: TimeInterval(proto.date))
        
        return Expense(
            id: uuid,
            title: proto.title,
            amount: proto.amount,
            category: category,
            date: date,
            syncStatus: .synced
        )
    }
    
    public static func toDomainList(_ protos: [ExpenseProtoMessage]) -> [Expense] {
        return protos.map { toDomain($0) }
    }
    
    public static func toProto(_ domain: Expense) -> ExpenseProtoMessage {
        return ExpenseProtoMessage(
            id: domain.id.uuidString,
            title: domain.title,
            amount: domain.amount,
            category: domain.category.rawValue,
            date: Int64(domain.date.timeIntervalSince1970)
        )
    }
}
