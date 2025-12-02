//
//  PrivacyPolicyView.swift
//  Classlly
//
//  Created by Robu Darius on 01.11.2025.
//


import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    public init() {}
    
    var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Privacy Policy")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Last updated: \(Date().formatted(date: .abbreviated, time: .omitted))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 10)
                    .background(Color.themeBackground) // <-- ADD THIS LINE
                    .navigationTitle("Privacy Policy")
                    
                    // Introduction
                    PolicySection(title: "Introduction") {
                        Text("Classlly (\"we,\" \"our,\" or \"us\") is committed to protecting your privacy. This Privacy Policy explains how your personal information is collected, used, and disclosed by Classlly.")
                    }
                    
                    // Information We Collect
                    PolicySection(title: "Information We Collect") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("We collect information you provide directly to us:")
                                .fontWeight(.medium)
                            
                            BulletPoint("Account Information: Your name, email address, and academic information when you create an account")
                            BulletPoint("Academic Data: Your subjects, tasks, grades, and schedule information")
                            BulletPoint("Usage Data: How you interact with our app to improve user experience")
                            BulletPoint("Device Information: Basic device information for app functionality")
                        }
                    }
                    
                    // How We Use Your Information
                    PolicySection(title: "How We Use Your Information") {
                        VStack(alignment: .leading, spacing: 12) {
                            BulletPoint("To provide and maintain the Classlly service")
                            BulletPoint("To personalize your academic experience")
                            BulletPoint("To send you important updates and notifications")
                            BulletPoint("To improve our app and develop new features")
                            BulletPoint("To analyze usage patterns and optimize performance")
                        }
                    }
                    
                    // Data Storage and Security
                    PolicySection(title: "Data Storage and Security") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your data is stored securely on your device and in iCloud (if enabled). We implement appropriate technical and organizational measures to protect your personal information.")
                            
                            BulletPoint("Local Storage: Your data is primarily stored on your device")
                            BulletPoint("iCloud Sync: Optional iCloud synchronization for backup across devices")
                            BulletPoint("Encryption: Data is encrypted in transit and at rest")
                            BulletPoint("No Third-Party Sharing: We don't sell your data to third parties")
                        }
                    }
                    
                    // Your Rights
                    PolicySection(title: "Your Rights") {
                        VStack(alignment: .leading, spacing: 12) {
                            BulletPoint("Access: You can access your personal data at any time")
                            BulletPoint("Correction: You can update or correct your information")
                            BulletPoint("Deletion: You can delete your account and all associated data")
                            BulletPoint("Export: You can export your data from the app")
                            BulletPoint("Opt-out: You can disable notifications and data collection")
                        }
                    }
                    
                    // Children's Privacy
                    PolicySection(title: "Children's Privacy") {
                        Text("Classlly is designed for students of all ages. We comply with applicable children's privacy regulations. For users under 13, we require parental consent for data collection.")
                    }
                    
                    // Changes to This Policy
                    PolicySection(title: "Changes to This Policy") {
                        Text("We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the \"Last updated\" date.")
                    }
                    
                    // Contact Us
                    PolicySection(title: "Contact Us") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("If you have any questions about this Privacy Policy, please contact us:")
                            
                            Button(action: {
                                if let url = URL(string: "mailto:privacy@classlly.app") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "envelope")
                                    Text("privacy@classlly.app")
                                }
                                .foregroundColor(.themePrimary)
                            }
                            
                            Button(action: {
                                if let url = URL(string: "https://classlly.app/support") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "globe")
                                    Text("Visit our website")
                                }
                                .foregroundColor(.themePrimary)
                            }
                        }
                    }
                    
                    // Agreement
                    VStack(alignment: .leading, spacing: 12) {
                        Text("By using Classlly, you agree to the collection and use of information in accordance with this policy.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("This policy is effective as of the date above.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 10)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }


struct PolicySection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            content
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct BulletPoint: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.body)
                .foregroundColor(.primary)
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}
