import SwiftUI

// MARK: - RAINBOW COMPONENTS (NEW)

struct RainbowThemeFactory {
    static func colors(for theme: Theme) -> (primary: Color, secondary: Color, tertiary: Color) {
        switch theme {
        case .classicBlue: return (.blue, .purple, .cyan)
        case .oceanTeal: return (.teal, .blue, .green)
        case .navyNight: return (.indigo, .purple, .pink)
        case .forestGreen: return (.green, .mint, .teal)
        case .mintLeaf: return (Color(red: 0.4, green: 0.8, blue: 0.6), .green, .cyan)
        case .sunsetOrange: return (.orange, .red, .yellow)
        case .coralRed: return (.red, .orange, .pink)
        case .berryPink: return (.pink, .purple, .red)
        case .royalPurple: return (.purple, .indigo, .blue)
        case .lavenderDream: return (Color(red: 0.6, green: 0.4, blue: 0.8), .pink, .blue)
        }
    }
}

struct RainbowStatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .padding(10)
                .background(Color.white.opacity(0.2))
                .clipShape(Circle())
            
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .background(
            LinearGradient(colors: [color, color.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(20)
        .shadow(color: color.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

struct RainbowCardModifier: ViewModifier {
    let color: Color
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                ZStack {
                    Color(white: 0.1) // Dark base
                    LinearGradient(colors: [color.opacity(0.15), color.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
                }
            )
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(color.opacity(0.3), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
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
