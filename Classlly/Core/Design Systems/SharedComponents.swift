import SwiftUI

// MARK: - Subject Cards

struct RainbowSubjectCard: View {
    let subject: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(subject)
                .font(.headline)
                .foregroundColor(.white)
            Spacer()
        }
        .padding()
        .frame(height: 120)
        .background(color)
        .cornerRadius(12)
    }
}

struct SubjectCard: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(title)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct ArcadeSubjectCard: View {
    let title: String
    let score: Int
    
    var body: some View {
        VStack {
            Text(title).bold()
            Text("Score: \(score)").font(.caption)
        }
        .padding()
        .background(Color.black)
        .foregroundColor(.green)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.green, lineWidth: 2)
        )
    }
}

// MARK: - Badges & Pills

struct StatPill: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(value).font(.headline)
            Text(title).font(.caption).foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
}

struct GradeBadge: View {
    let grade: String
    
    var body: some View {
        Text(grade)
            .font(.caption)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.green.opacity(0.2))
            .foregroundColor(.green)
            .cornerRadius(4)
    }
}

// MARK: - Layout Helpers

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(value).fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}
