import SwiftUI
import SwiftData

// MARK: - MAIN SWITCHER
struct ProfileView: View {
    @EnvironmentObject var themeManager: AppTheme
    @EnvironmentObject var authManager: AuthenticationManager
    @Query var subjects: [Subject]
    @Query var tasks: [StudyTask]
    
    var body: some View {
        Group {
            switch themeManager.selectedGameMode {
            case .arcade:
                ArcadeProfileView(user: authManager.currentUser, subjects: subjects, tasks: tasks)
            case .retro:
                RetroProfileView(user: authManager.currentUser, subjects: subjects, tasks: tasks)
            case .none:
                StandardProfileView(user: authManager.currentUser, subjects: subjects, tasks: tasks)
            }
        }
    }
}

// MARK: - 👔 STANDARD VIEW
struct StandardProfileView: View {
    let user: UserProfile?
    let subjects: [Subject]
    let tasks: [StudyTask]
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.modelContext) var modelContext
    
    var body: some View {
        ScrollView {
            if let user = user {
                VStack(spacing: 24) {
                    // Avatar & Name
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [.themePrimary, .themeSecondary]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 100, height: 100)
                            
                            Text(String(user.firstName.prefix(1)))
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 4) {
                            Text(user.fullName)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text(user.schoolName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(user.gradeLevel)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.themeSurface)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Stats
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Stats")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        HStack(spacing: 12) {
                            StatBox(title: "Subjects", value: "\(subjects.count)")
                            StatBox(title: "Tasks", value: "\(tasks.count)")
                        }
                        .padding(.horizontal)
                    }
                    
                    // Account Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Account")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            Button(action: {
                                authManager.signOut(modelContext: modelContext)
                            }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .foregroundColor(.red)
                                    Text("Sign Out")
                                        .foregroundColor(.red)
                                    Spacer()
                                }
                                .padding()
                                .background(Color.themeSurface)
                            }
                        }
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
        .background(Color.themeBackground)
        .navigationTitle("Profile")
    }
}

// MARK: - 🕹️ ARCADE VIEW
struct ArcadeProfileView: View {
    let user: UserProfile?
    let subjects: [Subject]
    let tasks: [StudyTask]
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.modelContext) var modelContext

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    if let user = user {
                        // Avatar
                        ZStack {
                            Circle()
                                .stroke(Color.cyan, lineWidth: 3)
                                .frame(width: 110, height: 110)
                            
                            Circle()
                                .fill(Color.purple.opacity(0.5))
                                .frame(width: 100, height: 100)
                            
                            Text(String(user.firstName.prefix(1)))
                                .font(.system(size: 40, weight: .black))
                                .foregroundColor(.white)
                        }
                        .shadow(color: .cyan, radius: 10)
                        
                        // Info
                        VStack(spacing: 8) {
                            Text(user.fullName.uppercased())
                                .font(.system(.title2, design: .rounded))
                                .fontWeight(.black)
                                .foregroundColor(.white)
                            
                            Text("CLASS: \(user.gradeLevel.uppercased())")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                            
                            Text("GUILD: \(user.schoolName.uppercased())")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                        }
                        
                        // Stats
                        HStack(spacing: 16) {
                            ArcadeStatPill(icon: "bolt.fill", value: "\(subjects.count)", label: "Skills", gradient: Gradient(colors: [.blue, .purple]))
                            ArcadeStatPill(icon: "flame.fill", value: "\(tasks.count)", label: "Quests", gradient: Gradient(colors: [.orange, .red]))
                        }
                        .padding()
                        
                        // Logout
                        Button(action: {
                            authManager.signOut(modelContext: modelContext)
                        }) {
                            Text("LOGOUT")
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.black)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red.opacity(0.2))
                                .foregroundColor(.red)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.red, lineWidth: 1)
                                )
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
        }
        .navigationTitle("Player Stats")
    }
}

// MARK: - 👾 RETRO VIEW
struct RetroProfileView: View {
    let user: UserProfile?
    let subjects: [Subject]
    let tasks: [StudyTask]
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.modelContext) var modelContext

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.05).ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let user = user {
                        Text("> IDENTIFYING_USER...")
                            .font(.caption)
                            .fontDesign(.monospaced)
                            .foregroundColor(.green)
                        
                        // User Data
                        VStack(alignment: .leading, spacing: 8) {
                            Text("USER_ID: \(user.firstName.uppercased())")
                                .font(.title3)
                                .fontDesign(.monospaced)
                                .foregroundColor(.white)
                            
                            RetroInfoRow(label: "FULL_NAME", value: user.fullName)
                            RetroInfoRow(label: "AFFILIATION", value: user.schoolName)
                            RetroInfoRow(label: "RANK", value: user.gradeLevel)
                        }
                        .padding()
                        .border(Color.green, width: 1)
                        
                        // Stats
                        Text("STATS_DUMP:")
                            .font(.caption)
                            .fontDesign(.monospaced)
                            .foregroundColor(.gray)
                        
                        HStack {
                            Text("SKILLS_LOADED: \(subjects.count)")
                                .font(.body)
                                .fontDesign(.monospaced)
                                .foregroundColor(.green)
                            Spacer()
                            Text("QUESTS_ACTIVE: \(tasks.count)")
                                .font(.body)
                                .fontDesign(.monospaced)
                                .foregroundColor(.green)
                        }
                        .padding()
                        .border(Color.green.opacity(0.5), width: 1)
                        
                        // Logout
                        Button(action: {
                            authManager.signOut(modelContext: modelContext)
                        }) {
                            Text("[ TERMINATE_SESSION ]")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .border(Color.red, width: 1)
                        }
                        .padding(.top)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("USER_PROFILE")
    }
}
