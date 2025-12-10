import SwiftUI
import SwiftData

struct SubjectsView: View {
    @EnvironmentObject var themeManager: AppTheme
    var embedInNavigationStack: Bool = true
    
    var body: some View {
        Group {
            switch themeManager.selectedGameMode {
            case .rainbow:
                RainbowSubjectsView(embedInNavigationStack: embedInNavigationStack)
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

// MARK: - 🌈 RAINBOW SUBJECTS
struct RainbowSubjectsView: View {
    @Query(sort: \Subject.title) var subjects: [Subject]
    @EnvironmentObject var themeManager: AppTheme
    @Environment(\.dismiss) private var dismiss
    
    // Scanner & Import State
    @State private var showingAddSubject = false
    @State private var showingScanner = false
    @State private var showingImagePicker = false
    @State private var showingScanReview = false
    @State private var isProcessingScan = false
    @State private var scannedCandidates: [ScannedClassCandidate] = []
    
    var embedInNavigationStack: Bool = true
    
    private let cardColors: [Color] = [
        RainbowColors.green, RainbowColors.blue, RainbowColors.orange, RainbowColors.purple,
        Color.pink, Color.teal, Color.indigo, Color.red, Color.yellow, Color.cyan,
        Color.mint, Color(red: 1.0, green: 0.4, blue: 0.4)
    ]
    
    var body: some View {
        let accentColor = themeManager.selectedTheme.primaryColor
        
        if embedInNavigationStack {
            NavigationStack { content(accentColor: accentColor) }
                .preferredColorScheme(.dark)
        } else {
            content(accentColor: accentColor)
                .preferredColorScheme(.dark)
        }
    }
    
    @ViewBuilder
    private func content(accentColor: Color) -> some View {
        VStack(spacing: 0) {
            RainbowHeader(
                title: "Subjects",
                accentColor: accentColor,
                showBackButton: !embedInNavigationStack,
                backAction: { dismiss() },
                trailingIcon: "plus",
                trailingAction: { showingAddSubject = true }
            )
            
            ZStack {
                Color.black.ignoresSafeArea()
                
                if subjects.isEmpty {
                    VStack(spacing: 24) {
                        VStack(spacing: 16) {
                            Image(systemName: "book.fill")
                                .font(.system(size: 60))
                                .foregroundColor(RainbowColors.darkCard.opacity(2))
                            Text("No Subjects Found")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        
                        HStack(spacing: 16) {
                            Button(action: { showingScanner = true }) {
                                ScanButtonContent(icon: "camera.fill", text: "Scan", color: accentColor)
                            }
                            Button(action: { showingImagePicker = true }) {
                                ScanButtonContent(icon: "photo.fill", text: "Import", color: RainbowColors.darkCard)
                            }
                        }
                    }
                } else {
                    ScrollView {
                        // Action Bar
                        HStack(spacing: 12) {
                            Button(action: { showingScanner = true }) {
                                Label("Scan Camera", systemImage: "camera.fill")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(accentColor)
                                    .cornerRadius(12)
                            }
                            
                            Button(action: { showingImagePicker = true }) {
                                Image(systemName: "photo.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(RainbowColors.darkCard)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                        
                        LazyVStack(spacing: 16) {
                            ForEach(Array(subjects.enumerated()), id: \.element.id) { index, subject in
                                let color = cardColors[index % cardColors.count]
                                NavigationLink(destination: SubjectDetailView(subject: subject)) {
                                    RainbowSubjectCard(subject: subject, color: color)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                        .padding(.bottom, 20)
                    }
                }
                
                if isProcessingScan {
                    Color.black.opacity(0.6).ignoresSafeArea()
                    ProgressView("Analyzing...").tint(accentColor).foregroundColor(.white)
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddSubject) { AddSubjectView() }
        .sheet(isPresented: $showingScanner) {
            DocumentScannerView(didFinishScanning: processScannedImage, didCancel: {}).ignoresSafeArea()
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(didFinishPicking: processScannedImage).ignoresSafeArea()
        }
        .sheet(isPresented: $showingScanReview) {
            ScheduleImportReviewView(candidates: scannedCandidates)
        }
    }
    
    private func processScannedImage(_ image: UIImage) {
        isProcessingScan = true
        Task {
            do {
                let candidates = try await ScheduleScannerService.shared.scanImage(image)
                await MainActor.run {
                    self.scannedCandidates = candidates
                    self.isProcessingScan = false
                    if !candidates.isEmpty { self.showingScanReview = true }
                }
            } catch {
                print("OCR Error: \(error)")
                await MainActor.run { self.isProcessingScan = false }
            }
        }
    }
}

// Helper for Rainbow Button
struct ScanButtonContent: View {
    let icon: String; let text: String; let color: Color
    var body: some View {
        HStack { Image(systemName: icon); Text(text) }
            .fontWeight(.bold).foregroundColor(.white)
            .padding().frame(minWidth: 120).background(color).cornerRadius(12)
    }
}

// MARK: - 👔 STANDARD SUBJECTS (Updated)
struct StandardSubjectsView: View {
    @Query(sort: \Subject.title) var subjects: [Subject]
    @State private var showingAddSubject = false
    
    @State private var showingScanner = false
    @State private var showingImagePicker = false
    @State private var showingScanReview = false
    @State private var isProcessingScan = false
    @State private var scannedCandidates: [ScannedClassCandidate] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Action Bar
                        HStack(spacing: 12) {
                            Button(action: { showingScanner = true }) {
                                Label("Scan Schedule", systemImage: "camera")
                                    .frame(maxWidth: .infinity)
                                    .padding().background(Color.themeSurface).cornerRadius(12)
                            }
                            Button(action: { showingImagePicker = true }) {
                                Label("Import", systemImage: "photo")
                                    .frame(maxWidth: .infinity)
                                    .padding().background(Color.themeSurface).cornerRadius(12)
                            }
                        }
                        .foregroundColor(.themePrimary)
                        .padding(.top, 8)
                        
                        ForEach(subjects) { subject in
                            NavigationLink(destination: SubjectDetailView(subject: subject)) {
                                SubjectCard(subject: subject)
                            }.buttonStyle(PlainButtonStyle())
                        }
                    }.padding()
                }
                if isProcessingScan { Color.black.opacity(0.4).ignoresSafeArea(); ProgressView() }
            }
            .navigationTitle("Subjects").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSubject = true }) { Image(systemName: "plus.circle.fill").font(.system(size: 20)).foregroundColor(.themePrimary) }
                }
            }
            .sheet(isPresented: $showingAddSubject) { AddSubjectView() }
            .sheet(isPresented: $showingScanner) { DocumentScannerView(didFinishScanning: processScannedImage, didCancel: {}).ignoresSafeArea() }
            .sheet(isPresented: $showingImagePicker) { ImagePicker(didFinishPicking: processScannedImage).ignoresSafeArea() }
            .sheet(isPresented: $showingScanReview) { ScheduleImportReviewView(candidates: scannedCandidates) }
        }
    }
    
    private func processScannedImage(_ image: UIImage) {
        isProcessingScan = true
        Task {
            do {
                let candidates = try await ScheduleScannerService.shared.scanImage(image)
                await MainActor.run { self.scannedCandidates = candidates; self.isProcessingScan = false; if !candidates.isEmpty { self.showingScanReview = true } }
            } catch { await MainActor.run { self.isProcessingScan = false } }
        }
    }
}

// MARK: - 🕹️ ARCADE SUBJECTS (Updated)
struct ArcadeSubjectsView: View {
    @Query(sort: \Subject.title) var subjects: [Subject]
    @State private var showingAddSubject = false
    @State private var showingScanner = false
    @State private var showingImagePicker = false
    @State private var showingScanReview = false
    @State private var isProcessingScan = false
    @State private var scannedCandidates: [ScannedClassCandidate] = []
    
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("TOTAL SKILLS").font(.caption).fontWeight(.black).foregroundColor(.gray)
                                Text("\(subjects.count)").font(.system(.title, design: .rounded)).fontWeight(.black).foregroundColor(.white)
                            }
                            Spacer()
                            // Split Action Button
                            HStack(spacing: 8) {
                                Button(action: { showingScanner = true }) {
                                    VStack { Image(systemName: "camera.fill"); Text("SCAN") }.font(.system(size: 8, weight: .black))
                                        .frame(width: 50, height: 50).background(Color.cyan.opacity(0.2)).foregroundColor(.cyan).cornerRadius(8)
                                }
                                Button(action: { showingImagePicker = true }) {
                                    VStack { Image(systemName: "photo.fill"); Text("LOAD") }.font(.system(size: 8, weight: .black))
                                        .frame(width: 50, height: 50).background(Color.purple.opacity(0.2)).foregroundColor(.purple).cornerRadius(8)
                                }
                            }
                        }
                        .padding().background(Color(white: 0.1)).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.cyan.opacity(0.3), lineWidth: 1))
                        
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(subjects) { subject in
                                NavigationLink(destination: SubjectDetailView(subject: subject)) { ArcadeSubjectCard(subject: subject) }
                            }
                        }
                    }.padding()
                }
                if isProcessingScan { Color.black.opacity(0.7).ignoresSafeArea(); ProgressView().tint(.cyan) }
            }
            .navigationTitle("Skill Trees").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { Button(action: { showingAddSubject = true }) { Image(systemName: "plus.circle.fill").foregroundColor(.cyan) } }
            }
            .sheet(isPresented: $showingAddSubject) { AddSubjectView() }
            .sheet(isPresented: $showingScanner) { DocumentScannerView(didFinishScanning: processScannedImage, didCancel: {}).ignoresSafeArea() }
            .sheet(isPresented: $showingImagePicker) { ImagePicker(didFinishPicking: processScannedImage).ignoresSafeArea() }
            .sheet(isPresented: $showingScanReview) { ScheduleImportReviewView(candidates: scannedCandidates) }
        }.preferredColorScheme(.dark)
    }
    
    private func processScannedImage(_ image: UIImage) {
        isProcessingScan = true
        Task {
            do {
                let candidates = try await ScheduleScannerService.shared.scanImage(image)
                await MainActor.run { self.scannedCandidates = candidates; self.isProcessingScan = false; if !candidates.isEmpty { self.showingScanReview = true } }
            } catch { await MainActor.run { self.isProcessingScan = false } }
        }
    }
}

