import SwiftUI
import SwiftData

struct SignInView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.modelContext) var modelContext
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "graduationcap.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.white)
                    
                    Text("Classlly")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Master your academic life.")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    Button(action: {
                        authManager.signIn()
                    }) {
                        HStack {
                            Image(systemName: "apple.logo")
                            Text("Sign in with Apple")
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        print("⚡️ Signing in as Demo User...")
                        
                        // 1. Wipe EVERYTHING (including old profiles) first
                        DemoDataManager.shared.deleteAllData(modelContext: modelContext, includeProfile: true)
                        
                        // 2. Generate Data
                        DemoDataManager.shared.createHeavyStressData(
                            modelContext: modelContext,
                            cleanFirst: false,
                            keepProfile: false
                        )
                        
                        // 3. Create & Insert User LAST
                        let user = authManager.signInAsDemoUser()
                        modelContext.insert(user)
                        
                        try? modelContext.save()
                        print("✅ Demo User & Data Created Successfully")
                        
                    }) {
                        Text("Try as Demo User")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding()
                    }
                    
                    // ✅ NEW DEBUG BUTTON
                    Button(action: {
                        print("🧨 Debug Reset Triggered")
                        
                        // 1. Wipe Data
                        DemoDataManager.shared.deleteAllData(modelContext: modelContext, includeProfile: true)
                        
                        // 2. Reset Auth State
                        authManager.debugReset()
                    }) {
                        Text("Debug: Reset My Account")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.red.opacity(0.8))
                            .padding(.top, 10)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    SignInView()
        .environmentObject(AuthenticationManager.shared)
}
