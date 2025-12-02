import SwiftUI
import Combine
import SwiftData

// MARK: - MAIN SWITCHER
struct CalendarView: View {
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        Group {
            switch themeManager.selectedGameMode {
            case .arcade:
                ArcadeAcademicCalendarView()
            case .retro:
                RetroAcademicCalendarView()
            case .rainbow:
                RainbowAcademicCalendarView()
            case .none:
                StandardAcademicCalendarView()
            }
        }
    }
}

// MARK: - 👔 STANDARD CALENDAR
struct StandardAcademicCalendarView: View {
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingCalendarManagement = false
    @State private var showingEditCalendar = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    calendarHeader
                    currentWeekCard
                    SemesterView(title: "Semester 1", semester: .semester1, calendarManager: calendarManager)
                    SemesterView(title: "Semester 2", semester: .semester2, calendarManager: calendarManager)
                }.padding()
            }
            .background(Color.themeBackground)
            .navigationTitle("Academic Calendar").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingCalendarManagement = true }) { Label("Manage Calendars", systemImage: "folder") }
                        Button(action: { showingEditCalendar = true }) { Label("Edit Current Calendar", systemImage: "pencil") }
                        if calendarManager.currentAcademicYear != nil { Button(action: { createNewCalendar() }) { Label("Create New Calendar", systemImage: "plus") } }
                    } label: { Image(systemName: "ellipsis.circle").font(.system(size: 20)) }
                }
            }
            .sheet(isPresented: $showingCalendarManagement) { CalendarManagementView(calendarManager: calendarManager) }
            .sheet(isPresented: $showingEditCalendar) { if let calendar = calendarManager.currentAcademicYear { EditAcademicCalendarView(calendar: calendar, calendarManager: calendarManager) } }
        }
    }
    
    private func createNewCalendar() {
        let newCalendar = calendarManager.createNewCalendar(year: "\(Calendar.current.component(.year, from: Date()))-\(Calendar.current.component(.year, from: Date()) + 1)", universityName: "My University", customName: "Custom Calendar")
        calendarManager.addCustomCalendar(newCalendar); calendarManager.setCurrentCalendar(newCalendar); showingEditCalendar = true
    }
    
    private var calendarHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let calendar = calendarManager.currentAcademicYear {
                    Text(calendar.customName ?? calendar.academicYear).font(.title2).fontWeight(.bold).foregroundColor(.themeTextPrimary)
                    if let university = calendar.universityName { Text(university).font(.subheadline).foregroundColor(.themeTextSecondary) }
                    Text(calendar.academicYear).font(.caption).foregroundColor(.themeTextSecondary)
                } else { Text("No Calendar Selected").font(.headline).foregroundColor(.themeTextSecondary) }
            }
            Spacer()
            Button("Switch") { showingCalendarManagement = true }.font(.subheadline).foregroundColor(.themePrimary)
        }.padding().background(Color.themeSurface).cornerRadius(12)
    }
    
    private var currentWeekCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Academic Week").font(.headline).foregroundColor(.themeTextSecondary)
                    if let currentWeek = calendarManager.currentTeachingWeek { Text("Week \(currentWeek)").font(.system(size: 32, weight: .bold)).foregroundColor(.themePrimary) }
                    else { Text("Break Period").font(.system(size: 24, weight: .semibold)).foregroundColor(.themeWarning) }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(calendarManager.currentAcademicYear?.academicYear ?? "").font(.subheadline).foregroundColor(.themeTextSecondary)
                    Text(calendarManager.currentSemester.displayName).font(.headline).foregroundColor(.themeTextPrimary)
                }
            }
            if let currentEvent = calendarManager.getCurrentEvent(for: Date()) {
                HStack {
                    Image(systemName: currentEvent.type.iconName).foregroundColor(currentEvent.type.color)
                    Text(currentEvent.customName ?? currentEvent.type.displayName).font(.subheadline).foregroundColor(.themeTextSecondary)
                    Spacer()
                    Text("\(formatDate(currentEvent.start)) - \(formatDate(currentEvent.end))").font(.caption).foregroundColor(.themeTextSecondary)
                }
            }
        }.padding().background(Color.themeSurface).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.separator), lineWidth: 1)).padding(.horizontal)
    }
}

