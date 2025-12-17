import SwiftUI

struct WhatIfGradeView: View {
    @EnvironmentObject var themeManager: AppTheme
    let subject: Subject
    
    var body: some View {
        Group {
            switch themeManager.selectedGameMode {
            case .arcade:
                AnyView(ArcadeWhatIfView(subject: subject))
            case .rainbow:
                AnyView(RainbowWhatIfView(subject: subject))
            case .none:
                AnyView(StandardWhatIfView(subject: subject))
            }
        }
    }
}

// MARK: - 👔 STANDARD VIEW
struct StandardWhatIfView: View {
    let subject: Subject
    @Environment(\.dismiss) var dismiss
    
    @State private var targetGrade: String = ""
    @State private var examWeight: String = "40" // Common default
    @State private var resultGrade: Double? = nil
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Current Status")) {
                    HStack {
                        Text("Current Average")
                        Spacer()
                        Text(String(format: "%.2f", subject.weightedAverage ?? 0.0))
                            .fontWeight(.bold)
                            .foregroundColor(.themePrimary)
                    }
                }
                
                Section(header: Text("The Scenario")) {
                    HStack {
                        Text("Goal Average")
                        Spacer()
                        TextField("e.g. 9.0", text: $targetGrade)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Exam Weight (%)")
                        Spacer()
                        TextField("e.g. 40", text: $examWeight)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section {
                    Button("Calculate") {
                        calculate()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.themePrimary)
                    .fontWeight(.bold)
                }
                
                if let result = resultGrade {
                    Section(header: Text("Result")) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("You need to score:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text(String(format: "%.2f", result))
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundColor(resultColor(result))
                                Text("/ 10")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(feedbackMessage(result))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("What If Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    
    private func calculate() {
        guard let target = Double(targetGrade),
              let weight = Double(examWeight) else { return }
        let needed = subject.scoreNeeded(forTarget: target * 10, nextAssignmentMax: 10.0 * (weight / 100.0))
        resultGrade = needed / (10.0 * (weight / 100.0)) * 10.0
    }
    
    private func resultColor(_ grade: Double) -> Color {
        if grade > 10 { return .themeError }
        if grade <= 0 { return .themeSuccess }
        return .themePrimary
    }
    
    private func feedbackMessage(_ grade: Double) -> String {
        if grade > 10 { return "Mathematically impossible. Extra credit needed!" }
        if grade > 9.5 { return "It's going to be tough, but possible." }
        if grade <= 0 { return "You've already secured this average!" }
        return "Aim for this score on your exam."
    }
}

// MARK: - 🌈 RAINBOW VIEW
struct RainbowWhatIfView: View {
    let subject: Subject
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: AppTheme
    
    @State private var targetGrade: String = ""
    @State private var examWeight: String = ""
    @State private var resultGrade: Double? = nil
    
    var body: some View {
        let accentColor = themeManager.selectedTheme.primaryColor
        
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Current Stats
                        RainbowContainer {
                            VStack(spacing: 8) {
                                Text("Current Average")
                                    .foregroundColor(.gray)
                                    .font(.headline)
                                Text(String(format: "%.2f", subject.currentGrade ?? 0.0))
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        // Inputs
                        RainbowContainer {
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Set Your Goals").font(.headline).foregroundColor(.white)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Desired Grade").font(.caption).foregroundColor(accentColor).fontWeight(.bold)
                                    TextField("e.g. 9.5", text: $targetGrade)
                                        .keyboardType(.decimalPad)
                                        .padding()
                                        .background(Color.black.opacity(0.3))
                                        .cornerRadius(12)
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Next Exam/Task Weight (%)").font(.caption).foregroundColor(RainbowColors.blue).fontWeight(.bold)
                                    TextField("e.g. 50", text: $examWeight)
                                        .keyboardType(.numberPad)
                                        .padding()
                                        .background(Color.black.opacity(0.3))
                                        .cornerRadius(12)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        
                        // Calculate Button
                        Button(action: calculate) {
                            Text("Calculate")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(LinearGradient(colors: [accentColor, RainbowColors.blue], startPoint: .leading, endPoint: .trailing))
                                .cornerRadius(16)
                        }
                        
                        // Result
                        if let result = resultGrade {
                            RainbowContainer {
                                VStack(spacing: 12) {
                                    Text("Required Score")
                                        .foregroundColor(.gray)
                                        .fontWeight(.medium)
                                    
                                    Text(String(format: "%.2f", result))
                                        .font(.system(size: 56, weight: .black))
                                        .foregroundColor(result > 10 ? .red : (result <= 4 ? .green : .white))
                                        .shadow(color: (result > 10 ? Color.red : Color.white).opacity(0.5), radius: 10)
                                    
                                    Text(feedbackMessage(result))
                                        .font(.caption)
                                        .foregroundColor(result > 10 ? .red : .gray)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("What If?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }.foregroundColor(.white)
                }
            }
        }
    }
    
    private func calculate() {
        withAnimation(.spring()) {
            guard let target = Double(targetGrade),
                  let weight = Double(examWeight) else { return }
            let needed = subject.scoreNeeded(forTarget: target * 10, nextAssignmentMax: 10.0 * (weight / 100.0))
            resultGrade = needed / (10.0 * (weight / 100.0)) * 10.0
        }
    }
    
    private func feedbackMessage(_ grade: Double) -> String {
        if grade > 10 { return "Impossible! You need > 10." }
        if grade > 9.0 { return "Study hard! You can do it." }
        if grade <= 0 { return "You're already there!" }
        return "This is your target."
    }
}

// MARK: - 🕹️ ARCADE VIEW
struct ArcadeWhatIfView: View {
    let subject: Subject
    @Environment(\.dismiss) var dismiss
    
    @State private var targetGrade: String = ""
    @State private var examWeight: String = ""
    @State private var resultGrade: Double? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Header Status
                    HStack {
                        VStack(alignment: .leading) {
                            Text("CURRENT XP").font(.caption).fontWeight(.black).foregroundColor(.gray)
                            Text(String(format: "%.2f", subject.currentGrade ?? 0.0))
                                .font(.system(size: 40, design: .rounded))
                                .fontWeight(.black)
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Image(systemName: "brain.head.profile").font(.largeTitle).foregroundColor(.cyan)
                    }
                    .padding()
                    .background(Color(white: 0.1))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.cyan.opacity(0.5), lineWidth: 1))
                    .padding(.horizontal)
                    
                    // Inputs
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("TARGET LEVEL").font(.system(size: 10, weight: .black)).foregroundColor(.green)
                            TextField("10.0", text: $targetGrade)
                                .keyboardType(.decimalPad)
                                .padding()
                                .background(Color.black)
                                .foregroundColor(.green)
                                .font(.system(.title3, design: .monospaced))
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.green, lineWidth: 1))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("BOSS DIFFICULTY (WEIGHT %)").font(.system(size: 10, weight: .black)).foregroundColor(.red)
                            TextField("40", text: $examWeight)
                                .keyboardType(.numberPad)
                                .padding()
                                .background(Color.black)
                                .foregroundColor(.red)
                                .font(.system(.title3, design: .monospaced))
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red, lineWidth: 1))
                        }
                    }
                    .padding(.horizontal)
                    
                    Button(action: calculate) {
                        Text("SIMULATE BATTLE")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.black)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.yellow)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Output
                    if let result = resultGrade {
                        VStack(spacing: 8) {
                            Text("REQUIRED DAMAGE")
                                .font(.caption).fontWeight(.black).foregroundColor(.gray)
                            
                            Text(String(format: "%.2f", result))
                                .font(.system(size: 60, weight: .black, design: .rounded))
                                .foregroundColor(result > 10 ? .red : .cyan)
                                .shadow(color: (result > 10 ? Color.red : Color.cyan).opacity(0.6), radius: 10)
                            
                            if result > 10 {
                                Text("MISSION IMPOSSIBLE").font(.caption).fontWeight(.black).foregroundColor(.red).padding(4).background(Color.red.opacity(0.2))
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(white: 0.05))
                        .transition(.move(edge: .bottom))
                    }
                    
                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Simulation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("EJECT") { dismiss() }.font(.caption).fontWeight(.bold).foregroundColor(.red)
                }
            }
        }
    }
    
    private func calculate() {
        withAnimation {
            guard let target = Double(targetGrade),
                  let weight = Double(examWeight) else { return }
            let needed = subject.scoreNeeded(forTarget: target * 10, nextAssignmentMax: 10.0 * (weight / 100.0))
            resultGrade = needed / (10.0 * (weight / 100.0)) * 10.0
        }
    }
}

