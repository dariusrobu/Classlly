
// MARK: - RAINBOW COMPONENTS

// 1. Rainbow Header (Custom Navigation Bar)
struct RainbowHeader: View {
let title: String
let accentColor: Color
@@ -23,7 +22,6 @@ struct RainbowHeader: View {

var body: some View {
HStack {
            // Left: Back Button or Empty Placeholder
if showBackButton {
Button(action: { backAction?() }) {
Image(systemName: "chevron.left")
@@ -34,20 +32,18 @@ struct RainbowHeader: View {
.clipShape(Circle())
}
} else {
                Spacer().frame(width: 44) // Balance spacing
                Spacer().frame(width: 44)
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
@@ -58,16 +54,15 @@ struct RainbowHeader: View {
.clipShape(Circle())
}
} else {
                Spacer().frame(width: 44) // Balance spacing
                Spacer().frame(width: 44)
}
}
.padding(.horizontal)
.padding(.vertical, 10)
        .background(Color.black) // Seamless background
        .background(Color.black)
}
}

// 2. Rainbow Gradient Text
struct RainbowGradientText: View {
let text: String
let colors: [Color]
@@ -86,7 +81,6 @@ struct RainbowGradientText: View {
}
}

// 3. Rainbow Card (Container with optional Gradient Border)
struct RainbowCard<Content: View>: View {
let colors: [Color]
let content: Content
@@ -98,7 +92,7 @@ struct RainbowCard<Content: View>: View {

var body: some View {
ZStack {
            Color(white: 0.1) // Dark surface
            Color(white: 0.1)
content.padding()
}
.cornerRadius(12)
@@ -112,7 +106,6 @@ struct RainbowCard<Content: View>: View {
}
}

// 4. Rainbow Stat Box (Solid Colorful Square)
struct RainbowStatBox: View {
let title: String
let value: String
@@ -146,7 +139,6 @@ struct RainbowStatBox: View {
}
}

// 5. Rainbow Container (Dark Gray Card for lists/forms)
struct RainbowContainer<Content: View>: View {
let content: Content

@@ -162,112 +154,416 @@ struct RainbowContainer<Content: View>: View {
}
}

struct RainbowSubjectCard: View {
    let subject: Subject
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle().fill(Color.white.opacity(0.2)).frame(width: 40, height: 40)
                    Image(systemName: "book.fill").foregroundColor(.white).font(.headline)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(subject.title).font(.title3).fontWeight(.bold).foregroundColor(.white).lineLimit(1)
                    Text(subject.courseTeacher).font(.subheadline).fontWeight(.medium).foregroundColor(.white.opacity(0.9)).lineLimit(1)
                }
                Spacer()
                if let grade = subject.currentGrade {
                    VStack(spacing: 0) {
                        Text(String(format: "%.1f", grade)).font(.headline).fontWeight(.black)
                        Text("AVG").font(.system(size: 8, weight: .bold))
                    }
                    .foregroundColor(color)
                    .padding(8)
                    .background(Color.white)
                    .cornerRadius(8)
                }
            }
            Divider().background(Color.white.opacity(0.3))
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                    Text(subject.courseDaysString.isEmpty ? "TBA" : subject.courseDaysString)
                }
                Text("•").foregroundColor(.white.opacity(0.5))
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                    Text(subject.courseTimeString)
                }
            }
            .font(.subheadline).fontWeight(.medium).foregroundColor(.white)
            
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                    Text(subject.courseClassroom.isEmpty ? "No Room" : subject.courseClassroom)
                }
                .font(.caption).foregroundColor(.white.opacity(0.9))
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "person.3.fill")
                    Text("\(Int(subject.attendanceRate * 100))%")
                }
                .font(.caption).fontWeight(.bold)
                .padding(.vertical, 4).padding(.horizontal, 8)
                .background(Color.black.opacity(0.2))
                .foregroundColor(.white)
                .cornerRadius(6)
            }
        }
        .padding(16)
        .background(color)
        .cornerRadius(20)
        .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

// MARK: - STANDARD COMPONENTS

