import SwiftUI
import SwiftData

struct ScheduleImportReviewView: View {
    @State var candidates: [ScannedClassCandidate]
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    var body: some View {
        NavigationView {
            List {
                ForEach($candidates) { $candidate in
                    ClassEditorRow(candidate: $candidate)
                }
                .onDelete { indexSet in
                    candidates.remove(atOffsets: indexSet)
                }
            }
            .navigationTitle("Review Classes")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Import All") {
                        saveToSchedule()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
    
    private func saveToSchedule() {
        let selected = candidates.filter { $0.isSelected }
        
        for item in selected {
            // Convert 'Day String' to weekday Int (1=Sun, 2=Mon...)
            let weekday = dayStringToInt(item.day)
            
            let newSubject = Subject(
                title: item.title,
                courseTeacher: item.type == .course ? item.teacher : "",
                courseClassroom: item.type == .course ? item.room : "",
                courseStartTime: item.startTime,
                courseEndTime: item.endTime,
                courseDays: item.type == .course ? [weekday] : [],
                seminarTeacher: item.type != .course ? item.teacher : "",
                seminarClassroom: item.type != .course ? item.room : "",
                seminarStartTime: item.type != .course ? item.startTime : Date(),
                seminarEndTime: item.type != .course ? item.endTime : Date(),
                seminarDays: item.type != .course ? [weekday] : []
            )
            
            // Save logic
            modelContext.insert(newSubject)
        }
        
        dismiss()
    }
    
    private func dayStringToInt(_ day: String) -> Int {
        // Simple mapper
        switch day.prefix(3).lowercased() {
        case "mon": return 2
        case "tue": return 3
        case "wed": return 4
        case "thu": return 5
        case "fri": return 6
        case "sat": return 7
        case "sun": return 1
        default: return 2 // Default Mon
        }
    }
}

// MARK: - Editor Row
struct ClassEditorRow: View {
    @Binding var candidate: ScannedClassCandidate
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header Row (Always Visible)
            HStack {
                Toggle("", isOn: $candidate.isSelected)
                    .labelsHidden()
                
                VStack(alignment: .leading) {
                    TextField("Subject Name", text: $candidate.title)
                        .font(.headline)
                    
                    HStack {
                        Text(candidate.day)
                            .foregroundColor(.blue)
                        Text("•")
                        Text(candidate.timeString)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if candidate.hasConflict {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                }
                
                Button(action: { withAnimation { isExpanded.toggle() }}) {
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
            }
            
            // Expanded Details
            if isExpanded {
                Divider()
                
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 12) {
                    GridRow {
                        Text("Room").font(.caption).foregroundColor(.gray)
                        TextField("Room", text: $candidate.room)
                    }
                    GridRow {
                        Text("Teacher").font(.caption).foregroundColor(.gray)
                        TextField("Teacher Name", text: $candidate.teacher)
                    }
                    GridRow {
                        Text("Type").font(.caption).foregroundColor(.gray)
                        Picker("Type", selection: $candidate.type) {
                            ForEach(ClassType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .labelsHidden()
                    }
                    GridRow {
                        Text("Weeks").font(.caption).foregroundColor(.gray)
                        TextField("e.g. Odd, S1", text: $candidate.weekRestriction)
                    }
                }
                .font(.subheadline)
                
                Toggle("Optional Class", isOn: $candidate.isOptional)
                    .font(.caption)
                    .tint(.blue)
            }
        }
        .padding(.vertical, 8)
    }
}
