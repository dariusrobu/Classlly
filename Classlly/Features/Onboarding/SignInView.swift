import SwiftUI
import AuthenticationServices

struct SignInView: View {
    // MARK: - Environment
    @Environment(AuthenticationManager.self) private var authManager
    @Environment(\.colorScheme) var colorScheme
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Header
            VStack(spacing: 12) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.tint)
                
                Text("Welcome to Classlly")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Your academic companion")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Actions
            VStack(spacing: 16) {
                // Apple Sign In
                Button {
                    handleAppleSignIn()
                } label: {
                    HStack {
                        Image(systemName: "apple.logo")
                        Text("Sign in with Apple")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(colorScheme == .dark ? Color.white : Color.black)
                    .foregroundColor(colorScheme == .dark ? Color.black : Color.white)
                    .cornerRadius(12)
                }
                
                // Demo User
                Button {
                    authManager.signInAsDemoUser()
                } label: {
                    Text("Try as Demo User")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Debug Reset (Restored)
                Button("Debug: Reset State") {
                    authManager.debugReset()
                }
                .font(.caption)
                .foregroundStyle(.red.opacity(0.8))
                .padding(.top, 20)
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView()
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
}

#Preview {
    SignInView()
        .environment(AuthenticationManager())
}
