import SwiftUI

// MARK: - RAINBOW THEME UTILS
struct RainbowColors {
    static let blue = Color(red: 0.0, green: 0.6, blue: 1.0)       // Vibrant Blue
    static let orange = Color(red: 1.0, green: 0.5, blue: 0.2)     // Vibrant Orange
    static let green = Color(red: 0.0, green: 0.8, blue: 0.6)      // Vibrant Mint/Green
    static let purple = Color(red: 0.6, green: 0.2, blue: 1.0)
    static let darkCard = Color(red: 0.11, green: 0.11, blue: 0.12) // Dark Gray
    static let background = Color.black
}

// MARK: - RAINBOW COMPONENTS

// 1. Rainbow Header (Custom Navigation Bar)
struct RainbowHeader: View {
    let title: String
    let accentColor: Color
    let showBackButton: Bool
    let backAction: (() -> Void)?
    let trailingIcon: String?
    let trailingAction: (() -> Void)?
    
    var body: some View {
        HStack {
            // Left: Back Button or Empty Placeholder
            if showBackButton {
                Button(action: { backAction?() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(accentColor)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            } else {
                Spacer().frame(width: 44) // Balance spacing
            }
            
            Spacer()
            
            // Center: Title
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
            
            // Right: Action Button or Empty Placeholder
            if let icon = trailingIcon, let action = trailingAction {
                Button(action: action) {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(accentColor)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            } else {
                Spacer().frame(width: 44) // Balance spacing
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color.black) // Seamless background
    }
}

// 2. Rainbow Gradient Text
struct RainbowGradientText: View {
    let text: String
    let colors: [Color]
    var font: Font = .title
    var weight: Font.Weight = .bold
    
    var body: some View {
        Text(text)
            .font(font)
            .fontWeight(weight)
            .overlay(
                LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
                    .mask(Text(text).font(font).fontWeight(weight))
            )
            .foregroundColor(.clear)
    }
}

// 3. Rainbow Card (Container with optional Gradient Border)
struct RainbowCard<Content: View>: View {
    let colors: [Color]
    let content: Content
    
    init(colors: [Color], @ViewBuilder content: () -> Content) {
        self.colors = colors
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            Color(white: 0.1) // Dark surface
            content.padding()
        }
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        )
    }
}

// 4. Rainbow Stat Box (Solid Colorful Square)
struct RainbowStatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.headline)
                    .padding(8)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
                
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
            }
            
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .opacity(0.9)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(color)
        .cornerRadius(20)
    }
}

// 5. Rainbow Container (Dark Gray Card for lists/forms)
struct RainbowContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(20)
            .background(RainbowColors.darkCard)
            .cornerRadius(20)
    }
}

// MARK: - STANDARD COMPONENTS

struct StandardDayChip: View {
    let day: String; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(day).font(.caption).fontWeight(.medium).foregroundColor(isSelected ? .white : .primary)
                .frame(height: 32).frame(maxWidth: .infinity)
                .background(isSelected ? Color.blue : Color(.systemGray6)).cornerRadius(8)
        }.buttonStyle(PlainButtonStyle())
    }
}

struct StatBox: View {
    let title: String; let value: String
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        VStack(spacing: 8) {
            Text(value).font(.title2).fontWeight(.bold).foregroundColor(.themePrimary)
            Text(title).font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center).minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity).frame(height: 90).padding(.horizontal, 4)
        .background(Color.themeSurface).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.adaptiveBorder.opacity(0.3), lineWidth: 1))
    }
}

struct DetailInfoCard: View {
    let icon: String; let title: String; let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) { Image(systemName: icon).font(.caption).foregroundColor(.themePrimary).frame(width: 16); Text(title).font(.caption).fontWeight(.medium).foregroundColor(.themeTextSecondary) }
            Text(value).font(.subheadline).fontWeight(.medium).foregroundColor(.themeTextPrimary).lineLimit(2).minimumScaleFactor(0.8)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(12).background(Color.adaptiveTertiaryBackground).cornerRadius(10)
    }
}

struct SectionHeader: View {
    let title: String; let icon: String
    var body: some View { HStack(spacing: 8) { Image(systemName: icon).font(.system(size: 14, weight: .medium)).foregroundColor(.themePrimary); Text(title).font(.headline).fontWeight(.semibold).foregroundColor(.themeTextPrimary); Spacer() } }
}

struct ActionButton: View {
    let icon: String; let title: String; let subtitle: String; let color: Color; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.title2).foregroundColor(color)
                Text(title).font(.caption).fontWeight(.medium).foregroundColor(.themeTextPrimary).multilineTextAlignment(.center)
                Text(subtitle).font(.caption2).foregroundColor(.themeTextSecondary).multilineTextAlignment(.center)
            }.frame(maxWidth: .infinity).padding().background(color.opacity(0.1)).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.3), lineWidth: 1))
        }.buttonStyle(PlainButtonStyle())
    }
}

