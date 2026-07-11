import Foundation

// Represents the Protobuf generated message structure for ExpenseMessage
public struct ExpenseProtoMessage: Codable, Equatable {
    public let id: String
    public let title: String
    public let amount: Double
    public let category: String
    public let date: Int64
    
    public init(id: String, title: String, amount: Double, category: String, date: Int64) {
        self.id = id
        self.title = title
        self.amount = amount
        self.category = category
        self.date = date
    }
}

public class GRPCExpenseClient: APIClientProtocol {
    private let host: String
    private let port: Int
    private let scheme: String
    
    public init(
        host: String = (Bundle.main.object(forInfoDictionaryKey: "APIHost") as? String) ?? "127.0.0.1",
        port: Int = Int((Bundle.main.object(forInfoDictionaryKey: "APIPort") as? String) ?? "50051") ?? 50051,
        scheme: String = (Bundle.main.object(forInfoDictionaryKey: "APIScheme") as? String) ?? "http"
    ) {
        self.host = host
        self.port = port
        self.scheme = scheme
    }
    
    public func createExpense(title: String, amount: Double, category: String, date: Date) async throws -> String {
        let protoDate = Int64(date.timeIntervalSince1970)
        let requestPayload: [String: Any] = [
            "title": title,
            "amount": amount,
            "category": category,
            "date": protoDate
        ]
        
        let responseData = try await performGRPCCall(
            method: "/expense.ExpenseService/CreateExpense",
            payload: requestPayload
        )
        
        guard let response = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
              let id = response["id"] as? String else {
            throw GRPCError.decodingFailed
        }
        
        return id
    }
    
    public func fetchExpenses() async throws -> [Expense] {
        let responseData = try await performGRPCCall(
            method: "/expense.ExpenseService/GetExpenses",
            payload: [:]
        )
        
        guard let response = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
              let list = response["expenses"] as? [[String: Any]] else {
            return []
        }
        
        var protoMessages: [ExpenseProtoMessage] = []
        for item in list {
            if let id = item["id"] as? String,
               let title = item["title"] as? String,
               let amount = item["amount"] as? Double,
               let category = item["category"] as? String,
               let date = item["date"] as? Int64 {
                protoMessages.append(ExpenseProtoMessage(id: id, title: title, amount: amount, category: category, date: date))
            }
        }
        
        return ExpenseMapper.toDomainList(protoMessages)
    }
    
    public func deleteExpense(id: String) async throws -> Bool {
        let responseData = try await performGRPCCall(
            method: "/expense.ExpenseService/DeleteExpense",
            payload: ["id": id]
        )
        
        guard let response = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
              let success = response["success"] as? Bool else {
            return false
        }
        
        return success
    }
    
    public func fetchBudget(month: String) async throws -> Double {
        let responseData = try await performGRPCCall(
            method: "/expense.ExpenseService/GetBudget",
            payload: ["month": month]
        )
        
        guard let response = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
              let amount = response["amount"] as? Double else {
            throw GRPCError.decodingFailed
        }
        
        return amount
    }
    
    public func updateBudget(month: String, amount: Double) async throws -> Bool {
        let responseData = try await performGRPCCall(
            method: "/expense.ExpenseService/SetBudget",
            payload: ["month": month, "amount": amount]
        )
        
        guard let response = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
              let success = response["success"] as? Bool else {
            throw GRPCError.decodingFailed
        }
        
        return success
    }
    
    private func performGRPCCall(method: String, payload: [String: Any]) async throws -> Data {
        let portString = (port == 80 || port == 443) ? "" : ":\(port)"
        guard let url = URL(string: "\(scheme)://\(host)\(portString)\(method)") else {
            throw GRPCError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/grpc+json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw GRPCError.serverError
        }
        
        return data
    }
}

public enum GRPCError: Error {
    case invalidURL
    case serverError
    case decodingFailed
}
