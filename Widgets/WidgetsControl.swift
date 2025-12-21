import AppIntents
import SwiftUI
import WidgetKit

// ⚠️ NOTICE: Control Widgets are an iOS 18+ feature.
// Since you are targeting iOS 17 and experiencing type-missing errors,
// this code is temporarily disabled to allow the rest of your app to build.
//
// Change '#if false' to '#if true' when you are ready to debug iOS 18 features.

#if false

@available(iOS 18.0, *)
struct WidgetsControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: "com.classlly.WidgetsControl",
            provider: Provider()
        ) { entry in
            ControlWidgetToggle(
                "Study Timer",
                isOn: entry.isRunning,
                action: ToggleTimerIntent()
            ) { isRunning in
                Label(isRunning ? "Stop Timer" : "Start Timer", systemImage: isRunning ? "stop.fill" : "play.fill")
            }
        }
        .displayName("Study Timer")
        .description("Quickly start or stop your study session.")
    }
}

@available(iOS 18.0, *)
extension WidgetsControl {
    struct Provider: ControlValueProvider {
        typealias Value = TimerEntry
        
        func previewValue(configuration: ControlValueProviderConfiguration<Provider>) -> TimerEntry {
            TimerEntry(isRunning: false)
        }
        
        func currentValue(configuration: ControlValueProviderConfiguration<Provider>) async throws -> TimerEntry {
            let isRunning = UserDefaults(suiteName: "group.com.classlly")?.bool(forKey: "isTimerRunning") ?? false
            return TimerEntry(isRunning: isRunning)
        }
    }
    
    struct TimerEntry: TimelineEntry {
        var date: Date = Date()
        var isRunning: Bool
    }
}

@available(iOS 18.0, *)
struct ToggleTimerIntent: SetValueIntent {
    static var title: LocalizedStringResource = "Toggle Study Timer"
    
    @Parameter(title: "Running")
    var value: Bool
    
    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: "group.com.classlly")
        defaults?.set(value, forKey: "isTimerRunning")
        return .result()
    }
}

#endif
