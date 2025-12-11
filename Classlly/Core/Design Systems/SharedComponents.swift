import SwiftUI

// MARK: - Rainbow Components

struct RainbowContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(Color(red: 0.1, green: 0.1, blue: 0.12)) // Dark Card
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}

struct RainbowStatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        RainbowContainer {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                    Spacer()
                }
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Standard Components

struct StatBox: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Subject Cards

struct RainbowSubjectCard: View {
    let subject: Subject
    let color: Color
    
    var body: some View {
        RainbowContainer {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(subject.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(subject.courseTeacher)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(color)
            }
        }
    }
}

struct SubjectCard: View {
    let subject: Subject
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(subject.title).font(.headline)
            Text(subject.courseTeacher).font(.subheadline).foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct ArcadeSubjectCard: View {
    let subject: Subject
    
    var body: some View {
        VStack {
            Text(subject.title).bold().foregroundColor(.green)
            Text("Score: 1000").font(.caption).foregroundColor(.gray)
        }
        .padding()
        .background(Color.black)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.green, lineWidth: 1))
    }
}

// MARK: - Arcade Components

struct ArcadeStatPill: View {
    let icon: String
    let value: String
    let label: String
    let gradient: Gradient
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.caption2)
                Text(value).font(.headline).fontWeight(.black)
            }
            Text(label).font(.caption2).fontWeight(.bold)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(LinearGradient(gradient: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
        .foregroundColor(.white)
        .cornerRadius(20)
    }
}

struct ArcadeActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon).font(.title2)
                Text(label).font(.system(size: 8, weight: .black))
            }
            .foregroundColor(color)
            .frame(width: 60, height: 60)
            .background(Color.black)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(color, lineWidth: 1))
        }
    }
}

struct ArcadeInfoCell: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(.cyan)
            VStack(alignment: .leading) {
                Text(label).font(.caption).fontWeight(.black).foregroundColor(.gray)
                Text(value).font(.caption).fontWeight(.bold).foregroundColor(.white)
            }
            Spacer()
        }
        .padding()
        .background(Color(white: 0.1))
        .cornerRadius(12)
    }
}

struct ArcadeInput: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(.purple)
            TextField(placeholder, text: $text)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color(white: 0.1))
        .cornerRadius(12)
    }
}

struct ArcadeDayChip: View {
    let label: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .fontWeight(.bold)
                .frame(width: 30, height: 30)
                .background(isSelected ? color : Color(white: 0.1))
                .foregroundColor(isSelected ? .white : .gray)
                .clipShape(Circle())
        }
    }
}

struct ArcadeSection<Content: View>: View {
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
            content
        }
        .padding()
        .background(Color.black)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.3), lineWidth: 1))
    }
}

struct StandardDayChip: View {
    let day: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(day)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
    }
}

// Rainbow Header Helper
struct RainbowHeader: View {
    let title: String
    let accentColor: Color
    let showBackButton: Bool
    let backAction: (() -> Void)?
    let trailingIcon: String?
    let trailingAction: (() -> Void)?
    
    var body: some View {
        HStack {
            if showBackButton {
                Button(action: { backAction?() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            
            Text(title)
                .font(.largeTitle)
                .fontWeight(.black)
                .foregroundColor(accentColor)
            
            Spacer()
            
            if let icon = trailingIcon, let action = trailingAction {
                Button(action: action) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        .padding()
        .background(Color.black)
    }
}

// Detail Info Card Helper
struct DetailInfoCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(value.isEmpty ? "Not set" : value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(title)
        }
        .font(.headline)
        .foregroundColor(.primary)
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 80, height: 80)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
    }
}

struct PerformanceCard: View {
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
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
                if let tIcon = trendIcon, let tColor = trendColor {
                    Image(systemName: tIcon)
                        .foregroundColor(tColor)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progress, total: 1.0)
                .tint(color)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}
