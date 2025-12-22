import SwiftUI
import SwiftData

struct SubjectsView: View {
    @EnvironmentObject var themeManager: AppTheme
    var embedInNavigationStack: Bool = true
    
    var body: some View {
        Group {
            switch themeManager.selectedGameMode {
            case .rainbow:
                AnyView(RainbowSubjectsView(embedInNavigationStack: embedInNavigationStack))
            case .standard: // ✅ FIXED: .none -> .standard
                AnyView(StandardSubjectsView())
            }
        }
    }
}

// MARK: - 🌈 RAINBOW SUBJECTS (Vertical List)
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
                    // Empty State
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
                    // ✅ VERTICAL LIST
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 16) {
                            ForEach(Array(subjects.enumerated()), id: \.element.id) { index, subject in
                                let color = cardColors[index % cardColors.count]
                                
                                NavigationLink(destination: SubjectDetailView(subject: subject)) {
                                    // Uses the component from SharedComponents.swift
                                    RainbowSubjectCard(subject: subject, color: color)
                                }
                                .buttonStyle(PlainButtonStyle())
                                // Subtle scroll animation
                                .scrollTransition { content, phase in
                                    content
                                        .opacity(phase.isIdentity ? 1 : 0.8)
                                        .scaleEffect(phase.isIdentity ? 1 : 0.95)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        .padding(.bottom, 100) // Space for floating buttons
                    }
                    
                    // Floating Action Bar (Bottom)
                    VStack {
                        Spacer()
                        HStack(spacing: 12) {
                            Button(action: { showingScanner = true }) {
                                Label("Scan", systemImage: "camera.fill")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .padding(.vertical, 14)
                                    .padding(.horizontal, 24)
                                    .background(accentColor)
                                    .cornerRadius(30)
                            }
                            
                            Button(action: { showingImagePicker = true }) {
                                Image(systemName: "photo.fill")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .padding(14)
                                    .background(RainbowColors.darkCard)
                                    .clipShape(Circle())
                            }
                        }
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
        .sheet(isPresented: $showingAddSubject) {
            AddSubjectView()
        }
        .sheet(isPresented: $showingScanner) {
            DocumentScannerView(didFinishScanning: processScannedImage, didCancel: {}).ignoresSafeArea()
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(didFinishPicking: processScannedImage).ignoresSafeArea()
        }
        .sheet(isPresented: $showingScanReview) {
            ScheduleImportReviewView()
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

// MARK: - 👔 STANDARD SUBJECTS
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
                    LazyVStack(spacing: 20) {
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
                                BigDetailedSubjectCard(subject: subject)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
                
                if isProcessingScan {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    ProgressView()
                }
            }
            .navigationTitle("Subjects").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSubject = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.themePrimary)
                    }
                }
            }
            .sheet(isPresented: $showingAddSubject) {
                AddSubjectView()
            }
            .sheet(isPresented: $showingScanner) { DocumentScannerView(didFinishScanning: processScannedImage, didCancel: {}).ignoresSafeArea() }
            .sheet(isPresented: $showingImagePicker) { ImagePicker(didFinishPicking: processScannedImage).ignoresSafeArea() }
            .sheet(isPresented: $showingScanReview) { ScheduleImportReviewView() }
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

// MARK: - 🕹️ ARCADE SUBJECTS
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
                                NavigationLink(destination: SubjectDetailView(subject: subject)) {
                                    // Uses the component from SharedComponents.swift
                                    ArcadeSubjectCard(subject: subject)
                                }
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
            .sheet(isPresented: $showingScanReview) { ScheduleImportReviewView() }
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

// MARK: - ✨ UNIQUE COMPONENTS FOR THIS VIEW
struct BigDetailedSubjectCard: View {
    let subject: Subject
    private var gradeColor: Color {
        guard let grade = subject.currentGrade else { return .secondary }
        if grade >= 9.0 { return .green }
        else if grade >= 7.0 { return .blue }
        else if grade >= 5.0 { return .orange }
        else { return .red }
    }
    private var attendanceColor: Color {
        let rate = subject.attendanceRate
        if rate >= 0.8 { return .green }
        else if rate >= 0.5 { return .orange }
        else { return .red }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                HStack(spacing: 12) {
                    Capsule().fill(subject.color).frame(width: 4, height: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(subject.title).font(.title3).fontWeight(.bold).foregroundColor(.primary).lineLimit(1)
                        Text(subject.courseTeacher).font(.subheadline).foregroundColor(.secondary).lineLimit(1)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary).padding(.top, 4)
            }
            HStack(spacing: 20) {
                Label(subject.courseClassroom, systemImage: "mappin.and.ellipse")
                Label(subject.courseDaysString, systemImage: "calendar")
                if subject.hasSeminar { Label("Seminar", systemImage: "person.2.fill").foregroundColor(.orange) }
            }.font(.caption).foregroundColor(.secondary).lineLimit(1)
            Divider()
            HStack(spacing: 12) {
                HStack(spacing: 8) { Image(systemName: "graduationcap.fill"); if let grade = subject.currentGrade { Text(String(format: "%.1f", grade)) } else { Text("-") } }
                    .font(.subheadline).fontWeight(.bold).padding(.horizontal, 16).padding(.vertical, 10).background(gradeColor.opacity(0.15)).foregroundColor(gradeColor).cornerRadius(10)
                HStack(spacing: 8) { Image(systemName: "person.3.fill"); Text("\(Int(subject.attendanceRate * 100))%") }
                    .font(.subheadline).fontWeight(.bold).padding(.horizontal, 16).padding(.vertical, 10).background(attendanceColor.opacity(0.15)).foregroundColor(attendanceColor).cornerRadius(10)
                Spacer()
                // ✅ FIX: Renamed ectsCredits to credits
                Text("\(subject.credits) ECTS").font(.caption2).fontWeight(.bold).foregroundColor(.secondary).padding(6).background(Color.secondary.opacity(0.1)).cornerRadius(6)
            }
        }.padding(20).background(Color.themeSurface).cornerRadius(20).shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
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
