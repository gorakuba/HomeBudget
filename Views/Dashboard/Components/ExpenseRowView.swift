import SwiftUI

public struct ExpenseRowView: View {
    public let expense: Expense
    @EnvironmentObject private var viewModel: BudgetViewModel
    
    public init(expense: Expense) {
        self.expense = expense
    }
    
    public var body: some View {
        HStack(spacing: 16) {
            // Category Icon with soft background
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(expense.category.color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: expense.category.iconName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(expense.category.color)
            }
            
            // Text Details
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(viewModel.formatDate(expense.date))
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Amount
            Text("- \(viewModel.formatCurrency(expense.amount))")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

#Preview {
    ExpenseRowView(expense: Expense(
        title: "Zakupy w Lidlu",
        amount: 420.50,
        category: .food,
        date: Date()
    ))
    .environmentObject(BudgetViewModel())
    .padding()
    .background(Color(.systemGroupedBackground))
}
