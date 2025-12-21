import SwiftUI

@MainActor
struct StickyOnboardingView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    // State for the Carousel
    @State private var currentPage = 0
    
    // Onboarding Pages Data
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Academic Vision",
            description: "Visualize your success. Track your progress across semesters with intuitive charts and insights.",
            icon: "chart.bar.xaxis",
            color: .blue
        ),
        OnboardingPage(
            title: "Syllabus Scanning",
            description: "Digitize your life. Snap a photo of your syllabus and let AI extract your schedule and assignments.",
            icon: "doc.text.viewfinder",
            color: .purple
        ),
        OnboardingPage(
            title: "GPA Mastering",
            description: "Stay ahead of the curve. Use 'What-If' scenarios to calculate exactly what you need to score to get that A.",
            icon: "graduationcap.fill",
            color: .orange
        )
    ]
    
    var body: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()
            
            VStack {
                // MARK: - Carousel
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(), value: currentPage)
                
                // MARK: - Controls
                VStack(spacing: 24) {
                    // Page Indicators
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Capsule()
                                .fill(currentPage == index ? pages[currentPage].color : Color.gray.opacity(0.3))
                                .frame(width: currentPage == index ? 24 : 8, height: 8)
                                .animation(.spring(), value: currentPage)
                        }
                    }
                    
                    // Action Button
                    Button(action: handleNext) {
                        Text(currentPage == pages.count - 1 ? "Get Started" : "Next")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(pages[currentPage].color)
                            .cornerRadius(16)
                            .shadow(color: pages[currentPage].color.opacity(0.4), radius: 10, y: 5)
                    }
                    
                    // Skip Button (Only on first pages)
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            complete()
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    } else {
                        // Placeholder to keep spacing consistent
                        Text(" ").font(.subheadline)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
    }
    
    // MARK: - Logic
    
    private func handleNext() {
        if currentPage < pages.count - 1 {
            withAnimation {
                currentPage += 1
            }
        } else {
            complete()
        }
    }
    
    private func complete() {
        // Mark carousel as seen. This triggers ClassllyApp to switch to SignInView.
        withAnimation {
            authManager.completeCarousel()
        }
    }
}

// MARK: - Subviews & Models

struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.1))
                    .frame(width: 250, height: 250)
                
                Circle()
                    .fill(page.color.opacity(0.2))
                    .frame(width: 180, height: 180)
                
                Image(systemName: page.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(page.color)
            }
            .padding(.bottom, 40)
            
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(page.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 32)
                    .lineSpacing(4)
            }
            
            Spacer()
        }
    }
}
