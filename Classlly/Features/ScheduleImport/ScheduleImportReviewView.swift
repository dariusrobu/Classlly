import SwiftUI
import SwiftData

struct ScheduleImportReviewView: View {
    @State var candidates: [ScannedClassCandidate]
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    var body: some View {
        NavigationView {
            List {
                if candidates.isEmpty {
                    Text("No classes detected. Please try a clearer image.")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach($candidates) { $candidate in
                        ClassEditorRow(candidate: $candidate)
                    }
                    .onDelete { indexSet in
                        candidates.remove(atOffsets: indexSet)
                    }
                }
            }
            .navigationTitle("Review Classes")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Import \(candidates.filter{$0.isSelected}.count)") {
                        saveToSchedule()
                    }
                    .fontWeight(.bold)
                    .disabled(candidates.filter{$0.isSelected}.isEmpty)
                }
            }
        }
    }
    
    private func saveToSchedule() {
        let selected = candidates.filter { $0.isSelected }
        
        for item in selected {
            // Convert 'Day String' to weekday Int (1=Sun, 2=Mon...)
            let weekday = dayStringToInt(item.day)
            
            // Parse frequency logic based on weekRestriction string
            var cFreq: ClassFrequency = .weekly
            var sFreq: ClassFrequency = .weekly
            
            let restriction = item.weekRestriction.lowercased()
            if restriction.contains("odd") || restriction.contains("impar") {
                cFreq = .biweeklyOdd; sFreq = .biweeklyOdd
            } else if restriction.contains("even") || restriction.contains("par") {
                cFreq = .biweeklyEven; sFreq = .biweeklyEven
            }
            
            let newSubject = Subject(
                title: item.title,
                courseTeacher: item.type == .course ? item.teacher : "",
                courseClassroom: item.type == .course ? item.room : "",
                courseStartTime: item.startTime,
                courseEndTime: item.endTime,
                courseDays: item.type == .course ? [weekday] : [],
                courseFrequency: cFreq,
                seminarTeacher: item.type != .course ? item.teacher : "",
                seminarClassroom: item.type != .course ? item.room : "",
                seminarStartTime: item.type != .course ? item.startTime : Date(),
                seminarEndTime: item.type != .course ? item.endTime : Date(),
                seminarDays: item.type != .course ? [weekday] : [],
                seminarFrequency: sFreq
            )
            
            modelContext.insert(newSubject)
        }
        
        dismiss()
    }
    
    private func dayStringToInt(_ day: String) -> Int {
        let d = day.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // English Checks
        if d.starts(with: "mon") { return 2 }
        if d.starts(with: "tue") { return 3 }
        if d.starts(with: "wed") { return 4 }
        if d.starts(with: "thu") { return 5 }
        if d.starts(with: "fri") { return 6 }
        if d.starts(with: "sat") { return 7 }
        if d.starts(with: "sun") { return 1 }
        
        // Romanian Checks
        if d.starts(with: "lun") { return 2 } // Luni
        if d.starts(with: "mar") { return 3 } // Marti
        if d.starts(with: "mie") { return 4 } // Miercuri
        if d.starts(with: "joi") { return 5 } // Joi
        if d.starts(with: "vin") { return 6 } // Vineri
        if d.starts(with: "sam") { return 7 } // Sambata
        if d.starts(with: "dum") { return 1 } // Duminica
        
        return 2 // Default to Monday if unknown
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
                            .fontWeight(.medium)
                        Text("•")
                        Text(candidate.timeString)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Type Badge
                Text(candidate.type.rawValue.prefix(1))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(candidate.type.color)
                    .clipShape(Circle())
                
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
                        TextField("e.g. Odd, Even", text: $candidate.weekRestriction)
                    }
                }
                .font(.subheadline)
            }
        }
        .padding(.vertical, 8)
        .opacity(candidate.isSelected ? 1.0 : 0.5)
    }
}
