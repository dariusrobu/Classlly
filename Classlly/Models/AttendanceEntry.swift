//
//  AttendanceStatus.swift
//  Classlly
//
//  Created by Robu Darius on 17.12.2025.
//

import Foundation
import SwiftData

enum AttendanceStatus: String, Codable, CaseIterable {
    case present = "Present"
    case absent = "Absent"
    case late = "Late"
    case excused = "Excused"
}

@Model
final class AttendanceEntry {
    var id: UUID = UUID()
    var date: Date = Date()
    
    // Store as Raw String to avoid SwiftData Macro bugs with Enums
    var statusRaw: String = AttendanceStatus.present.rawValue
    
    var note: String? = nil
    
    // Inverse relationship
    var subject: Subject?

    // Computed property for easy access
    @Transient var status: AttendanceStatus {
        get { AttendanceStatus(rawValue: statusRaw) ?? .present }
        set { statusRaw = newValue.rawValue }
    }

    init(date: Date = Date(), status: AttendanceStatus = .present, note: String? = nil) {
        self.id = UUID()
        self.date = date
        self.statusRaw = status.rawValue
        self.note = note
    }
}
