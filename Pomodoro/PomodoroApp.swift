import SwiftUI

@main
struct PomodoroApp: App {
    @State private var model = TimerModel()

    var body: some Scene {
        MenuBarExtra {
            ContentView(model: model)
        } label: {
            Text(model.menuBarTitle)
        }
        .menuBarExtraStyle(.window)
        .defaultSize(width: 280, height: 200)
        .onChange(of: model.phase) {}
    }

    init() {
        NotificationManager.shared.requestPermission()
        // Wire up notification callback after model is created
        let notificationManager = NotificationManager.shared
        _model = State(initialValue: {
            let m = TimerModel()
            m.onPhaseComplete = { phase in
                notificationManager.sendNotification(for: phase)
            }
            return m
        }())
    }
}
