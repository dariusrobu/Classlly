import SwiftUI
import SwiftData

struct SubjectsView: View {
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        Group {
            switch themeManager.selectedGameMode {
            case .rainbow:
                RainbowSubjectsView()
            case .arcade:
                ArcadeSubjectsView()
            case .retro:
                RetroSubjectsView()
            case .none:
                StandardSubjectsView()
            }
        }
    }
}

struct StandardSubjectsView: View {
    @Query(sort: \Subject.title) var subjects: [Subject]
    @State private var showingAddSubject = false
    var body: some View {
        NavigationStack {
            ScrollView { LazyVStack(spacing: 16) { ForEach(subjects) { subject in NavigationLink(destination: SubjectDetailView(subject: subject)) { SubjectCard(subject: subject) }.buttonStyle(PlainButtonStyle()) } }.padding() }
            .navigationTitle("Subjects").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button(action: { showingAddSubject = true }) { Image(systemName: "plus.circle.fill").font(.system(size: 20, weight: .medium)).foregroundColor(.themePrimary) } } }
            .sheet(isPresented: $showingAddSubject) { AddSubjectView() }
        }
    }
}

struct ArcadeSubjectsView: View {
    @Query(sort: \Subject.title) var subjects: [Subject]; @State private var showingAddSubject = false
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack { VStack(alignment: .leading) { Text("TOTAL SKILLS").font(.caption).fontWeight(.black).foregroundColor(.gray); Text("\(subjects.count)").font(.system(.title, design: .rounded)).fontWeight(.black).foregroundColor(.white) }; Spacer(); VStack(alignment: .trailing) { Text("MASTERY").font(.caption).fontWeight(.black).foregroundColor(.gray); Text(calculateMastery()).font(.system(.title, design: .rounded)).fontWeight(.black).foregroundColor(.cyan) } }.padding().background(Color(white: 0.1)).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.cyan.opacity(0.3), lineWidth: 1))
                        LazyVGrid(columns: columns, spacing: 16) { ForEach(subjects) { subject in NavigationLink(destination: SubjectDetailView(subject: subject)) { ArcadeSubjectCard(subject: subject) } } }
                    }.padding()
                }
            }
            .navigationTitle("Skill Trees").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button(action: { showingAddSubject = true }) { Image(systemName: "plus.circle.fill").foregroundColor(.cyan) } } }
            .sheet(isPresented: $showingAddSubject) { AddSubjectView() }
        }.preferredColorScheme(.dark)
    }
    private func calculateMastery() -> String { guard !subjects.isEmpty else { return "0%" }; let total = subjects.reduce(0.0) { $0 + $1.attendanceRate }; let avg = total / Double(subjects.count); return "\(Int(avg * 100))%" }
}

struct ArcadeSubjectCard: View {
    let subject: Subject
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack { ZStack { Circle().fill(Color.purple.opacity(0.2)).frame(width: 40, height: 40); Image(systemName: "bolt.fill").foregroundColor(.purple) }; Spacer(); Text("LVL \(Int(subject.attendanceRate * 10))").font(.system(.caption, design: .rounded)).fontWeight(.black).foregroundColor(.white).padding(4).background(Color.purple.opacity(0.2)).cornerRadius(4) }
            Text(subject.title).font(.system(.headline, design: .rounded)).fontWeight(.bold).foregroundColor(.white).lineLimit(2).multilineTextAlignment(.leading)
            Spacer()
            HStack { if let grade = subject.currentGrade { Text(String(format: "%.1f", grade)).font(.caption).fontWeight(.bold).foregroundColor(.yellow) } else { Text("-.-").font(.caption).foregroundColor(.gray) }; Spacer(); Text("\(Int(subject.attendanceRate * 100))%").font(.caption).fontWeight(.bold).foregroundColor(.green) }
            GeometryReader { geo in ZStack(alignment: .leading) { Capsule().fill(Color.white.opacity(0.1)); Capsule().fill(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)).frame(width: geo.size.width * subject.attendanceRate) } }.frame(height: 6)
        }.padding().frame(height: 160).background(Color(white: 0.1)).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.05), lineWidth: 1)).shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 5)
    }
}

struct RetroSubjectsView: View {
    @Query(sort: \Subject.title) var subjects: [Subject]; @State private var showingAddSubject = false
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.05).ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        VStack(alignment: .leading, spacing: 4) { Text("> ACCESSING_DATABASE...").font(.system(.caption, design: .monospaced)).foregroundColor(.green); Text("ROOT_DIR/SUBJECTS").font(.system(.title3, design: .monospaced)).fontWeight(.bold).foregroundColor(.green); Rectangle().frame(height: 1).foregroundColor(.green) }.padding()
                        LazyVStack(spacing: 0) { ForEach(subjects) { subject in NavigationLink(destination: SubjectDetailView(subject: subject)) { RetroSubjectRow(subject: subject) } } }.padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Database").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button(action: { showingAddSubject = true }) { Text("[ NEW_ENTRY ]").font(.system(.caption, design: .monospaced)).foregroundColor(.green) } } }
            .sheet(isPresented: $showingAddSubject) { AddSubjectView() }
        }.preferredColorScheme(.dark)
    }
}