struct StandardDayChip: View {
    let day: String; let isSelected: Bool; let action: () -> Void
    let day: String
    let isSelected: Bool
    let action: () -> Void
    
var body: some View {
Button(action: action) {
            Text(day).font(.caption).fontWeight(.medium).foregroundColor(isSelected ? .white : .primary)
                .frame(height: 32).frame(maxWidth: .infinity)
                .background(isSelected ? Color.blue : Color(.systemGray6)).cornerRadius(8)
        }.buttonStyle(PlainButtonStyle())
            Text(day)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .frame(height: 32)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
}
}

struct StatBox: View {
    let title: String; let value: String
    let title: String
    let value: String
@Environment(\.colorScheme) var colorScheme
    
var body: some View {
VStack(spacing: 8) {
            Text(value).font(.title2).fontWeight(.bold).foregroundColor(.themePrimary)
            Text(title).font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center).minimumScaleFactor(0.8)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.themePrimary)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
}
        .frame(maxWidth: .infinity).frame(height: 90).padding(.horizontal, 4)
        .background(Color.themeSurface).cornerRadius(12)
        .frame(maxWidth: .infinity)
        .frame(height: 90)
        .padding(.horizontal, 4)
        .background(Color.themeSurface)
        .cornerRadius(12)
.overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.adaptiveBorder.opacity(0.3), lineWidth: 1))
}
}

struct DetailInfoCard: View {
    let icon: String; let title: String; let value: String
    let icon: String
    let title: String
    let value: String
    
var body: some View {
VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) { Image(systemName: icon).font(.caption).foregroundColor(.themePrimary).frame(width: 16); Text(title).font(.caption).fontWeight(.medium).foregroundColor(.themeTextSecondary) }
            Text(value).font(.subheadline).fontWeight(.medium).foregroundColor(.themeTextPrimary).lineLimit(2).minimumScaleFactor(0.8)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(12).background(Color.adaptiveTertiaryBackground).cornerRadius(10)
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.themePrimary)
                    .frame(width: 16)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.themeTextSecondary)
            }
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.themeTextPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.adaptiveTertiaryBackground)
        .cornerRadius(10)
}
}

struct SectionHeader: View {
    let title: String; let icon: String
    var body: some View { HStack(spacing: 8) { Image(systemName: icon).font(.system(size: 14, weight: .medium)).foregroundColor(.themePrimary); Text(title).font(.headline).fontWeight(.semibold).foregroundColor(.themeTextPrimary); Spacer() } }
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.themePrimary)
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.themeTextPrimary)
            Spacer()
        }
    }
}

struct ActionButton: View {
    let icon: String; let title: String; let subtitle: String; let color: Color; let action: () -> Void
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
var body: some View {
Button(action: action) {
VStack(spacing: 8) {
                Image(systemName: icon).font(.title2).foregroundColor(color)
                Text(title).font(.caption).fontWeight(.medium).foregroundColor(.themeTextPrimary).multilineTextAlignment(.center)
                Text(subtitle).font(.caption2).foregroundColor(.themeTextSecondary).multilineTextAlignment(.center)
            }.frame(maxWidth: .infinity).padding().background(color.opacity(0.1)).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.3), lineWidth: 1))
        }.buttonStyle(PlainButtonStyle())
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.themeTextPrimary)
                    .multilineTextAlignment(.center)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.themeTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
}
}

struct PerformanceCard: View {
    let title: String; let value: String; let subtitle: String; let color: Color; let icon: String; let progress: Double; var trendIcon: String? = nil; var trendColor: Color? = nil
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    let progress: Double
    var trendIcon: String? = nil
    var trendColor: Color? = nil
    
var body: some View {
VStack(alignment: .leading, spacing: 12) {
HStack {
                Image(systemName: icon).font(.system(size: 16)).foregroundColor(color)
                Text(title).font(.subheadline).fontWeight(.medium).foregroundColor(.themeTextSecondary); Spacer()
                if let tIcon = trendIcon, let tColor = trendColor { Image(systemName: tIcon).font(.system(size: 14)).foregroundColor(tColor) }
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.themeTextSecondary)
                Spacer()
                if let tIcon = trendIcon, let tColor = trendColor {
                    Image(systemName: tIcon)
                        .font(.system(size: 14))
                        .foregroundColor(tColor)
                }
}
            Text(value).font(.title2).fontWeight(.bold).foregroundColor(.themeTextPrimary); Text(subtitle).font(.caption).foregroundColor(.themeTextSecondary)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.themeTextPrimary)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.themeTextSecondary)
            
