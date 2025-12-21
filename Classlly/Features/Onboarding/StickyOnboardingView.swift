import SwiftUI
import SwiftData

struct StickyOnboardingView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var themeManager: AppTheme
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    @Environment(\.modelContext) var modelContext
    
    // Flow State
    @State private var currentStep = 1
    @State private var direction: AnyTransition = .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
    
    // User Data
    @State private var semesterEndDate = Calendar.current.date(byAdding: .month, value: 4, to: Date()) ?? Date()
    @State private var subjectCount: Double = 4
    
    // UI Triggers
    @State private var showConfetti = false
    @State private var showPopup = false
    
    var body: some View {
        ZStack {
            // Shared Background
            Color.black.ignoresSafeArea()
            
            // Step Content
            VStack {
                switch currentStep {
                case 1:
                    StickyHookView(onNext: nextStep)
                        .transition(direction)
                case 2:
                    StickyUniversityView(onNext: nextStep)
                        .transition(direction)
                case 3:
                    StickySetupView(onNext: nextStep, onGenerateDemo: generateAndProceed)
                        .transition(direction)
                case 4:
                    StickyVibeView(onFinish: finishOnboarding)
                        .transition(direction)
                default:
                    EmptyView()
                }
            }
            .animation(.easeInOut(duration: 0.5), value: currentStep)
            
            // Confetti Overlay
            if showConfetti {
                ConfettiView()
            }
            
            // "Aha!" Popup
            if showPopup {
                Color.black.opacity(0.4).ignoresSafeArea()
                VStack(spacing: 16) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 40))
                        .foregroundColor(.yellow)
                    Text("Schedule Generated!")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("We built a base schedule for you.\nTap any block later to rename it to your actual subject.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                    
                    Button("Got it") {
                        withAnimation { showPopup = false }
                    }
                    .fontWeight(.bold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
                    .foregroundColor(.white)
                }
                .padding(24)
                .background(Color(white: 0.15))
                .cornerRadius(20)
                .padding(40)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Logic
    
    private func nextStep() {
        withAnimation {
            currentStep += 1
        }
    }
    
    private func generateAndProceed() {
        // 1. Template Injection
        OnboardingGenerator.generateTemplate(
            context: modelContext,
            subjectCount: Int(subjectCount),
            semesterEnd: semesterEndDate
        )
        
        // 2. Move to next step (Vibe Check)
        withAnimation {
            currentStep = 4
        }
        
        // 3. Trigger "Aha" moments
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showConfetti = true
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { showPopup = true }
        }
    }
    
    private func finishOnboarding() {
        // Marks onboarding as done -> Triggers switch to SignInView in ClassllyApp
        authManager.completeStickyOnboarding(modelContext: modelContext)
    }
}

// ... (Subviews: Hook, University, Setup, Vibe remain unchanged in functionality)

// MARK: - Data Model
enum OnboardingPainPoint: String, CaseIterable, Identifiable {
    case exams = "Passing Exams"
    case schedule = "Organizing Schedule"
    case procrastination = "Stop Procrastinating"
    
    var id: String { self.rawValue }
    var icon: String {
        switch self {
        case .exams: return "graduationcap.fill"
        case .schedule: return "calendar"
        case .procrastination: return "hourglass"
        }
    }
}

// MARK: - Confetti View
// ✅ Added here to ensure visibility
struct ConfettiView: View {
    @State private var animate = false
    var body: some View {
        ZStack {
            ForEach(0..<50) { _ in
                Circle()
                    .fill(Color(
                        red: .random(in: 0...1),
                        green: .random(in: 0...1),
                        blue: .random(in: 0...1)
                    ))
                    .frame(width: 8, height: 8)
                    .offset(x: animate ? .random(in: -200...200) : 0, y: animate ? .random(in: -200...200) : 0)
                    .opacity(animate ? 0 : 1)
            }
        }
        .onAppear { withAnimation(.easeOut(duration: 1.5)) { animate = true } }
    }
}
