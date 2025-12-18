import SwiftUI
import SwiftData

@main
struct ClassllyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // ✅ Detect App Lifecycle
    @Environment(\.scenePhase) var scenePhase
    
    // Shared Managers
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var themeManager = AppTheme.shared
    @StateObject private var calendarManager = AcademicCalendarManager.shared
    @StateObject private var studyTimerManager = StudyTimerManager.shared
    
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isAuthenticated {
                    MainTabView()
                        .environmentObject(themeManager)
                        .environmentObject(authManager)
                        .environmentObject(calendarManager)
                        .environmentObject(studyTimerManager)
                } else {
                    SignInView()
                        .environmentObject(authManager)
                        .environmentObject(calendarManager)
                        .environmentObject(themeManager)
                }
            }
            .preferredColorScheme(darkModeEnabled ? .dark : nil)
            .tint(themeManager.selectedTheme.primaryColor)
            .modelContainer(for: [
                Subject.self,
                StudyTask.self,
                GradeEntry.self,
                AttendanceEntry.self,
                StudyCalendarEvent.self,
                StudentProfile.self,
                ClassEvent.self
            ])
            // ✅ Handle Background Timer Logic
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if newPhase == .background {
                    studyTimerManager.appDidEnterBackground()
                } else if newPhase == .active {
                    studyTimerManager.appWillEnterForeground()
                }
            }
        }
    }
}
