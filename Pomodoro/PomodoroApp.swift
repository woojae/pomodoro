import SwiftUI
import AppKit
import os

@main
struct PomodoroApp: App {
    @State private var model = TimerModel()
    @State private var isInserted = true
    private let logger = Logger(subsystem: "com.local.pomodoro", category: "menubar")

    var body: some Scene {
        MenuBarExtra(isInserted: $isInserted) {
            ContentView(model: model)
        } label: {
            Text(model.menuBarTitle)
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)) { _ in
                    reinsert(reason: "screen change")
                }
                .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didWakeNotification)) { _ in
                    reinsert(reason: "wake")
                }
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
                if phase == .working {
                    PomodoroLog.shared.completed(minutes: TimerModel.workMinutes)
                }
                notificationManager.sendNotification(for: phase)
            }
            return m
        }())
    }

    /// macOS can drop the status item when displays change; toggling re-creates it.
    private func reinsert(reason: String) {
        logger.info("Reinserting menu bar item: \(reason, privacy: .public)")
        isInserted = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { isInserted = true }
    }
}
