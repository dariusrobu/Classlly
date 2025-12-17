import SwiftUI
import AuthenticationServices
import SwiftData

struct SignInView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    @Environment(\.modelContext) var modelContext
    
    @State private var showingProfileSetup = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack {
                    // Header
                    VStack(spacing: 16) {
                        Spacer()
                        
                        Image(systemName: "graduationcap.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                            .padding(24)
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                        
                        VStack(spacing: 8) {
                            Text("Welcome to Classlly")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Your all-in-one academic companion")
                                .font(.title3)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 40)
                    
                    // Features list
                    VStack(alignment: .leading, spacing: 24) {
                        FeatureRow(icon: "calendar", title: "Class Schedule", subtitle: "Organize your courses and timetable")
                        FeatureRow(icon: "checklist", title: "Task Management", subtitle: "Track assignments and deadlines")
                        FeatureRow(icon: "chart.bar", title: "Grade Tracking", subtitle: "Monitor your academic performance")
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                    Spacer()
                    
                    // Sign in button area
                    VStack(spacing: 12) {
                        SignInWithAppleButton(.signIn) { request in
                            let nonce = authManager.randomNonceString()
                            authManager.currentNonce = nonce
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { result in
                            authManager.handleSignInWithApple(result: result, modelContext: modelContext)
                        }
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 50)
                        .cornerRadius(10)
                        
                        // Demo User Button
                        Button(action: {
                            authManager.signInAsDemoUser()
                            calendarManager.loadDemoData()
                            DemoDataManager.shared.createHeavyStressData(modelContext: modelContext)
                        }) {
                            Text("Continue as Demo User")
                                .font(.headline)
                                .foregroundColor(.blue)
                                .frame(height: 50)
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .cornerRadius(10)
                        }
                        
                        // 🆕 New User Test Button
                        Button(action: {
                            authManager.startNewUserOnboarding()
                        }) {
                            Text("Start as New User")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(height: 50)
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        
                        Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                    .background(.regularMaterial)
                }
            }
            .navigationBarHidden(true)
            // Profile Setup Sheet
            .onChange(of: authManager.currentUser) { oldValue, newValue in
                if newValue != nil && !authManager.isAuthenticated {
                    showingProfileSetup = true
                }
            }
            .sheet(isPresented: $showingProfileSetup) {
                if let user = authManager.currentUser {
                    ProfileSetupView(user: user)
                }
            }
            // Onboarding Cover
            .fullScreenCover(isPresented: $authManager.showingOnboarding) {
                StickyOnboardingView()
            }
            // Loading Overlay
            .overlay {
                if authManager.isLoading {
                    LoadingOverlay()
                }
            }
        }
        .navigationViewStyle(.stack)
    }
    
    struct FeatureRow: View {
        let icon: String
        let title: String
        let subtitle: String
        
        var body: some View {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
    }
    
    struct LoadingOverlay: View {
        var body: some View {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    
                    Text("Signing you in...")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding(30)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 10)
            }
        }
    }
}
