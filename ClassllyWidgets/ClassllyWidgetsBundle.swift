import WidgetKit
import SwiftUI

@main
struct ClassllyWidgetsBundle: WidgetBundle {
    var body: some Widget {
        // 1. Grade Velocity Widget (Sparkline)
        GradeVelocityWidget()
        
        // 2. Attendance Check-In Widget (Interactive)
        AttendanceCheckInWidget()
        
        // 3. Next Task Widget (Ring)
        NextTaskWidget()
        
        // 4. Lock Screen Widget (Glance)
        LockScreenWidget()
    }
}