GeometryReader { geo in
                ZStack(alignment: .leading) { Rectangle().fill(Color.adaptiveTertiaryBackground).frame(height: 4); Rectangle().fill(color).frame(width: geo.size.width * progress, height: 4) }
            }.frame(height: 4)
        }.padding().background(Color.themeSurface).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.adaptiveTertiaryBackground, lineWidth: 1))
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.adaptiveTertiaryBackground)
                        .frame(height: 4)
                    Rectangle()
                        .fill(color)
                        .frame(width: geo.size.width * progress, height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding()
        .background(Color.themeSurface)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.adaptiveTertiaryBackground, lineWidth: 1))
    }
}

struct SubjectCard: View {
    let subject: Subject
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(subject.title).font(.title2).fontWeight(.bold).foregroundColor(.themeTextPrimary)
                    Text(subject.courseTeacher).font(.subheadline).foregroundColor(.themeTextSecondary)
                }
                Spacer()
                if let grade = subject.currentGrade { GradeBadge(grade: grade) }
            }
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(icon: "clock", text: "\(subject.courseDaysString) \(subject.courseTimeString)")
                InfoRow(icon: "mappin.circle", text: subject.courseClassroom)
            }
            HStack(spacing: 12) {
                StatPill(icon: "checkmark.circle", value: "\(subject.attendedClasses)", label: "Present")
                StatPill(icon: "xmark.circle", value: "\(subject.totalClasses - subject.attendedClasses)", label: "Absent")
                StatPill(icon: "star", value: "\(subject.gradeHistory?.count ?? 0)", label: "Grades")
            }
        }
        .padding()
        .background(Color.themeSurface)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.adaptiveBorder.opacity(0.3), lineWidth: 1))
    }
}

struct StatPill: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.caption2).foregroundColor(.themeTextSecondary)
                Text(value).font(.caption).fontWeight(.semibold).foregroundColor(.themeTextPrimary)
            }
            Text(label).font(.caption2).foregroundColor(.themeTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.adaptiveTertiaryBackground)
        .cornerRadius(8)
    }
}

struct GradeBadge: View {
    let grade: Double
    private var gradeColor: Color {
        switch grade {
        case 9...10: return .themeSuccess
        case 7..<9: return .themePrimary
        case 5..<7: return .themeWarning;
        default: return .themeError
        }
    }
    var body: some View {
        VStack(spacing: 2) {
            Text(String(format: "%.1f", grade)).font(.system(size: 16, weight: .bold)).foregroundColor(.white)
            Text("/10").font(.system(size: 10, weight: .medium)).foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 8).padding(.vertical, 4).background(gradeColor).cornerRadius(8)
    }
}

struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.caption).foregroundColor(.themeTextSecondary).frame(width: 16)
            Text(text).font(.subheadline).foregroundColor(.themeTextPrimary)
            Spacer()
        }
}
}

// MARK: - ARCADE COMPONENTS

struct ArcadeSection<Content: View>: View {
    let title: String; let color: Color; let content: Content
    init(title: String, color: Color, @ViewBuilder content: () -> Content) { self.title = title; self.color = color; self.content = content() }
    let title: String
    let color: Color
    let content: Content
    
    init(title: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.color = color
        self.content = content()
    }
    
var body: some View {
VStack(alignment: .leading, spacing: 12) {
Text(title).font(.caption).fontWeight(.black).foregroundColor(color)
            VStack(spacing: 12) { content }.padding().background(Color(white: 0.1)).cornerRadius(16).overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.3), lineWidth: 1))
            VStack(spacing: 12) {
                content
            }
            .padding()
            .background(Color(white: 0.1))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.3), lineWidth: 1))
}
}
}

struct ArcadeInput: View {
    let icon: String; let placeholder: String; @Binding var text: String
    var body: some View { HStack { Image(systemName: icon).foregroundColor(.gray); TextField(placeholder, text: $text).foregroundColor(.white) }.padding(10).background(Color.black).cornerRadius(8) }
    let icon: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(.gray)
            TextField(placeholder, text: $text).foregroundColor(.white)
        }
        .padding(10)
        .background(Color.black)
        .cornerRadius(8)
    }
}

