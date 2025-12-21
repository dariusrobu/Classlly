import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        let isRainbow = themeManager.selectedGameMode == .rainbow
        
        ZStack {
            if isRainbow {
                Color.black.ignoresSafeArea()
            } else {
                Color.themeBackground.ignoresSafeArea()
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // ✅ Custom Header for Rainbow Mode with Back Button
                    if isRainbow {
                        HStack(spacing: 16) {
                            Button(action: { dismiss() }) {
                                Image(systemName: "chevron.left")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color(white: 0.15))
                                    .clipShape(Circle())
                            }
                            Spacer()
                        }
                        .padding(.bottom, 10)
                    }
                    
                    // Header Text
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Privacy Policy")
                            .font(.largeTitle).fontWeight(.black)
                            .foregroundColor(isRainbow ? .white : .primary)
                        
                        Text("Last updated: \(Date().formatted(date: .abbreviated, time: .omitted))")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, 20)
                    
                    // Sections
                    Group {
                        PolicySection(title: "Introduction", isRainbow: isRainbow) {
                            Text("Classlly is committed to protecting your privacy. This policy explains how your data is handled.")
                        }
                        
                        PolicySection(title: "Data We Collect", isRainbow: isRainbow) {
                            BulletPoint("Account Info: Name & University", isRainbow: isRainbow)
                            BulletPoint("Academic Data: Tasks, Grades, Schedule", isRainbow: isRainbow)
                            BulletPoint("Local Usage: App interactions", isRainbow: isRainbow)
                        }
                        
                        PolicySection(title: "Data Storage", isRainbow: isRainbow) {
                            Text("Your data is primarily stored locally on your device. We do not sell your data.")
                        }
                        
                        PolicySection(title: "Contact", isRainbow: isRainbow) {
                            Button(action: {}) {
                                Text("simplly.team@gmail.com").foregroundColor(themeManager.selectedTheme.primaryColor)
                            }
                        }
                    }
                }
                .padding(24)
            }
        }
        // ✅ Hide native navigation bar only in Rainbow mode to avoid double headers or missing buttons
        .navigationBarHidden(isRainbow)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PolicySection<Content: View>: View {
    let title: String
    let isRainbow: Bool
    let content: Content
    
    init(title: String, isRainbow: Bool, @ViewBuilder content: () -> Content) {
        self.title = title
        self.isRainbow = isRainbow
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline).fontWeight(.bold).foregroundColor(isRainbow ? .white : .primary)
            content.font(.body).foregroundColor(isRainbow ? .gray : .primary)
        }
    }
}

struct BulletPoint: View {
    let text: String
    let isRainbow: Bool
    init(_ text: String, isRainbow: Bool) { self.text = text; self.isRainbow = isRainbow }
    var body: some View {
        HStack(alignment: .top) {
            Text("•").foregroundColor(isRainbow ? .gray : .primary)
            Text(text).foregroundColor(isRainbow ? .gray : .primary)
        }
    }
}