struct PerformanceCard: View {
    let title: String; let value: String; let subtitle: String; let color: Color; let icon: String; let progress: Double; var trendIcon: String? = nil; var trendColor: Color? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon).font(.system(size: 16)).foregroundColor(color)
                Text(title).font(.subheadline).fontWeight(.medium).foregroundColor(.themeTextSecondary); Spacer()
                if let tIcon = trendIcon, let tColor = trendColor { Image(systemName: tIcon).font(.system(size: 14)).foregroundColor(tColor) }
            }
            Text(value).font(.title2).fontWeight(.bold).foregroundColor(.themeTextPrimary); Text(subtitle).font(.caption).foregroundColor(.themeTextSecondary)
            GeometryReader { geo in
                ZStack(alignment: .leading) { Rectangle().fill(Color.adaptiveTertiaryBackground).frame(height: 4); Rectangle().fill(color).frame(width: geo.size.width * progress, height: 4) }
            }.frame(height: 4)
        }.padding().background(Color.themeSurface).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.adaptiveTertiaryBackground, lineWidth: 1))
    }
}

// MARK: - ARCADE COMPONENTS

struct ArcadeSection<Content: View>: View {
    let title: String; let color: Color; let content: Content
    init(title: String, color: Color, @ViewBuilder content: () -> Content) { self.title = title; self.color = color; self.content = content() }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.caption).fontWeight(.black).foregroundColor(color)
            VStack(spacing: 12) { content }.padding().background(Color(white: 0.1)).cornerRadius(16).overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.3), lineWidth: 1))
        }
    }
}

struct ArcadeInput: View {
    let icon: String; let placeholder: String; @Binding var text: String
    var body: some View { HStack { Image(systemName: icon).foregroundColor(.gray); TextField(placeholder, text: $text).foregroundColor(.white) }.padding(10).background(Color.black).cornerRadius(8) }
}

struct ArcadeDayChip: View {
    let label: String; let isSelected: Bool; let color: Color; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label).font(.caption).fontWeight(.bold).frame(width: 30, height: 30)
                .background(isSelected ? color : Color.black).foregroundColor(isSelected ? .white : .gray).cornerRadius(15).overlay(Circle().stroke(isSelected ? .white : color.opacity(0.5), lineWidth: 1))
        }
    }
}

struct ArcadeStatPill: View {
    let icon: String; let value: String; let label: String; let gradient: Gradient
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle().fill(LinearGradient(gradient: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 36, height: 36).shadow(color: Color(uiColor: UIColor(gradient.stops.first!.color)).opacity(0.4), radius: 5)
                Image(systemName: icon).font(.system(size: 16, weight: .bold)).foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 0) {
                Text(value).font(.system(.title3, design: .rounded)).fontWeight(.black).foregroundColor(.white)
                Text(label).font(.system(size: 10, weight: .bold)).foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).frame(height: 60)
        .padding(8).background(Color(white: 0.1)).cornerRadius(20)
    }
}

struct ArcadeActionButton: View {
    let icon: String; let label: String; let color: Color; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack { Image(systemName: icon).font(.headline); Text(label).font(.system(size: 8, weight: .black)) }
            .frame(maxWidth: .infinity).padding(.vertical, 12).background(color.opacity(0.2)).foregroundColor(color).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(color, lineWidth: 1))
        }
    }
}

struct ArcadeInfoCell: View {
    let label: String; let value: String; let icon: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 8, weight: .black)).foregroundColor(.gray)
            HStack { Image(systemName: icon).font(.caption).foregroundColor(.cyan); Text(value.isEmpty ? "N/A" : value).font(.caption).fontWeight(.bold).foregroundColor(.white).lineLimit(1) }
        }.padding().frame(maxWidth: .infinity, alignment: .leading).background(Color(white: 0.1)).cornerRadius(12)
    }
}

// MARK: - RETRO COMPONENTS

struct RetroDayCheck: View {
    let label: String; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack { Text(isSelected ? "[X]" : "[ ]").foregroundColor(isSelected ? .green : .gray); Text(label).foregroundColor(isSelected ? .green : .gray) }.font(.system(.caption, design: .monospaced))
        }
    }
}

struct RetroInfoRow: View {
    let label: String; let value: String
    var body: some View {
        HStack { Text("\(label):").foregroundColor(.green); Spacer(); Text(value.isEmpty ? "NULL" : value.uppercased()).foregroundColor(.white) }.font(.system(.body, design: .monospaced))
    }
}

struct RetroButton: View {
    let label: String; var color: Color = .green; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label).font(.system(.caption, design: .monospaced)).foregroundColor(color).frame(maxWidth: .infinity).padding(8).border(color, width: 1)
        }
    }
}

struct RetroStatCard: View {
    let label: String; let value: String; let color: Color
    var body: some View {
        VStack(spacing: 8) {
            Text(value).font(.system(.title, design: .monospaced)).fontWeight(.bold).foregroundColor(color)
            Text(label).font(.system(size: 10, design: .monospaced)).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity).frame(height: 80)
        .padding(8).background(Color.black).overlay(RoundedRectangle(cornerRadius: 4).stroke(color, lineWidth: 1))
    }
}

// MARK: - RAINBOW THEME FACTORY (Restored for compatibility)
struct RainbowThemeFactory {
    static func palette(for theme: Theme) -> [Color] {
        // Fallback or utility if needed elsewhere
        switch theme {
        case .classicBlue: return [.blue, .cyan, .purple]
        default: return [.blue, .cyan, .purple]
        }
    }
}
