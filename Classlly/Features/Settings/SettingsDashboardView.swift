import SwiftUI

struct SettingsDashboardView: View {
    @EnvironmentObject var themeManager: AppTheme
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        Group {
            switch themeManager.selectedGameMode {
            case .rainbow: RainbowSettingsDashboardView()
            case .arcade: ArcadeSettingsDashboardView()
            case .retro: RetroSettingsDashboardView()
            case .none: StandardSettingsDashboardView()
            }
        }
    }
}

struct StandardSettingsDashboardView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    var body: some View {
        NavigationStack {
            List {
                if let user = authManager.currentUser {
                    NavigationLink(destination: ProfileView()) {
                        HStack(spacing: 16) {
                            ZStack { Circle().fill(LinearGradient(gradient: Gradient(colors: [.themePrimary, .themeSecondary]), startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 60, height: 60); Text(getInitials(from: user.fullName)).font(.title2).fontWeight(.bold).foregroundColor(.white) }
                            VStack(alignment: .leading, spacing: 4) { Text(user.fullName).font(.headline).fontWeight(.semibold); Text("View Profile & Stats").font(.subheadline).foregroundColor(.secondary) }
                        }.padding(.vertical, 8)
                    }.listRowBackground(Color.themeSurface)
                }
                Section {
                    NavigationLink(destination: AcademicCalendarView()) { Label("Academic Calendar", systemImage: "calendar.circle.fill") }
                    NavigationLink(destination: SettingsView()) { Label("Settings", systemImage: "gearshape.fill") }
                }.listRowBackground(Color.themeSurface)
                Section {
                    NavigationLink(destination: PrivacyPolicyView()) { Label("Terms & Privacy Policy", systemImage: "lock.shield.fill") }
                }.listRowBackground(Color.themeSurface)
            }
            .scrollContentBackground(.hidden).background(Color.themeBackground)
            .navigationTitle("More").navigationBarTitleDisplayMode(.inline)
        }
    }
}

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
                                    LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing).mask(RoundedRectangle(cornerRadius: 20))
                                    HStack(spacing: 20) {
                                        ZStack { Circle().fill(Color.black.opacity(0.3)).frame(width: 64, height: 64); Text(getInitials(from: user.fullName)).font(.system(.title3, design: .rounded)).fontWeight(.black).foregroundColor(.white) }
                                        VStack(alignment: .leading, spacing: 4) { Text(user.fullName.uppercased()).font(.system(.headline, design: .rounded)).fontWeight(.black).foregroundColor(.white); Text("PLAYER PROFILE").font(.system(size: 10, weight: .bold)).foregroundColor(.cyan).padding(4).background(Color.black.opacity(0.3)).cornerRadius(6) }
                                        Spacer(); Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.7))
                                    }.padding(20)
                                }.shadow(color: .blue.opacity(0.4), radius: 10)
                            }.buttonStyle(PlainButtonStyle())
                        }
                        VStack(alignment: .leading, spacing: 16) {
                            Text("SYSTEM SETTINGS").font(.system(.caption, design: .rounded)).fontWeight(.black).foregroundColor(.gray).padding(.horizontal)
                            VStack(spacing: 12) {
                                ArcadeMenuButton(title: "ACADEMIC CALENDAR", icon: "calendar", color: .green, destination: AnyView(AcademicCalendarView()))
                                ArcadeMenuButton(title: "SYSTEM CONFIG", icon: "gearshape.fill", color: .orange, destination: AnyView(SettingsView()))
                                ArcadeMenuButton(title: "LEGAL PROTOCOLS", icon: "lock.shield.fill", color: .gray, destination: AnyView(PrivacyPolicyView()))
                            }
                        }
                    }.padding()
                }
            }
            .navigationTitle("Command Center").navigationBarTitleDisplayMode(.inline)
        }.preferredColorScheme(.dark)
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

struct RainbowSettingsDashboardView: View {
    @EnvironmentObject var themeManager: AppTheme; @EnvironmentObject var authManager: AuthenticationManager
    var body: some View {
        let colors = RainbowThemeFactory.colors(for: themeManager.selectedTheme)
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                List {
                    if let user = authManager.currentUser {
                        NavigationLink(destination: ProfileView()) {
                            HStack {
                                Circle().fill(colors.primary).frame(width: 50, height: 50).overlay(Text(String(user.firstName.prefix(1))).bold())
                                VStack(alignment: .leading) { Text(user.fullName).font(.headline); Text("View Profile").font(.caption) }
                            }
                        }.listRowBackground(Color(white: 0.1))
                    }
                    Section {
                        NavigationLink(destination: AcademicCalendarView()) { Label("Calendar", systemImage: "calendar") }
                        NavigationLink(destination: SettingsView()) { Label("Settings", systemImage: "gear") }
                        NavigationLink(destination: PrivacyPolicyView()) { Label("Privacy", systemImage: "lock") }
                    }.listRowBackground(Color(white: 0.1))
                }.scrollContentBackground(.hidden)
            }.navigationTitle("More")
        }.preferredColorScheme(.dark)
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
