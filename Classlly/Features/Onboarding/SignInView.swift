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
            backgroundGradient
                .opacity(0.9)
                .ignoresSafeArea()
            
            // 2. Animated Blobs (Optional purely for aesthetic depth)
            GeometryReader { proxy in
                Circle()
                    .fill(.white.opacity(0.1))
                    .frame(width: 300, height: 300)
                    .offset(x: -100, y: -100)
                    .blur(radius: 50)
                
                Circle()
                    .fill(.blue.opacity(0.2))
                    .frame(width: 250, height: 250)
                    .position(x: proxy.size.width, y: proxy.size.height * 0.8)
                    .blur(radius: 60)
            }
            .ignoresSafeArea()
            
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
                    // Apple Sign In
                    Button {
                        handleAppleSignIn()
                    } label: {
                        HStack {
                            Image(systemName: "apple.logo")
                                .font(.title2)
                            Text("Sign in with Apple")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(.white)
                        .foregroundStyle(.black)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    }
                    
                    // Demo User
                    Button {
                        handleDemoSignIn()
                    } label: {
                        Text("Try as Demo User")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)
                    }
                    
                    // Debug Reset
                    Button("Debug: Reset State") {
                        authManager.debugReset()
                        // Synchronous call on MainActor
                        DemoDataManager.shared.deleteAllData(modelContext: modelContext, includeProfile: true)
                    }
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.top, 20)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
        .overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    ProgressView()
                        .tint(.white)
                        .controlSize(.large)
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
            // 1. Clear existing data to ensure a fresh demo start
            // FIX: Removed 'await' because deleteAllData is MainActor but synchronous
            DemoDataManager.shared.deleteAllData(modelContext: modelContext, includeProfile: true)
            
            // 2. Generate the Heavy Stress data
            // FIX: Removed 'await' because createHeavyStressData is MainActor but synchronous
            DemoDataManager.shared.createHeavyStressData(modelContext: modelContext, cleanFirst: true, keepProfile: false)
            
            // 3. Manually create the AppUser to match the hardcoded Demo UID
            let demoUser = AppUser(
                id: "demo-user-001", // Matches AuthenticationManager.signInAsDemoUser
                email: "demo@classlly.com",
                fullName: "Demo Student"
            )
            // Pre-fill academic info so the profile looks complete
            demoUser.universityName = "Demo University"
            demoUser.facultyName = "Computer Science"
            demoUser.yearOfStudy = "2"
            demoUser.group = "CS-202"
            
            modelContext.insert(demoUser)
            
            // 4. Update Auth State
            authManager.completeOnboarding() // Skip sticky onboarding
            authManager.signInAsDemoUser()   // Set session
            
            // Small delay to let animations play/context save
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            isLoading = false
        }
    }
}

#Preview {
    SignInView()
        .environment(AuthenticationManager())
        // FIX: AppTheme is an ObservableObject, so we must use .environmentObject
        .environmentObject(AppTheme())
}
