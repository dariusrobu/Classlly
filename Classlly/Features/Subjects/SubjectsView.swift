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
                    LazyVStack(spacing: 16) {
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
