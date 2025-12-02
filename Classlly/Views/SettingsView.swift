//
//  SettingsView.swift
//  Classlly
//
//  Created by Robu Darius on 05.11.2025.
//


import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @AppStorage("autoSyncEnabled") private var autoSyncEnabled = true
    
    public init() {}
    
    var body: some View {
        Form {
            Section(header: Text("Appearance")) {
                Toggle("Dark Mode", isOn: $darkModeEnabled)
            }
            .listRowBackground(Color.themeSurface)
            
            Section(header: Text("Notifications")) {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
                NavigationLink(destination: NotificationSettingsView()) {
                    Text("Manage Notifications")
                }
            }
            .listRowBackground(Color.themeSurface)

            Section(header: Text("Data")) {
                Toggle("Auto Sync", isOn: $autoSyncEnabled)
            }
            .listRowBackground(Color.themeSurface)
        }
        .scrollContentBackground(.hidden)
        .background(Color.themeBackground)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
