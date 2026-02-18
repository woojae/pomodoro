import SwiftUI
import UniformTypeIdentifiers

enum Tab {
    case timer, settings
}

struct ContentView: View {
    @Bindable var model: TimerModel
    @State private var reflection: String = ""
    @State private var comment: String = ""
    @State private var recentNotes: [String] = []
    @State private var selectedTab: Tab = .timer

    var body: some View {
        VStack(spacing: 12) {
            switch selectedTab {
            case .timer:
                if model.awaitingReflection {
                    reflectionView
                } else {
                    timerView
                }
            case .settings:
                settingsView
            }

            Divider()

            HStack {
                Button {
                    selectedTab = .timer
                } label: {
                    Image(systemName: "timer")
                        .foregroundStyle(selectedTab == .timer ? .primary : .secondary)
                }
                .buttonStyle(.plain)

                Button {
                    selectedTab = .settings
                } label: {
                    Image(systemName: "gear")
                        .foregroundStyle(selectedTab == .settings ? .primary : .secondary)
                }
                .buttonStyle(.plain)

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

    // MARK: - Timer View

    private var timerView: some View {
        VStack(spacing: 12) {
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

            if model.phase == .working {
                noteInputView
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

    // MARK: - Note Input

    private var noteInputView: some View {
        VStack(spacing: 6) {
            if !recentNotes.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(recentNotes, id: \.self) { n in
                        Text("- \(n)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 8) {
                TextField("Add a note...", text: $comment)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
                    .onSubmit { addNote() }

                Button("Add") { addNote() }
                    .font(.caption)
                    .disabled(comment.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private func addNote() {
        let text = comment.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        PomodoroLog.shared.note(text)
        recentNotes.append(text)
        comment = ""
    }

    // MARK: - Reflection View

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

            if !recentNotes.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(recentNotes, id: \.self) { n in
                        Text("- \(n)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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
                    recentNotes = []
                    model.startBreak()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    // MARK: - Settings View

    private var settingsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                Text("Log file location")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(PomodoroLog.shared.filePath)
                    .font(.system(size: 11, design: .monospaced))
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button("Change...") { chooseLogFile() }
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Actions

    private func startWithLog() {
        let task = model.currentTask.trimmingCharacters(in: .whitespaces)
        guard !task.isEmpty else { return }
        PomodoroLog.shared.start(task)
        recentNotes = []
        model.start()
    }

    private func saveReflectionAndStartBreak() {
        let text = reflection.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        PomodoroLog.shared.done(text)
        reflection = ""
        recentNotes = []
        model.startBreak()
    }

    private func chooseLogFile() {
        let panel = NSSavePanel()
        panel.title = "Choose log file location"
        panel.nameFieldStringValue = URL(fileURLWithPath: PomodoroLog.shared.filePath).lastPathComponent
        panel.allowedContentTypes = [UTType(filenameExtension: "log") ?? .plainText]
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
