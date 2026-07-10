import SwiftUI

public struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: BudgetViewModel
    
    @State private var amountString: String = ""
    @State private var title: String = ""
    @State private var selectedCategory: Category = .food
    @State private var date: Date = Date()
    
    public init() {}
    
    private var normalizedAmount: Double? {
        // Replace Polish comma with a dot for safe parsing to Double
        let cleanString = amountString
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(cleanString)
    }
    
    private var isSaveDisabled: Bool {
        guard let amount = normalizedAmount, amount > 0 else {
            return true
        }
        return title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Large Centered Amount Card
                        VStack(spacing: 8) {
                            Text("KWOTA")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)
                                .tracking(1)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                TextField("0,00", text: $amountString)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.center)
                                    .font(.system(size: 44, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: 240)
                                
                                Text("zł")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 32)
                        .frame(maxWidth: .infinity)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(24)
                        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
                        
                        // Transaction Details Card
                        VStack(spacing: 16) {
                            // Title Row
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Tytuł wydatku")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(.secondary)
                                
                                TextField("np. Zakupy w Biedronce", text: $title)
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .padding()
                                    .background(Color(.systemGroupedBackground))
                                    .cornerRadius(12)
                            }
                            
                            Divider()
                            
                            // Category Row
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Kategoria")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(.secondary)
                                
                                Picker("Wybierz kategorię", selection: $selectedCategory) {
                                    ForEach(Category.allCases) { category in
                                        HStack {
                                            Image(systemName: category.iconName)
                                            Text(category.localizedName)
                                        }
                                        .tag(category)
                                    }
                                }
                                .pickerStyle(.menu)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            Divider()
                            
                            // Date Picker
                            DatePicker(selection: $date, displayedComponents: .date) {
                                Text("Data płatności")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                            .environment(\.locale, Locale(identifier: "pl_PL"))
                        }
                        .padding(20)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(24)
                        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Dodaj wpis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Anuluj") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.indigo)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Zapisz") {
                        if let amount = normalizedAmount {
                            viewModel.addExpense(
                                title: title,
                                amount: amount,
                                category: selectedCategory,
                                date: date
                            )
                            dismiss()
                        }
                    }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(isSaveDisabled ? .gray : .indigo)
                    .disabled(isSaveDisabled)
                }
            }
        }
    }
}

#Preview {
    AddExpenseView()
        .environmentObject(BudgetViewModel())
}