// MARK: - 👾 RETRO SUBJECTS (Updated)
struct RetroSubjectsView: View {
    @Query(sort: \Subject.title) var subjects: [Subject]
    @State private var showingAddSubject = false
    @State private var showingScanner = false
    @State private var showingImagePicker = false
    @State private var showingScanReview = false
    @State private var isProcessingScan = false
    @State private var scannedCandidates: [ScannedClassCandidate] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.05).ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("> DATABASE_ACCESS").font(.caption).fontDesign(.monospaced).foregroundColor(.green)
                            HStack {
                                Text("ROOT/SUBJECTS").font(.system(.title3, design: .monospaced)).bold().foregroundColor(.green)
                                Spacer()
                                Button(action: { showingScanner = true }) { Text("[ SCAN ]").font(.caption).fontDesign(.monospaced).foregroundColor(.green).padding(4).border(Color.green, width: 1) }
                                Button(action: { showingImagePicker = true }) { Text("[ FILE ]").font(.caption).fontDesign(.monospaced).foregroundColor(.yellow).padding(4).border(Color.yellow, width: 1) }
                            }
                            Rectangle().frame(height: 1).foregroundColor(.green)
                        }.padding()
                        
                        LazyVStack(spacing: 0) {
                            ForEach(subjects) { subject in
                                NavigationLink(destination: SubjectDetailView(subject: subject)) { RetroSubjectRow(subject: subject) }
                            }
                        }.padding(.horizontal)
                    }
                }
                if isProcessingScan { Color.black.ignoresSafeArea(); Text("DECODING_IMAGE_DATA...").fontDesign(.monospaced).foregroundColor(.green).blinking() }
            }
            .navigationTitle("Database").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { Button(action: { showingAddSubject = true }) { Text("[ NEW ]").font(.caption).fontDesign(.monospaced).foregroundColor(.green) } }
            }
            .sheet(isPresented: $showingAddSubject) { AddSubjectView() }
            .sheet(isPresented: $showingScanner) { DocumentScannerView(didFinishScanning: processScannedImage, didCancel: {}).ignoresSafeArea() }
            .sheet(isPresented: $showingImagePicker) { ImagePicker(didFinishPicking: processScannedImage).ignoresSafeArea() }
            .sheet(isPresented: $showingScanReview) { ScheduleImportReviewView(candidates: scannedCandidates) }
        }.preferredColorScheme(.dark)
    }
    
    private func processScannedImage(_ image: UIImage) {
        isProcessingScan = true
        Task {
            do {
                let candidates = try await ScheduleScannerService.shared.scanImage(image)
                await MainActor.run { self.scannedCandidates = candidates; self.isProcessingScan = false; if !candidates.isEmpty { self.showingScanReview = true } }
            } catch { await MainActor.run { self.isProcessingScan = false } }
        }
    }
}

