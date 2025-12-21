import SwiftUI

struct WhatIfGradeView: View {
    @EnvironmentObject var themeManager: AppTheme
    let subject: Subject
    
    var body: some View {
        Group {
            switch themeManager.selectedGameMode {
            case .rainbow:
                AnyView(RainbowWhatIfView(subject: subject))
            case .standard:
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
                        Text(String(format: "%.2f", subject.currentGrade ?? 0.0))
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
