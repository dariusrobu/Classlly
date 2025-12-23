import SwiftUI

struct StickyOnboardingView: View {
    // FIXED: Using modern @Environment syntax
    @Environment(AuthenticationManager.self) private var authManager
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            
            VStack {
                TabView(selection: $currentPage) {
                    OnboardingPageView(
                        imageName: "calendar",
                        title: "Organize Your Schedule",
                        description: "Keep track of all your classes and labs."
                    ).tag(0)
                    
                    OnboardingPageView(
                        imageName: "bell.badge",
                        title: "Never Miss a Deadline",
                        description: "Get timely notifications for exams."
                    ).tag(1)
                    
                    OnboardingPageView(
                        imageName: "person.2.crop.square.stack",
                        title: "Stay Connected",
                        description: "Sync with your university group."
                    ).tag(2)
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                // Controls
                VStack(spacing: 16) {
                    Button {
                        withAnimation {
                            if currentPage < 2 { currentPage += 1 }
                            else { completeOnboarding() }
                        }
                    } label: {
                        Text(currentPage == 2 ? "Get Started" : "Next")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    if currentPage < 2 {
                        Button("Skip") { completeOnboarding() }
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }
    
    private func completeOnboarding() {
        authManager.completeOnboarding()
    }
}

struct OnboardingPageView: View {
    let imageName: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: imageName)
                .resizable()
                .scaledToFit()
                .frame(height: 150)
                .foregroundColor(.accentColor)
            Text(title).font(.title).fontWeight(.bold).multilineTextAlignment(.center)
            Text(description).font(.body).foregroundColor(.secondary).multilineTextAlignment(.center).padding(.horizontal)
            Spacer()
        }
    }
}

#Preview {
    StickyOnboardingView()
        .environment(AuthenticationManager())
}
