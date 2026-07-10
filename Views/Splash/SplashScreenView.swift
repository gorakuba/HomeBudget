import SwiftUI

public struct SplashScreenView: View {
    @Binding public var isFinished: Bool
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0
    
    public init(isFinished: Binding<Bool>) {
        self._isFinished = isFinished
    }
    
    public var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Icon Container
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(LinearGradient(
                            colors: [.indigo, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 120, height: 120)
                        .shadow(color: .indigo.opacity(0.3), radius: 15, x: 0, y: 10)
                    
                    Image(systemName: "wallet.pass.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .foregroundColor(.white)
                }
                .scaleEffect(scale)
                .opacity(opacity)
                
                // App Title
                VStack(spacing: 8) {
                    Text("HomeBudget")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Twój osobisty asystent finansowy")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .opacity(opacity)
                
                Spacer()
                
                // Loading Indicator
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.indigo)
                    .padding(.bottom, 50)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0)) {
                self.scale = 1.0
                self.opacity = 1.0
            }
            
            // Auto transition after 1.8 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    self.isFinished = true
                }
            }
        }
    }
}

#Preview {
    SplashScreenView(isFinished: .constant(false))
}