struct ArcadeDayChip: View {
    let label: String; let isSelected: Bool; let color: Color; let action: () -> Void
    let label: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
var body: some View {
Button(action: action) {
            Text(label).font(.caption).fontWeight(.bold).frame(width: 30, height: 30)
                .background(isSelected ? color : Color.black).foregroundColor(isSelected ? .white : .gray).cornerRadius(15).overlay(Circle().stroke(isSelected ? .white : color.opacity(0.5), lineWidth: 1))
            Text(label)
                .font(.caption)
                .fontWeight(.bold)
                .frame(width: 30, height: 30)
                .background(isSelected ? color : Color.black)
                .foregroundColor(isSelected ? .white : .gray)
                .cornerRadius(15)
                .overlay(Circle().stroke(isSelected ? .white : color.opacity(0.5), lineWidth: 1))
}
}
}

struct ArcadeStatPill: View {
    let icon: String; let value: String; let label: String; let gradient: Gradient
    let icon: String
    let value: String
    let label: String
    let gradient: Gradient
    
var body: some View {
HStack(spacing: 8) {
ZStack {
                Circle().fill(LinearGradient(gradient: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 36, height: 36).shadow(color: Color(uiColor: UIColor(gradient.stops.first!.color)).opacity(0.4), radius: 5)
                Circle()
                    .fill(LinearGradient(gradient: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 36, height: 36)
                    .shadow(color: Color(uiColor: UIColor(gradient.stops.first!.color)).opacity(0.4), radius: 5)
Image(systemName: icon).font(.system(size: 16, weight: .bold)).foregroundColor(.white)
}
VStack(alignment: .leading, spacing: 0) {
@@ -281,71 +577,101 @@ struct ArcadeStatPill: View {
}

struct ArcadeActionButton: View {
    let icon: String; let label: String; let color: Color; let action: () -> Void
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
var body: some View {
Button(action: action) {
            VStack { Image(systemName: icon).font(.headline); Text(label).font(.system(size: 8, weight: .black)) }
            .frame(maxWidth: .infinity).padding(.vertical, 12).background(color.opacity(0.2)).foregroundColor(color).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(color, lineWidth: 1))
            VStack {
                Image(systemName: icon).font(.headline)
                Text(label).font(.system(size: 8, weight: .black))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(color, lineWidth: 1))
}
}
}

struct ArcadeInfoCell: View {
    let label: String; let value: String; let icon: String
    let label: String
    let value: String
    let icon: String
    
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
            HStack {
                Image(systemName: icon).font(.caption).foregroundColor(.cyan)
                Text(value.isEmpty ? "N/A" : value).font(.caption).fontWeight(.bold).foregroundColor(.white).lineLimit(1)
            }
}
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(white: 0.1))
        .cornerRadius(12)
}
}

struct RetroStatCard: View {
    let label: String; let value: String; let color: Color
struct ArcadeSubjectCard: View {
    let subject: Subject
    
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle().fill(Color.purple.opacity(0.2)).frame(width: 40, height: 40)
                    Image(systemName: "bolt.fill").foregroundColor(.purple)
                }
                Spacer()
                Text("LVL \(Int(subject.attendanceRate * 10))")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.black)
                    .foregroundColor(.white)
                    .padding(4)
                    .background(Color.purple.opacity(0.2))
                    .cornerRadius(4)
            }
            Text(subject.title)
                .font(.system(.headline, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            Spacer()
            HStack {
                if let grade = subject.currentGrade {
                    Text(String(format: "%.1f", grade))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                } else {
                    Text("-.-").font(.caption).foregroundColor(.gray)
                }
                Spacer()
                Text("\(Int(subject.attendanceRate * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1))
                    Capsule().fill(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)).frame(width: geo.size.width * subject.attendanceRate)
                }
            }
            .frame(height: 6)
}
        .padding()
        .frame(height: 160)
        .background(Color(white: 0.1))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.05), lineWidth: 1))
        .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 5)
}
}
