import SwiftUI

struct AcademicCalendarSettingsView: View {
    @EnvironmentObject var themeManager: AppTheme
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    
    var body: some View {
        Group {
            switch themeManager.selectedGameMode {
            case .rainbow:
                RainbowCalendarSettingsView()
            case .arcade:
                // Simple stub for arcade mode
                ZStack {
                    Color.black.ignoresSafeArea()
                    Text("Arcade Calendar Config").foregroundColor(.cyan)
                }
            case .none:
                StandardCalendarSettingsView()
            }
        }
    }
}

// MARK: - 🌈 RAINBOW CALENDAR SETTINGS
struct RainbowCalendarSettingsView: View {
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    @EnvironmentObject var themeManager: AppTheme
    @Environment(\.dismiss) private var dismiss
    
    // Local State for Editing
    @State private var startDate = Date()
    @State private var endDate = Date()
    
    var body: some View {
        let accent = themeManager.selectedTheme.primaryColor
        
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "chevron.left").foregroundColor(.white)
                            }
                            Text("ACADEMIC CALENDAR")
                                .font(.headline).fontWeight(.black).foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                            Spacer().frame(width: 20)
                        }
                        .padding()
                        
                        // Semester Config
                        VStack(alignment: .leading, spacing: 16) {
                            RainbowSectionHeader(title: "CURRENT SEMESTER", color: accent)
                            
                            VStack(spacing: 12) {
                                DateRow(title: "Start Date", date: $startDate, color: accent)
                                Divider().background(Color(white: 0.2))
                                DateRow(title: "End Date", date: $endDate, color: accent)
                            }
                            .padding()
                            .background(Color(white: 0.1))
                            .cornerRadius(16)
                            
                            RainbowSectionHeader(title: "BREAKS", color: RainbowColors.orange)
                            
                            Button(action: {}) {
                                HStack {
                                    Image(systemName: "plus.circle.fill").foregroundColor(RainbowColors.orange)
                                    Text("Add Holiday / Break").fontWeight(.bold).foregroundColor(.white)
                                    Spacer()
                                }
                                .padding()
                                .background(Color(white: 0.1))
                                .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Save Button
                        Button(action: saveDates) {
                            Text("Update Calendar")
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(accent)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear(perform: loadDates)
        }
    }
    
    // ✅ Load from Manager
    private func loadDates() {
        startDate = calendarManager.startDate
        endDate = calendarManager.endDate
    }
    
    // ✅ Save back to Manager
    private func saveDates() {
        calendarManager.startDate = startDate
        calendarManager.endDate = endDate
        dismiss()
    }
    
    struct DateRow: View {
        let title: String
        @Binding var date: Date
        let color: Color
        
        var body: some View {
            HStack {
                Text(title).fontWeight(.bold).foregroundColor(.gray)
                Spacer()
                DatePicker("", selection: $date, displayedComponents: .date)
                    .labelsHidden()
                    .colorScheme(.dark)
            }
        }
    }
}

// MARK: - 🏠 STANDARD CALENDAR SETTINGS
struct StandardCalendarSettingsView: View {
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    
    // Use binding directly to manager properties for standard view
    var body: some View {
        Form {
            Section("Current Semester") {
                DatePicker("Start Date", selection: $calendarManager.startDate, displayedComponents: .date)
                DatePicker("End Date", selection: $calendarManager.endDate, displayedComponents: .date)
            }
            
            Section("Calculated Info") {
                HStack {
                    Text("Total Weeks")
                    Spacer()
                    // Safe unwrap or calculation
                    Text("\(calendarManager.currentTeachingWeek ?? 0)")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Academic Calendar")
    }
}