// MARK: - 🕹️ ARCADE CALENDAR
struct ArcadeAcademicCalendarView: View {
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    @State private var showingCalendarManagement = false; @State private var showingEditCalendar = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        ZStack {
                            LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing).mask(RoundedRectangle(cornerRadius: 20)).opacity(0.2)
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("ACTIVE TIMELINE").font(.caption).fontWeight(.black).foregroundColor(.cyan)
                                    if let calendar = calendarManager.currentAcademicYear {
                                        Text(calendar.customName?.uppercased() ?? calendar.academicYear).font(.system(.title3, design: .rounded)).fontWeight(.black).foregroundColor(.white)
                                        Text(calendar.universityName?.uppercased() ?? "").font(.caption).fontWeight(.bold).foregroundColor(.white.opacity(0.7))
                                    } else { Text("NO DATA").font(.headline).foregroundColor(.gray) }
                                }
                                Spacer()
                                Button(action: { showingCalendarManagement = true }) { Text("SWITCH").font(.system(size: 10, weight: .black)).padding(8).background(Color.cyan).foregroundColor(.black).cornerRadius(8) }
                            }.padding()
                        }.overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.cyan.opacity(0.5), lineWidth: 1)).padding(.horizontal)
                        
                        VStack(spacing: 10) {
                            Text("CURRENT STATUS").font(.system(size: 10, weight: .black)).foregroundColor(.gray)
                            HStack {
                                if let week = calendarManager.currentTeachingWeek {
                                    Text("WEEK").font(.system(size: 14, weight: .bold)).foregroundColor(.gray); Text("\(week)").font(.system(size: 40, weight: .black)).foregroundColor(.yellow).shadow(color: .yellow, radius: 10)
                                } else { Text("BREAK MODE").font(.system(.title, design: .rounded)).fontWeight(.black).foregroundColor(.green).shadow(color: .green, radius: 10) }
                            }
                            Text(calendarManager.currentSemester.displayName.uppercased()).font(.caption).fontWeight(.bold).foregroundColor(.white).padding(4).background(Color.white.opacity(0.1)).cornerRadius(4)
                        }.frame(maxWidth: .infinity).padding().background(Color(white: 0.05)).cornerRadius(20).padding(.horizontal)
                        
                        HStack {
                            ArcadeActionButton(icon: "pencil", label: "EDIT CONFIG", color: .orange) { showingEditCalendar = true }
                            ArcadeActionButton(icon: "plus", label: "NEW TIMELINE", color: .green) { createNewCalendar() }
                        }.padding(.horizontal)
                        
                        VStack(spacing: 24) {
                            ArcadeSection(title: "PHASE 1 (SEM 1)", color: .purple) { ArcadeSemesterList(events: calendarManager.getSemesterEvents(.semester1), calendarManager: calendarManager) }
                            ArcadeSection(title: "PHASE 2 (SEM 2)", color: .pink) { ArcadeSemesterList(events: calendarManager.getSemesterEvents(.semester2), calendarManager: calendarManager) }
                        }.padding(.horizontal)
                    }.padding(.top)
                }
            }
            .navigationTitle("Timeline").navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingCalendarManagement) { CalendarManagementView(calendarManager: calendarManager) }
            .sheet(isPresented: $showingEditCalendar) { if let calendar = calendarManager.currentAcademicYear { EditAcademicCalendarView(calendar: calendar, calendarManager: calendarManager) } }
        }.preferredColorScheme(.dark)
    }
    private func createNewCalendar() {
        let newCalendar = calendarManager.createNewCalendar(year: "2025-2026", universityName: "My University", customName: "Custom Calendar")
        calendarManager.addCustomCalendar(newCalendar); calendarManager.setCurrentCalendar(newCalendar); showingEditCalendar = true
    }
}

struct ArcadeSemesterList: View {
    let events: [AcademicEventData]; let calendarManager: AcademicCalendarManager
    var body: some View {
        VStack(spacing: 8) {
            ForEach(events) { event in
                HStack {
                    Image(systemName: event.type.iconName).foregroundColor(event.type.color)
                    VStack(alignment: .leading) {
                        Text(event.customName ?? event.type.displayName).font(.system(size: 12, weight: .bold, design: .rounded)).foregroundColor(.white)
                        Text("\(formatDate(event.start)) - \(formatDate(event.end))").font(.system(size: 10)).foregroundColor(.gray)
                    }
                    Spacer()
                    if calendarManager.getCurrentEvent(for: Date())?.id == event.id { Text("ACTIVE").font(.system(size: 8, weight: .black)).foregroundColor(.black).padding(4).background(Color.green).cornerRadius(4) }
                }.padding(8).background(Color.black.opacity(0.5)).cornerRadius(8)
            }
        }
    }
}

