import SwiftUI

struct SettingsDashboardView: View {
    @EnvironmentObject var themeManager: AppTheme
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        Group {
            switch themeManager.selectedGameMode {
            case .rainbow: RainbowSettingsDashboardView()
            case .arcade: ArcadeSettingsDashboardView()
            case .none: StandardSettingsDashboardView()
            }
        }
    }
}

// MARK: - 🌈 RAINBOW SETTINGS DASHBOARD (Dynamic Color & Dark Cards)
struct RainbowSettingsDashboardView: View {
    @EnvironmentObject var themeManager: AppTheme
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        // Dynamic Accent Color
        let accentColor = themeManager.selectedTheme.primaryColor
        
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 1. Profile Card (Solid Theme Color)
                        if let user = authManager.currentUser {
                            NavigationLink(destination: ProfileView()) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        if let data = user.profileImageData, let uiImage = UIImage(data: data) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 60, height: 60)
                                                .clipShape(Circle())
                                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                        } else {
                                            Circle()
                                                .fill(Color.white.opacity(0.2))
                                                .frame(width: 60, height: 60)
                                            
                                            Text(String(user.firstName.prefix(1)))
                                                .font(.title)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                        }
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(user.fullName)
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        
                                        Text("View Profile & Stats")
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .padding(20)
                                .background(accentColor) // Dynamic Accent Background
                                .cornerRadius(20)
                                .shadow(color: accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                        }
                        
                        // 2. Menu Items (Dark Container with Colorful Icons)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("General")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 4)
                            
                            RainbowContainer {
                                VStack(spacing: 0) {
                                    RainbowMenuRow(
                                        icon: "calendar",
                                        title: "Academic Calendar",
                                        color: RainbowColors.purple,
                                        destination: AnyView(AcademicCalendarView())
                                    )
                                    
                                    Divider()
                                        .background(Color.gray.opacity(0.3))
                                        .padding(.leading, 52)
                                    
                                    RainbowMenuRow(
                                        icon: "gearshape.fill",
                                        title: "Settings",
                                        color: RainbowColors.orange,
                                        destination: AnyView(SettingsView())
                                    )
                                    
                                    Divider()
                                        .background(Color.gray.opacity(0.3))
                                        .padding(.leading, 52)
                                    
                                    RainbowMenuRow(
                                        icon: "lock.shield.fill",
                                        title: "Privacy Policy",
                                        color: RainbowColors.green,
                                        destination: AnyView(PrivacyPolicyView())
                                    )
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }
}

