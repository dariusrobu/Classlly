import SwiftUI
import SwiftData
import AuthenticationServices

struct SignInView: View {
    // MARK: - Environment
    @Environment(AuthenticationManager.self) private var authManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // MARK: - Gradient Colors
    private let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.4, blue: 0.6), // Pinkish
            Color(red: 0.6, green: 0.2, blue: 0.8), // Purple
            Color(red: 1.0, green: 0.6, blue: 0.2)  // Orange accent
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        ZStack {
            // 1. Vibrant Background
            backgroundGradient.opacity(0.9).ignoresSafeArea()
            
            // 2. Animated Blobs
            GeometryReader { proxy in
                Circle().fill(.white.opacity(0.1)).frame(width: 300, height: 300)
                    .offset(x: -100, y: -100).blur(radius: 50)
                
                Circle().fill(.blue.opacity(0.2)).frame(width: 250, height: 250)
                    .position(x: proxy.size.width, y: proxy.size.height * 0.8).blur(radius: 60)
            }.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // MARK: - Header
                VStack(spacing: 16) {
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    
                    Text("Classlly")
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    Text("Your academic companion")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(.bottom, 40)
                
                Spacer()
                
                // MARK: - Actions
                VStack(spacing: 16) {
                    Button { handleAppleSignIn() } label: {
                        HStack {
                            Image(systemName: "apple.logo").font(.title2)
                            Text("Sign in with Apple").fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity).frame(height: 56)
                        .background(.white).foregroundStyle(.black)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    }
                    
                    Button { handleDemoSignIn() } label: {
                        Text("Try as Demo User")
                            .font(.headline).foregroundStyle(.white)
                            .padding(.vertical, 12).padding(.horizontal, 24)
                            .background(.ultraThinMaterial).cornerRadius(20)
                    }
                    
                    Button("Debug: Reset State") {
                        authManager.debugReset()
                        DemoDataManager.shared.deleteAllData(modelContext: modelContext, includeProfile: true)
                    }
                    .font(.caption).foregroundStyle(.white.opacity(0.6)).padding(.top, 20)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
        .overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    ProgressView().tint(.white).controlSize(.large)
                }
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
    }
    
    // MARK: - Handlers
    
    private func handleAppleSignIn() {
        isLoading = true
        Task {
            do {
                try await authManager.signInWithApple()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    private func handleDemoSignIn() {
        isLoading = true
        
        Task {
            // 1. Clean up old data
            DemoDataManager.shared.deleteAllData(modelContext: modelContext, includeProfile: true)
            
            // 2. Create the User Profile FIRST (Critical for RootView check)
            DemoDataManager.shared.createDemoProfile(modelContext: modelContext)
            
            // 3. Create Demo Content
            DemoDataManager.shared.createHeavyStressData(modelContext: modelContext, cleanFirst: false, keepProfile: true)
            
            // 4. Update Auth State
            // We use MainActor.run to ensure UI updates happen on main thread
            await MainActor.run {
                authManager.completeOnboarding()
                authManager.signInAsDemoUser()
                isLoading = false
            }
        }
    }
}

#Preview {
    SignInView()
        .environment(AuthenticationManager())
        .environmentObject(AppTheme.shared)
}