// MARK: - 👾 RETRO CALENDAR
struct RetroAcademicCalendarView: View {
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    @State private var showingCalendarManagement = false; @State private var showingEditCalendar = false
    private var retroFont: Font.Design { .monospaced }
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.05).ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("> SYSTEM_CALENDAR").font(.system(.headline, design: retroFont)).foregroundColor(.green)
                            if let calendar = calendarManager.currentAcademicYear {
                                Text("LOADED: \(calendar.academicYear)").font(.system(.caption, design: retroFont)).foregroundColor(.gray)
                                Text("ORG: \(calendar.universityName ?? "UNKNOWN")").font(.system(.caption, design: retroFont)).foregroundColor(.gray)
                            } else { Text("ERROR: NO_CALENDAR_MOUNTED").font(.system(.caption, design: retroFont)).foregroundColor(.red) }
                            Rectangle().frame(height: 1).foregroundColor(.green)
                        }
                        HStack {
                            RetroButton(label: "[ LOAD_DB ]") { showingCalendarManagement = true }
                            RetroButton(label: "[ MODIFY ]", color: .yellow) { showingEditCalendar = true }
                            RetroButton(label: "[ NEW ]", color: .cyan) { createNewCalendar() }
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CURRENT_STATUS:").font(.system(.caption, design: retroFont)).foregroundColor(.gray)
                            HStack { Text("WEEK_INDEX:"); Spacer(); if let week = calendarManager.currentTeachingWeek { Text("\(week)").fontWeight(.bold).foregroundColor(.green) } else { Text("NULL (BREAK)").foregroundColor(.yellow) } }.font(.system(.body, design: retroFont)).foregroundColor(.green)
                            HStack { Text("SEMESTER:"); Spacer(); Text(calendarManager.currentSemester == .semester1 ? "1" : "2").foregroundColor(.green) }.font(.system(.body, design: retroFont)).foregroundColor(.green)
                        }.padding().border(Color.green.opacity(0.5), width: 1)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SEQUENCE_A:").font(.caption).fontDesign(.monospaced).foregroundColor(.gray)
                            ForEach(calendarManager.getSemesterEvents(.semester1)) { event in Text("[ \(event.weeks)w ] \(event.customName?.uppercased() ?? "EVENT")").font(.system(.caption, design: .monospaced)).foregroundColor(.green) }
                        }.padding().border(Color.green.opacity(0.5), width: 1)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SEQUENCE_B:").font(.caption).fontDesign(.monospaced).foregroundColor(.gray)
                            ForEach(calendarManager.getSemesterEvents(.semester2)) { event in Text("[ \(event.weeks)w ] \(event.customName?.uppercased() ?? "EVENT")").font(.system(.caption, design: .monospaced)).foregroundColor(.green) }
                        }.padding().border(Color.green.opacity(0.5), width: 1)
                    }.padding()
                }
            }
            .navigationTitle("CAL_DB").navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingCalendarManagement) { CalendarManagementView(calendarManager: calendarManager) }
            .sheet(isPresented: $showingEditCalendar) { if let calendar = calendarManager.currentAcademicYear { EditAcademicCalendarView(calendar: calendar, calendarManager: calendarManager) } }
        }.preferredColorScheme(.dark)
    }
    private func createNewCalendar() {
        let newCalendar = calendarManager.createNewCalendar(year: "2025-2026", universityName: "My University", customName: "Custom Calendar")
        calendarManager.addCustomCalendar(newCalendar); calendarManager.setCurrentCalendar(newCalendar); showingEditCalendar = true
    }
}

// MARK: - 🌈 RAINBOW CALENDAR
struct RainbowAcademicCalendarView: View {
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    @EnvironmentObject var themeManager: AppTheme
    
    // Simply wrap standard view for full functionality with theme colors applied via StandardAcademicCalendarView which respects AppTheme
    // but force dark mode to match the Rainbow aesthetic
    var body: some View {
        StandardAcademicCalendarView()
            .preferredColorScheme(.dark)
    }
}

// MARK: - SUPPORTING VIEWS
private func formatDate(_ date: Date) -> String { let f = DateFormatter(); f.dateFormat = "MMM d"; return f.string(from: date) }
private func formatDate(_ dateString: String) -> String { let i = DateFormatter(); i.dateFormat = "yyyy-MM-dd"; guard let d = i.date(from: dateString) else { return dateString }; let o = DateFormatter(); o.dateFormat = "MMM d"; return o.string(from: d) }
