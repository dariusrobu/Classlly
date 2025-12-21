import SwiftUI
import AuthenticationServices
import SwiftData

@MainActor
struct SignInView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.modelContext) var modelContext
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Logo & Title
                VStack(spacing: 16) {
                    Image(systemName: "graduationcap.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.white)
                        .shadow(radius: 10)
                    
                    Text("Classlly")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(radius: 5)
                    
                    Text("Master your academic life.")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                // Auth Buttons
                VStack(spacing: 16) {
                    // 1. Sign in with Apple (Native Button)
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            handleAppleLogin(result)
                        }
                    )
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .cornerRadius(12)
                    
                    // 2. Guest / Demo Option
                    Button(action: continueAsGuest) {
                        Text("Continue as Guest")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            )
                    }
                    
                    // Debug Reset (Optional, keep for development)
                    Button(action: {
                        authManager.debugReset()
                        try? modelContext.delete(model: StudentProfile.self)
                    }) {
                        Text("Debug: Reset App")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.top, 10)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            
            if isLoading {
                Color.black.opacity(0.4).ignoresSafeArea()
                ProgressView().tint(.white)
            }
        }
    }
    
    // MARK: - Actions
    
    private func handleAppleLogin(_ result: Result<ASAuthorization, Error>) {
        isLoading = true
        
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                
                // 1. Extract Name (Only available on first login!)
                var initialName = "Apple User"
                if let fullName = appleIDCredential.fullName {
                    let given = fullName.givenName ?? ""
                    let family = fullName.familyName ?? ""
                    if !given.isEmpty || !family.isEmpty {
                        initialName = "\(given) \(family)".trimmingCharacters(in: .whitespaces)
                    }
                }
                
                let email = appleIDCredential.email ?? "user@icloud.com"
                let userID = appleIDCredential.user
                
                print("🍎 Apple Login Success. Name: \(initialName), ID: \(userID)")
                
                // 2. Create User
                let user = StudentProfile(
                    name: initialName,
                    email: email
                )
                
                modelContext.insert(user)
                
                // 3. Sign In
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isLoading = false
                    authManager.signIn(with: user)
                }
            }
            
        case .failure(let error):
            isLoading = false
            print("🍎 Apple Login Failed: \(error.localizedDescription)")
        }
    }
    
    private func continueAsGuest() {
        isLoading = true
        print("👤 Continuing as Guest...")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let guestUser = StudentProfile(
                name: "Guest Student",
                email: "guest@local"
            )
            
            modelContext.insert(guestUser)
            try? modelContext.save()
            
            authManager.signIn(with: guestUser)
            isLoading = false
        }
    }
}