struct RetroSubjectRow: View {
    let subject: Subject
    var body: some View {
        HStack {
            Text(">").font(.system(.body, design: .monospaced)).foregroundColor(.green).padding(.trailing, 4)
            VStack(alignment: .leading, spacing: 4) {
                Text(subject.title.uppercased()).font(.system(.body, design: .monospaced)).foregroundColor(.white)
                HStack { Text("ID: \(subject.courseTeacher.prefix(3).uppercased())"); Text("|"); if let grade = subject.currentGrade { Text("VAL: \(String(format: "%.1f", grade))") } else { Text("VAL: NULL") } }.font(.system(size: 10, design: .monospaced)).foregroundColor(.gray)
            }
            Spacer(); Text("[ OPEN ]").font(.system(size: 10, design: .monospaced)).foregroundColor(.green)
        }.padding(.vertical, 16).overlay(Rectangle().frame(height: 1).foregroundColor(Color.green.opacity(0.3)), alignment: .bottom)
    }
}

struct RainbowSubjectsView: View {
    @Query(sort: \Subject.title) var subjects: [Subject]; @EnvironmentObject var themeManager: AppTheme; @State private var showingAddSubject = false
    var body: some View {
        let colors = RainbowThemeFactory.colors(for: themeManager.selectedTheme)
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(subjects) { subject in
                            NavigationLink(destination: SubjectDetailView(subject: subject)) {
                                HStack(spacing: 16) {
                                    ZStack { Circle().fill(colors.secondary.opacity(0.2)).frame(width: 50, height: 50); Image(systemName: "book.fill").foregroundColor(colors.secondary) }
                                    VStack(alignment: .leading, spacing: 4) { Text(subject.title).font(.headline).foregroundColor(.white); Text(subject.courseTeacher).font(.caption).foregroundColor(.gray) }
                                    Spacer(); Image(systemName: "chevron.right").foregroundColor(.gray)
                                }.modifier(RainbowCardModifier(color: colors.secondary))
                            }
                        }
                    }.padding()
                }
            }
            .navigationTitle("Subjects")
            .toolbar { Button(action: { showingAddSubject = true }) { Image(systemName: "plus.circle.fill").foregroundColor(colors.primary).font(.title2) } }
            .sheet(isPresented: $showingAddSubject) { AddSubjectView() }
        }.preferredColorScheme(.dark)
    }
}

// MARK: - SHARED COMPONENTS (Standard)
struct SubjectCard: View {
    let subject: Subject
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) { Text(subject.title).font(.title2).fontWeight(.bold).foregroundColor(.themeTextPrimary); Text(subject.courseTeacher).font(.subheadline).foregroundColor(.themeTextSecondary) }
                Spacer(); if let grade = subject.currentGrade { GradeBadge(grade: grade) }
            }
            VStack(alignment: .leading, spacing: 8) { InfoRow(icon: "clock", text: "\(subject.courseDaysString) \(subject.courseTimeString)"); InfoRow(icon: "mappin.circle", text: subject.courseClassroom) }
            HStack(spacing: 12) { StatPill(icon: "checkmark.circle", value: "\(subject.attendedClasses)", label: "Present"); StatPill(icon: "xmark.circle", value: "\(subject.totalClasses - subject.attendedClasses)", label: "Absent"); StatPill(icon: "star", value: "\(subject.gradeHistory?.count ?? 0)", label: "Grades") }
        }.padding().background(Color.themeSurface).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.adaptiveBorder.opacity(0.3), lineWidth: 1))
    }
}

struct StatPill: View {
    let icon: String; let value: String; let label: String
    var body: some View { VStack(spacing: 4) { HStack(spacing: 4) { Image(systemName: icon).font(.caption2).foregroundColor(.themeTextSecondary); Text(value).font(.caption).fontWeight(.semibold).foregroundColor(.themeTextPrimary) }; Text(label).font(.caption2).foregroundColor(.themeTextSecondary) }.frame(maxWidth: .infinity).padding(.vertical, 8).background(Color.adaptiveTertiaryBackground).cornerRadius(8) }
}

struct GradeBadge: View {
    let grade: Double; private var gradeColor: Color { switch grade { case 9...10: return .themeSuccess; case 7..<9: return .themePrimary; case 5..<7: return .themeWarning; default: return .themeError } }
    var body: some View { VStack(spacing: 2) { Text(String(format: "%.1f", grade)).font(.system(size: 16, weight: .bold)).foregroundColor(.white); Text("/10").font(.system(size: 10, weight: .medium)).foregroundColor(.white.opacity(0.9)) }.padding(.horizontal, 8).padding(.vertical, 4).background(gradeColor).cornerRadius(8) }
}

struct InfoRow: View {
    let icon: String; let text: String
    var body: some View { HStack(spacing: 8) { Image(systemName: icon).font(.caption).foregroundColor(.themeTextSecondary).frame(width: 16); Text(text).font(.subheadline).foregroundColor(.themeTextPrimary); Spacer() } }
}
