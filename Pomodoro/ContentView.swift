import SwiftUI

struct ContentView: View {
    @Bindable var model: TimerModel
    @State private var reflection: String = ""
    @State private var showingSettings: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            if model.awaitingReflection {
                reflectionView
            } else {
                timerView
            }

            if showingSettings {
                settingsView
            }

            Divider()

            HStack {
                Button(showingSettings ? "Hide Settings" : "Settings") {
                    showingSettings.toggle()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .font(.caption)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .font(.caption)
            }
        }
        .padding(20)
        .frame(width: 280)
    }

    private var timerView: some View {
        VStack(spacing: 16) {
            Text(model.phase.rawValue)
                .font(.headline)
                .foregroundStyle(phaseColor)

            if model.phase == .idle {
                TextField("What will you work on?", text: $model.currentTask)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { startWithLog() }
            }

            Text(model.displayTime)
                .font(.system(size: 48, weight: .medium, design: .monospaced))

            if model.phase != .idle, !model.currentTask.isEmpty {
                Text(model.currentTask)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            HStack(spacing: 12) {
                switch model.phase {
                case .idle:
                    Button("Start") { startWithLog() }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .disabled(model.currentTask.trimmingCharacters(in: .whitespaces).isEmpty)

                case .working, .onBreak:
                    if model.isPaused {
                        Button("Resume") { model.resume() }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                    } else {
                        Button("Pause") { model.pause() }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                    }
                    Button("Reset") { model.reset() }
                        .buttonStyle(.bordered)
                }
            }
        }
    }

    private var reflectionView: some View {
        VStack(spacing: 12) {
            Text("Time's up!")
                .font(.headline)
                .foregroundStyle(.red)

            if !model.currentTask.isEmpty {
                Text(model.currentTask)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            TextField("What did you accomplish?", text: $reflection)
                .textFieldStyle(.roundedBorder)
                .onSubmit { saveReflectionAndStartBreak() }

            HStack(spacing: 12) {
                Button("Save") { saveReflectionAndStartBreak() }
                    .buttonStyle(.borderedProminent)
                    .disabled(reflection.trimmingCharacters(in: .whitespaces).isEmpty)

                Button("Skip") {
                    reflection = ""
                    model.startBreak()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func startWithLog() {
        let note = model.currentTask.trimmingCharacters(in: .whitespaces)
        guard !note.isEmpty else { return }
        let entry = PomodoroEntry(
            date: Date(),
            duration: 25,
            note: note
        )
        PomodoroLog.shared.save(entry)
        model.start()
    }

    private func saveReflectionAndStartBreak() {
        let text = reflection.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        PomodoroLog.shared.updateLastReflection(text)
        reflection = ""
        model.startBreak()
    }

    private var settingsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Log file")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Text(PomodoroLog.shared.filePath)
                    .font(.system(size: 11, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button("Change...") { chooseLogFile() }
                    .font(.caption)
            }
        }
        .padding(.top, 4)
    }

    private func chooseLogFile() {
        let panel = NSSavePanel()
        panel.title = "Choose log file location"
        panel.nameFieldStringValue = URL(fileURLWithPath: PomodoroLog.shared.filePath).lastPathComponent
        panel.allowedContentTypes = [.json]
        panel.directoryURL = URL(fileURLWithPath: PomodoroLog.shared.filePath).deletingLastPathComponent()
        if panel.runModal() == .OK, let url = panel.url {
            PomodoroLog.shared.filePath = url.path
        }
    }

    private var phaseColor: Color {
        switch model.phase {
        case .idle: return .secondary
        case .working: return .red
        case .onBreak: return .green
        }
    }
}
