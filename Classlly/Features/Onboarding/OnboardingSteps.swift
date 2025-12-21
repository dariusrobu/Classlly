import SwiftUI
import SwiftData

// MARK: - Step 1: Hook
struct StickyHookView: View {
    let onNext: () -> Void
    @State private var isCompleted = false
    @State private var showXP = false
    
    var body: some View {
        VStack {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(isCompleted ? Color.green : Color(white: 0.15))
                    .frame(height: 80)
                    .overlay(
                        HStack {
                            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.title)
                                .foregroundColor(isCompleted ? .white : .gray)
                            Text("Finish Onboarding")
                                .font(.headline)
                                .foregroundColor(.white)
                                .strikethrough(isCompleted)
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                    )
                    .scaleEffect(isCompleted ? 1.05 : 1.0)
                    .onTapGesture {
                        if !isCompleted {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            withAnimation(.spring()) { isCompleted = true }
                            withAnimation(.easeOut(duration: 0.8)) { showXP = true }
                        }
                    }
                
                if showXP {
                    Text("XP +50").font(.title3).fontWeight(.black).foregroundColor(.yellow)
                        .offset(y: -60).transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.horizontal)
            Spacer()
            
            if isCompleted {
                Button(action: onNext) {
                    Text("Next").font(.headline).fontWeight(.bold).foregroundColor(.black)
                        .frame(maxWidth: .infinity).padding().background(Color.white).cornerRadius(12)
                }
                .padding(.horizontal).padding(.bottom, 80).transition(.opacity)
            }
        }
    }
}

// MARK: - Step 2: University
struct StickyUniversityView: View {
    let onNext: () -> Void
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    @State private var isConfigured = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Where do you study?").font(.largeTitle).fontWeight(.bold).foregroundColor(.white)
            
            Button(action: {
                Task { @MainActor in
                    calendarManager.loadDemoData()
                    withAnimation { isConfigured = true }
                }
            }) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Universitatea Babeș-Bolyai").fontWeight(.bold)
                        Text("Cluj-Napoca").font(.caption).opacity(0.8)
                    }
                    Spacer()
                    if isConfigured {
                        Text("Configured!").font(.caption).fontWeight(.bold).padding(6).background(Color.white.opacity(0.2)).clipShape(Capsule())
                        Image(systemName: "checkmark.circle.fill")
                    } else { Image(systemName: "building.columns.fill") }
                }
                .foregroundColor(.white).padding().background(isConfigured ? Color.green : Color.blue).cornerRadius(16)
            }
            .disabled(isConfigured)
            
            Button(action: onNext) {
                HStack { Text("Other University"); Spacer(); Image(systemName: "chevron.right") }
                    .foregroundColor(.white).padding().background(Color(white: 0.15)).cornerRadius(16)
            }
            Spacer()
            
            if isConfigured {
                Button("Continue", action: onNext)
                    .font(.headline).foregroundColor(.black).frame(maxWidth: .infinity).padding().background(Color.white).cornerRadius(12).padding(.bottom, 80)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Step 3: Setup
struct StickySetupView: View {
    let onNext: () -> Void
    let onGenerateDemo: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Build your Schedule").font(.largeTitle).fontWeight(.bold).foregroundColor(.white)
            HStack(spacing: 16) {
                Button(action: onNext) {
                    VStack(spacing: 12) {
                        Image(systemName: "camera.fill").font(.largeTitle)
                        Text("Scan\nTimetable").multilineTextAlignment(.center)
                    }
                    .font(.headline).foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 160).background(Color(white: 0.15)).cornerRadius(20)
                }
                Button(action: onGenerateDemo) {
                    VStack(spacing: 12) {
                        Image(systemName: "square.grid.2x2.fill").font(.largeTitle)
                        Text("Use Demo\nTemplate").multilineTextAlignment(.center)
                    }
                    .font(.headline).foregroundColor(.black).frame(maxWidth: .infinity).frame(height: 160).background(Color.yellow).cornerRadius(20)
                }
            }
            Spacer()
        }.padding(.horizontal)
    }
}

// MARK: - Step 4: Vibe
struct StickyVibeView: View {
    let onFinish: () -> Void
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Vibe Check").font(.largeTitle).fontWeight(.bold).foregroundColor(.white)
            HStack(spacing: 16) {
                // ✅ UPDATED: .none -> .standard
                Button(action: { withAnimation { themeManager.selectedGameMode = .standard } }) {
                    VStack {
                        Image(systemName: "book.closed.fill").font(.system(size: 40))
                        Text("Focus").font(.headline).padding(.top, 8)
                    }
                    // ✅ UPDATED: .none -> .standard
                    .foregroundColor(themeManager.selectedGameMode == .standard ? .black : .white)
                    .frame(maxWidth: .infinity).frame(height: 200)
                    // ✅ UPDATED: .none -> .standard
                    .background(themeManager.selectedGameMode == .standard ? Color.white : Color(white: 0.15))
                    .cornerRadius(20)
                }
                
                Button(action: { withAnimation { themeManager.selectedGameMode = .arcade } }) {
                    VStack {
                        Image(systemName: "gamecontroller.fill").font(.system(size: 40))
                        Text("Arcade").font(.headline).padding(.top, 8)
                    }
                    .foregroundColor(themeManager.selectedGameMode == .arcade ? .black : .white)
                    .frame(maxWidth: .infinity).frame(height: 200)
                    .background(themeManager.selectedGameMode == .arcade ? Color.cyan : Color(white: 0.15))
                    .cornerRadius(20)
                }
            }
            Spacer()
            Button(action: onFinish) {
                Text("Start Semester").font(.title3).fontWeight(.bold).foregroundColor(.white).frame(maxWidth: .infinity).padding().background(Color.blue).cornerRadius(16)
            }.padding(.bottom, 50)
        }.padding(.horizontal)
    }
}