// ... (SubjectCard, RainbowSubjectCard, ArcadeSubjectCard, RetroSubjectRow - these components remain unchanged from previous versions) ...
// Ensure they are present here or in a SharedComponents file.
// For brevity, I am assuming you have the previous versions of these components.
// If you need me to reprint them, just ask!

// MARK: - SHARED COMPONENTS (Restored)

struct SubjectCard: View {
    let subject: Subject
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(subject.title).font(.title2).fontWeight(.bold).foregroundColor(.themeTextPrimary)
                    Text(subject.courseTeacher).font(.subheadline).foregroundColor(.themeTextSecondary)
                }
                Spacer()
                if let grade = subject.currentGrade { GradeBadge(grade: grade) }
            }
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(icon: "clock", text: "\(subject.courseDaysString) \(subject.courseTimeString)")
                InfoRow(icon: "mappin.circle", text: subject.courseClassroom)
            }
            HStack(spacing: 12) {
                StatPill(icon: "checkmark.circle", value: "\(subject.attendedClasses)", label: "Present")
                StatPill(icon: "xmark.circle", value: "\(subject.totalClasses - subject.attendedClasses)", label: "Absent")
                StatPill(icon: "star", value: "\(subject.gradeHistory?.count ?? 0)", label: "Grades")
            }
        }
        .padding()
        .background(Color.themeSurface)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.adaptiveBorder.opacity(0.3), lineWidth: 1))
    }
}