// Helper Component for Menu Rows
struct RainbowMenuRow: View {
    let icon: String
    let title: String
    let color: Color
    let destination: AnyView
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 16) {
                // Icon Circle
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 👔 STANDARD SETTINGS DASHBOARD
struct StandardSettingsDashboardView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        NavigationStack {
            List {
                if let user = authManager.currentUser {
                    NavigationLink(destination: ProfileView()) {
                        HStack(spacing: 16) {
                            ZStack {
                                if let data = user.profileImageData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(LinearGradient(gradient: Gradient(colors: [.themePrimary, .themeSecondary]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 60, height: 60)
                                    Text(getInitials(from: user.fullName))
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.fullName)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Text("View Profile & Stats")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(Color.themeSurface)
                }
                
                Section {
                    NavigationLink(destination: AcademicCalendarView()) {
                        Label("Academic Calendar", systemImage: "calendar.circle.fill")
                    }
                    NavigationLink(destination: SettingsView()) {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                }
                .listRowBackground(Color.themeSurface)
                
                Section {
                    NavigationLink(destination: PrivacyPolicyView()) {
                        Label("Terms & Privacy Policy", systemImage: "lock.shield.fill")
                    }
                }
                .listRowBackground(Color.themeSurface)
            }
            .scrollContentBackground(.hidden)
            .background(Color.themeBackground)
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - 🕹️ ARCADE SETTINGS DASHBOARD
struct ArcadeSettingsDashboardView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        if let user = authManager.currentUser {
                            NavigationLink(destination: ProfileView()) {
                                ZStack {
                                    LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        .mask(RoundedRectangle(cornerRadius: 20))
                                    
                                    HStack(spacing: 20) {
                                        ZStack {
                                            if let data = user.profileImageData, let uiImage = UIImage(data: data) {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 64, height: 64)
                                                    .clipShape(Circle())
                                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                            } else {
                                                Circle()
                                                    .fill(Color.black.opacity(0.3))
                                                    .frame(width: 64, height: 64)
                                                Text(getInitials(from: user.fullName))
                                                    .font(.system(.title3, design: .rounded))
                                                    .fontWeight(.black)
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(user.fullName.uppercased())
                                                .font(.system(.headline, design: .rounded))
                                                .fontWeight(.black)
                                                .foregroundColor(.white)
                                            Text("PLAYER PROFILE")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.cyan)
                                                .padding(4)
                                                .background(Color.black.opacity(0.3))
                                                .cornerRadius(6)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    .padding(20)
                                }
                                .shadow(color: .blue.opacity(0.4), radius: 10)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("SYSTEM SETTINGS")
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.black)
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                ArcadeMenuButton(title: "ACADEMIC CALENDAR", icon: "calendar", color: .green, destination: AnyView(AcademicCalendarView()))
                                ArcadeMenuButton(title: "SYSTEM CONFIG", icon: "gearshape.fill", color: .orange, destination: AnyView(SettingsView()))
                                ArcadeMenuButton(title: "LEGAL PROTOCOLS", icon: "lock.shield.fill", color: .gray, destination: AnyView(PrivacyPolicyView()))
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Command Center")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }
}

struct ArcadeMenuButton: View {
    let title: String; let icon: String; let color: Color; let destination: AnyView
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 16) {
                ZStack { Circle().fill(color.opacity(0.2)).frame(width: 40, height: 40); Image(systemName: icon).font(.headline).foregroundColor(color) }
                Text(title).font(.system(.subheadline, design: .rounded)).fontWeight(.bold).foregroundColor(.white)
                Spacer(); Image(systemName: "arrow.right").font(.caption).foregroundColor(.gray)
            }.padding().background(Color(white: 0.1)).cornerRadius(16).overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.3), lineWidth: 1))
        }.buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 👾 RETRO VIEW
struct RetroSettingsDashboardView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.05).ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if let user = authManager.currentUser {
                            NavigationLink(destination: ProfileView()) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("> USER_DETECTED: \(user.fullName.uppercased())").font(.system(.headline, design: .monospaced)).foregroundColor(.green)
                                    HStack { Text("STATUS:"); Text("ONLINE").foregroundColor(.green).blinking(duration: 1.0) }.font(.system(.caption, design: .monospaced)).foregroundColor(.gray)
                                    
                                    // Add image logic here if you want it in Retro too
                                    if let data = user.profileImageData, let uiImage = UIImage(data: data) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 100)
                                            .border(Color.green, width: 1)
                                    }
                                    
                                    Text("[ ACCESS_PROFILE ]").font(.system(.caption, design: .monospaced)).foregroundColor(.black).padding(6).background(Color.green)
                                }.padding().frame(maxWidth: .infinity, alignment: .leading).border(Color.green, width: 1)
                            }.buttonStyle(PlainButtonStyle())
                        }
                        VStack(alignment: .leading, spacing: 0) {
                            Text("> SYSTEM_MENU").font(.system(.caption, design: .monospaced)).foregroundColor(.gray).padding(.bottom, 8)
                            RetroMenuLink(title: "CALENDAR_DB", destination: AnyView(AcademicCalendarView()))
                            RetroMenuLink(title: "CONFIG_SETTINGS", destination: AnyView(SettingsView()))
                            RetroMenuLink(title: "LEGAL_DOCS", destination: AnyView(PrivacyPolicyView()))
                        }.padding(.horizontal)
                    }.padding(.top)
                }
            }
            .navigationTitle("SYSTEM_ROOT").navigationBarTitleDisplayMode(.inline)
        }.preferredColorScheme(.dark)
    }
}

struct RetroMenuLink: View {
    let title: String; let destination: AnyView
    var body: some View {
        NavigationLink(destination: destination) {
            HStack { Text(">").foregroundColor(.green); Text(title).font(.system(.body, design: .monospaced)).foregroundColor(.white); Spacer() }
            .padding(.vertical, 16).border(width: 1, edges: [.bottom], color: Color.green.opacity(0.3))
        }
    }
}

// Helper functions and extensions
private func getInitials(from name: String) -> String { let names = name.split(separator: " "); let initials = names.prefix(2).map { String($0.first ?? Character("")) }; return initials.joined() }
extension View { func blinking(duration: Double = 0.75) -> some View { modifier(BlinkModifier(duration: duration)) } }
struct BlinkModifier: ViewModifier { let duration: Double; @State private var blinking: Bool = false; func body(content: Content) -> some View { content.opacity(blinking ? 0 : 1).onAppear { withAnimation(.easeInOut(duration: duration).repeatForever()) { blinking = true } } } }
extension View { func border(width: CGFloat, edges: [Edge], color: Color) -> some View { overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color)) } }
struct EdgeBorder: Shape {
    var width: CGFloat; var edges: [Edge]
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for edge in edges {
            var x: CGFloat { switch edge { case .top, .bottom, .leading: return rect.minX; case .trailing: return rect.maxX - width } }
            var y: CGFloat { switch edge { case .top, .leading, .trailing: return rect.minY; case .bottom: return rect.maxY - width } }
            var w: CGFloat { switch edge { case .top, .bottom: return rect.width; case .leading, .trailing: return width } }
            var h: CGFloat { switch edge { case .top, .bottom: return width; case .leading, .trailing: return rect.height } }
            path.addPath(Path(CGRect(x: x, y: y, width: w, height: h)))
        }
        return path
    }
}
