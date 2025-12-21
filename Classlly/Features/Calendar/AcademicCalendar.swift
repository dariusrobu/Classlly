import SwiftUI

struct AcademicCalendarView: View {
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        Group {
            switch themeManager.selectedGameMode {
            case .rainbow:
                AnyView(RainbowSemesterListView())
            case .arcade:
                AnyView(ArcadeSemesterListView())
            case .standard:
                AnyView(StandardSemesterListView())
            }
        }
    }
}

// MARK: - 🌈 RAINBOW VIEW
struct RainbowSemesterListView: View {
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        let accent = themeManager.selectedTheme.primaryColor
        
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    RainbowHeader(title: "Schedule", accentColor: accent, showBackButton: false)
                    
                    if let currentYear = calendarManager.currentAcademicYear {
                        VStack(spacing: 20) {
                            RainbowSemesterCard(
                                semesterData: currentYear.semester1,
                                title: "SEMESTER 1",
                                isCurrent: calendarManager.currentSemester == .semester1
                            )
                            
                            RainbowSemesterCard(
                                semesterData: currentYear.semester2,
                                title: "SEMESTER 2",
                                isCurrent: calendarManager.currentSemester == .semester2
                            )
                        }
                        .padding(.horizontal)
                    } else {
                        ContentUnavailableView("No Calendar Set", systemImage: "calendar.badge.exclamationmark")
                    }
                }
            }
        }
    }
}

struct RainbowSemesterCard: View {
    let semesterData: SemesterData
    let title: String
    let isCurrent: Bool
    
    var startDate: String { semesterData.events.first?.start ?? "N/A" }
    var endDate: String { semesterData.events.last?.end ?? "N/A" }
    
    var body: some View {
        RainbowContainer {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(title).font(.headline).fontWeight(.black).foregroundColor(.white)
                    Spacer()
                    if isCurrent {
                        Text("CURRENT").font(.caption).fontWeight(.bold).padding(6).background(Color.green).foregroundColor(.black).cornerRadius(8)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Timeline").font(.caption).foregroundColor(.gray)
                    Text("\(formatDate(startDate)) - \(formatDate(endDate))").font(.headline).fontWeight(.bold).foregroundColor(.white)
                }
                
                if !semesterData.events.isEmpty {
                    Divider().background(Color.gray)
                    ForEach(semesterData.events) { event in
                        HStack {
                            Circle().fill(event.type.color).frame(width: 8, height: 8)
                            Text(event.customName ?? event.type.displayName).font(.caption).foregroundColor(.white)
                            Spacer()
                            Text("\(event.weeks) wks").font(.caption).foregroundColor(.gray)
                        }
                    }
                }
            }
        }
    }
    
    func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateString) {
            // ✅ FIXED: Changed .medium to .abbreviated
            return date.formatted(date: .abbreviated, time: .omitted)
        }
        return dateString
    }
}

// MARK: - 👔 STANDARD VIEW
struct StandardSemesterListView: View {
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    
    var body: some View {
        NavigationStack {
            List {
                if let currentYear = calendarManager.currentAcademicYear {
                    Section(header: Text("Semester 1")) {
                        LabeledContent("Start", value: formatDate(currentYear.semester1.events.first?.start))
                        LabeledContent("End", value: formatDate(currentYear.semester1.events.last?.end))
                        eventsList(events: currentYear.semester1.events)
                    }
                    Section(header: Text("Semester 2")) {
                        LabeledContent("Start", value: formatDate(currentYear.semester2.events.first?.start))
                        LabeledContent("End", value: formatDate(currentYear.semester2.events.last?.end))
                        eventsList(events: currentYear.semester2.events)
                    }
                } else {
                    ContentUnavailableView("No Calendar Configured", systemImage: "calendar")
                }
            }
            .navigationTitle("Academic Year")
        }
    }
    
    @ViewBuilder
    func eventsList(events: [AcademicEventData]) -> some View {
        ForEach(events) { event in
            HStack {
                Circle().fill(event.type.color).frame(width: 8, height: 8)
                Text(event.customName ?? event.type.displayName)
                Spacer()
                Text("\(event.weeks) weeks").foregroundColor(.secondary)
            }
        }
    }
    
    func formatDate(_ dateString: String?) -> String {
        guard let dateString = dateString else { return "-" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateString) {
            // ✅ FIXED: Changed .medium to .abbreviated
            return date.formatted(date: .abbreviated, time: .omitted)
        }
        return dateString
    }
}

// MARK: - 🕹️ ARCADE VIEW
struct ArcadeSemesterListView: View {
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    HStack {
                        Text("TIMELINE").font(.system(size: 30, weight: .black, design: .rounded)).foregroundColor(.cyan)
                        Spacer()
                    }.padding()
                    
                    if let currentYear = calendarManager.currentAcademicYear {
                        ArcadeSemesterBlock(title: "SEMESTER 1", events: currentYear.semester1.events)
                        ArcadeSemesterBlock(title: "SEMESTER 2", events: currentYear.semester2.events)
                    }
                }
            }
        }
    }
}

struct ArcadeSemesterBlock: View {
    let title: String
    let events: [AcademicEventData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline).fontWeight(.black).foregroundColor(.purple)
            
            ForEach(events) { event in
                HStack {
                    Image(systemName: "circle.fill").font(.caption2).foregroundColor(.cyan)
                    Text(event.customName ?? event.type.displayName).font(.custom("Courier", size: 14)).foregroundColor(.white)
                    Spacer()
                    Text("[\(event.weeks) WEEKS]").font(.caption).foregroundColor(.gray)
                }
                .padding(10)
                .background(Color(white: 0.1))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cyan.opacity(0.3), lineWidth: 1))
            }
        }
        .padding()
        .background(Color.black)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.purple, lineWidth: 2))
        .padding(.horizontal)
    }
}