struct StatPill: View {
    let icon: String; let value: String; let label: String
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.caption2).foregroundColor(.themeTextSecondary)
                Text(value).font(.caption).fontWeight(.semibold).foregroundColor(.themeTextPrimary)
            }
            Text(label).font(.caption2).foregroundColor(.themeTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.adaptiveTertiaryBackground)
        .cornerRadius(8)
    }
}

struct GradeBadge: View {
    let grade: Double
    private var gradeColor: Color {
        switch grade { case 9...10: return .themeSuccess; case 7..<9: return .themePrimary; case 5..<7: return .themeWarning; default: return .themeError }
    }
    var body: some View {
        VStack(spacing: 2) {
            Text(String(format: "%.1f", grade)).font(.system(size: 16, weight: .bold)).foregroundColor(.white)
            Text("/10").font(.system(size: 10, weight: .medium)).foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 8).padding(.vertical, 4).background(gradeColor).cornerRadius(8)
    }
}

struct InfoRow: View {
    let icon: String; let text: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.caption).foregroundColor(.themeTextSecondary).frame(width: 16)
            Text(text).font(.subheadline).foregroundColor(.themeTextPrimary)
            Spacer()
        }
    }
}

struct ArcadeSubjectCard: View {
    let subject: Subject
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack { Circle().fill(Color.purple.opacity(0.2)).frame(width: 40, height: 40); Image(systemName: "bolt.fill").foregroundColor(.purple) }
                Spacer()
                Text("LVL \(Int(subject.attendanceRate * 10))").font(.system(.caption, design: .rounded)).fontWeight(.black).foregroundColor(.white).padding(4).background(Color.purple.opacity(0.2)).cornerRadius(4)
            }
            Text(subject.title).font(.system(.headline, design: .rounded)).fontWeight(.bold).foregroundColor(.white).lineLimit(2).multilineTextAlignment(.leading)
            Spacer()
            HStack {
                if let grade = subject.currentGrade { Text(String(format: "%.1f", grade)).font(.caption).fontWeight(.bold).foregroundColor(.yellow) } else { Text("-.-").font(.caption).foregroundColor(.gray) }
                Spacer()
                Text("\(Int(subject.attendanceRate * 100))%").font(.caption).fontWeight(.bold).foregroundColor(.green)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1))
                    Capsule().fill(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)).frame(width: geo.size.width * subject.attendanceRate)
                }
            }.frame(height: 6)
        }
        .padding()
        .frame(height: 160)
        .background(Color(white: 0.1))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.05), lineWidth: 1))
        .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 5)
    }
}

