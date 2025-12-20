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
                    
                    // ✅ FIXED BUTTON LOGIC
                    Button(action: {
                        print("⚡️ Signing in as Demo User...")
                        
                        // 1. Wipe EVERYTHING (including old profiles) first
                        DemoDataManager.shared.deleteAllData(modelContext: modelContext, includeProfile: true)
                        
                        // 2. Generate Data (Subjects, Tasks, etc.)
                        // keepProfile: false doesn't matter here since we wiped anyway,
                        // but cleanFirst: false prevents double deletion.
                        DemoDataManager.shared.createHeavyStressData(
                            modelContext: modelContext,
                            cleanFirst: false,
                            keepProfile: false
                        )
                        
                        // 3. Create & Insert User LAST
                        // This ensures the user isn't deleted by the data manager
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
