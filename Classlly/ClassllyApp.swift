// File: Classlly/ClassllyApp.swift
// Note: This is the FINAL corrected file. It now uses compiler flags
// to create a local-only container for the simulator (to prevent
// the crash) and the iCloud-enabled container for physical devices.

import SwiftUI
import UIKit
import SwiftData

@main
struct ClassllyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var calendarManager = AcademicCalendarManager()
    @StateObject private var themeManager = AppTheme()

    // --- THIS IS THE FIX ---
    // This container is now set up conditionally.
    var modelContainer: ModelContainer = {
        let schema = Schema([
            Subject.self,
            StudyTask.self,
            GradeEntry.self,
            AttendanceEntry.self,
            StudyCalendarEvent.self
        ])

        // 1. Define the iCloud configuration
        // Use the supported CloudKit parameter for your SDK.
        let iCloudConfiguration = ModelConfiguration(
            "ClassllySchemaV1",
            schema: schema,
            cloudKitDatabase: .private("iCloud.com.robu.darius.classlly")
        )
        
        // 2. Define a local-only configuration for the simulator
        let localConfiguration = ModelConfiguration(
            "ClassllySchemaV1",
            schema: schema
        )

        do {
            // 3. Check if we are running on the simulator
            #if targetEnvironment(simulator)
                // On the simulator, use the LOCAL database
                return try ModelContainer(for: schema, configurations: [localConfiguration])
            #else
                // On a real device, use the ICLOUD database
                return try ModelContainer(for: schema, configurations: [iCloudConfiguration])
            #endif
            
        } catch {
            // This will now report a *real* error if one happens
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    // --- END OF FIX ---
    
    init() {
        // (UI Appearance code is unchanged)
        let dynamicListBackground = UIColor.systemGroupedBackground
        let dynamicCellBackground = UIColor.secondarySystemGroupedBackground

        UITableView.appearance().backgroundColor = dynamicListBackground
        UITableViewCell.appearance().backgroundColor = dynamicCellBackground
        
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        
        navBarAppearance.backgroundColor = dynamicListBackground
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(calendarManager)
                .environmentObject(themeManager)
        }
        .modelContainer(modelContainer)
    }
}