struct RetroSubjectRow: View {
    let subject: Subject
    var body: some View {
        HStack {
            Text(">").font(.system(.body, design: .monospaced)).foregroundColor(.green).padding(.trailing, 4)
            VStack(alignment: .leading, spacing: 4) {
                Text(subject.title.uppercased()).font(.system(.body, design: .monospaced)).foregroundColor(.white)
                HStack {
                    Text("ID: \(subject.courseTeacher.prefix(3).uppercased())")
                    Text("|")
                    if let grade = subject.currentGrade { Text("VAL: \(String(format: "%.1f", grade))") } else { Text("VAL: NULL") }
                }.font(.system(size: 10, design: .monospaced)).foregroundColor(.gray)
            }
            Spacer()
            Text("[ OPEN ]").font(.system(size: 10, design: .monospaced)).foregroundColor(.green)
        }
        .padding(.vertical, 16)
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.green.opacity(0.3)), alignment: .bottom)
    }
}

struct RainbowSubjectCard: View {
    let subject: Subject; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack { Circle().fill(Color.white.opacity(0.2)).frame(width: 40, height: 40); Image(systemName: "book.fill").foregroundColor(.white).font(.headline) }
                VStack(alignment: .leading, spacing: 4) {
                    Text(subject.title).font(.title3).fontWeight(.bold).foregroundColor(.white).lineLimit(1)
                    Text(subject.courseTeacher).font(.subheadline).fontWeight(.medium).foregroundColor(.white.opacity(0.9)).lineLimit(1)
                }
                Spacer()
                if let grade = subject.currentGrade { VStack(spacing: 0) { Text(String(format: "%.1f", grade)).font(.headline).fontWeight(.black); Text("AVG").font(.system(size: 8, weight: .bold)) }.foregroundColor(color).padding(8).background(Color.white).cornerRadius(8) }
            }
            Divider().background(Color.white.opacity(0.3))
            HStack(spacing: 12) {
                HStack(spacing: 6) { Image(systemName: "calendar"); Text(subject.courseDaysString.isEmpty ? "TBA" : subject.courseDaysString) }
                Text("•").foregroundColor(.white.opacity(0.5))
                HStack(spacing: 6) { Image(systemName: "clock.fill"); Text(subject.courseTimeString) }
            }.font(.subheadline).fontWeight(.medium).foregroundColor(.white)
            HStack {
                HStack(spacing: 6) { Image(systemName: "mappin.and.ellipse"); Text(subject.courseClassroom.isEmpty ? "No Room" : subject.courseClassroom) }.font(.caption).foregroundColor(.white.opacity(0.9))
                Spacer()
                HStack(spacing: 4) { Image(systemName: "person.3.fill"); Text("\(Int(subject.attendanceRate * 100))%") }.font(.caption).fontWeight(.bold).padding(.vertical, 4).padding(.horizontal, 8).background(Color.black.opacity(0.2)).foregroundColor(.white).cornerRadius(6)
            }
        }.padding(16).background(color).cornerRadius(20).shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}
