import SwiftUI
import Charts

public struct DashboardView: View {
    @EnvironmentObject private var viewModel: BudgetViewModel
    @State private var isShowingAddExpense = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Card 1: Budget Summary
                        VStack(spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("DO ROZDYSPONOWANIA")
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundColor(.secondary)
                                        .tracking(1)
                                    
                                    Text(viewModel.formatCurrency(viewModel.remainingBudget))
                                        .font(.system(size: 34, weight: .bold, design: .rounded))
                                        .foregroundColor(viewModel.remainingBudget < 0 ? .red : .primary)
                                }
                                Spacer()
                            }
                            
                            // Progress bar
                            VStack(spacing: 8) {
                                GeometryReader { geo in
                                    let spent = viewModel.spentAmount
                                    let budget = viewModel.totalBudget
                                    let ratio = budget > 0 ? spent / budget : 1.0
                                    let progress = min(max(ratio, 0), 1)
                                    
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color.secondary.opacity(0.15))
                                        
                                        Capsule()
                                            .fill(viewModel.remainingBudget < 0 ? Color.red : Color.indigo)
                                            .frame(width: geo.size.width * CGFloat(progress))
                                    }
                                }
                                .frame(height: 10)
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("WYDANE")
                                            .font(.system(size: 9, weight: .bold, design: .rounded))
                                            .foregroundColor(.secondary)
                                        Text(viewModel.formatCurrency(viewModel.spentAmount))
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("BUDŻET")
                                            .font(.system(size: 9, weight: .bold, design: .rounded))
                                            .foregroundColor(.secondary)
                                        Text(viewModel.formatCurrency(viewModel.totalBudget))
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    }
                                }
                            }
                        }
                        .padding(24)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(24)
                        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
                        
                        // Card 2: Charts
                        VStack(alignment: .leading, spacing: 16) {
                            Text("PODZIAŁ WYDATKÓW")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)
                                .tracking(1)
                            
                            if viewModel.expenses.isEmpty {
                                HStack {
                                    Spacer()
                                    Text("Brak wydatków do wyświetlenia")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(.secondary)
                                        .padding(.vertical, 40)
                                    Spacer()
                                }
                            } else {
                                Chart(viewModel.categorySums) { item in
                                    SectorMark(
                                        angle: .value("Kwota", item.amount),
                                        innerRadius: .ratio(0.65),
                                        angularInset: 2.0
                                    )
                                    .cornerRadius(6)
                                    .foregroundStyle(item.category.color)
                                }
                                .frame(height: 180)
                                .chartBackground { chartProxy in
                                    GeometryReader { geo in
                                        if let plotFrame = chartProxy.plotFrame {
                                            let frame = geo[plotFrame]
                                            VStack(spacing: 2) {
                                                Text("WYDANE")
                                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                                    .foregroundColor(.secondary)
                                                    .tracking(0.5)
                                                
                                                Text(viewModel.formatCurrency(viewModel.spentAmount))
                                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                                    .foregroundColor(.primary)
                                            }
                                            .position(x: frame.midX, y: frame.midY)
                                        }
                                    }
                                }
                                
                                // Legend
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(viewModel.categorySums) { item in
                                            HStack(spacing: 6) {
                                                Circle()
                                                    .fill(item.category.color)
                                                    .frame(width: 8, height: 8)
                                                Text(item.category.localizedName)
                                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                                    .foregroundColor(.primary)
                                                Text(viewModel.formatCurrency(item.amount))
                                                    .font(.system(size: 11, weight: .regular, design: .rounded))
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 4)
                                }
                            }
                        }
                        .padding(24)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(24)
                        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
                        
                        // Card 3: Recent Operations
                        VStack(alignment: .leading, spacing: 16) {
                            Text("OSTATNIE OPERACJE")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)
                                .tracking(1)
                            
                            if viewModel.expenses.isEmpty {
                                HStack {
                                    Spacer()
                                    Text("Brak operacji")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(.secondary)
                                        .padding(.vertical, 20)
                                    Spacer()
                                }
                            } else {
                                LazyVStack(spacing: 12) {
                                    ForEach(viewModel.expenses) { expense in
                                        ExpenseRowView(expense: expense)
                                            .transition(.asymmetric(
                                                insertion: .move(edge: .top).combined(with: .opacity),
                                                removal: .opacity
                                            ))
                                    }
                                }
                            }
                        }
                        .padding(24)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(24)
                        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
                        .padding(.bottom, 100) // Space for floating button
                    }
                    .padding(16)
                }
                
                // Floating Action Pill Button
                Button {
                    isShowingAddExpense = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                        Text("Dodaj wydatek")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 28)
                    .background(LinearGradient(
                        colors: [.indigo, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .cornerRadius(30)
                    .shadow(color: .indigo.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .padding(.bottom, 24)
            }
            .navigationTitle("Czerwiec 2026")
            .sheet(isPresented: $isShowingAddExpense) {
                AddExpenseView()
            }
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(BudgetViewModel())
}
