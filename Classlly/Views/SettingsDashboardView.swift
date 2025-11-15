//
//  SettingsDashboardView.swift
//  Classlly
//
//  Created by Robu Darius on 14.11.2025.
//


// File: Classlly/Views/SettingsDashboardView.swift
// Note: This is the root view for the "More" tab.
// It links to Profile, Academic Calendar, and Settings.

import SwiftUI

struct SettingsDashboardView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var authManager: AuthenticationManager
    
    public init() {}
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - Profile Section
                if let user = authManager.currentUser {
                    NavigationLink(destination: ProfileView()) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [.themePrimary, .themeSecondary]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 60, height: 60)
                                
                                Text(getInitials(from: user.fullName))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.fullName)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Text("View Profile & Stats")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(Color.themeSurface)
                }
                
                // MARK: - Main Links
                Section {
                    NavigationLink(destination: AcademicCalendarView()) {
                        Label("Academic Calendar", systemImage: "calendar.circle.fill")
                    }
                    
                    NavigationLink(destination: SettingsView()) {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                }
                .listRowBackground(Color.themeSurface)
                
                // MARK: - Legal Links
                Section {
                    NavigationLink(destination: PrivacyPolicyView()) {
                        Label("Terms & Privacy Policy", systemImage: "lock.shield.fill")
                    }
                }
                .listRowBackground(Color.themeSurface)

            }
            .listStyle(InsetGroupedListStyle())
            .scrollContentBackground(.hidden)
            .navigationTitle("More")
            // --- THIS IS THE FIX ---
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func getInitials(from name: String) -> String {
        let names = name.split(separator: " ")
        let initials = names.prefix(2).map { String($0.first ?? Character("")) }
        return initials.joined()
    }
}