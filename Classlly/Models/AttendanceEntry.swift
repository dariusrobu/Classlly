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
    var id: UUID
    var date: Date
    var status: AttendanceStatus
    var note: String?
    
    // Inverse relationship
    var subject: Subject?

    init(date: Date = Date(), status: AttendanceStatus, note: String? = nil) {
        self.id = UUID()
        self.date = date
        self.status = status
        self.note = note
    }
}