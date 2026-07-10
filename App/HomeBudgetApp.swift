import SwiftUI

@main
public struct HomeBudgetApp: App {
    @StateObject private var viewModel = BudgetViewModel()
    @State private var isSplashFinished = false
    
    public init() {}
    
    public var body: some Scene {
        WindowGroup {
            Group {
                if !isSplashFinished {
                    SplashScreenView(isFinished: $isSplashFinished)
                } else {
                    DashboardView()
                        .transition(.opacity)
                }
            }
            .environmentObject(viewModel)
            .preferredColorScheme(.light) // Set standard light scheme or make it support dynamic color scheme
        }
    }
}
