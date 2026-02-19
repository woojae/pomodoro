import SwiftUI
import UniformTypeIdentifiers

enum Tab {
    case timer, settings
}

// MARK: - Theme

private enum Theme {
    // Background gradient
    static let bgTop = Color(red: 0.78, green: 0.22, blue: 0.18)
    static let bgBottom = Color(red: 0.62, green: 0.15, blue: 0.13)
    static let toolbarBg = Color.black.opacity(0.15)

    // Foreground
    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.70)
    static let dimText = Color.white.opacity(0.45)

    // Accents
    static let warmGreen = Color(red: 0.40, green: 0.85, blue: 0.55)
    static let warmBlue = Color(red: 0.55, green: 0.78, blue: 1.0)
    static let warmOrange = Color(red: 1.0, green: 0.75, blue: 0.35)
    static let warmGray = Color.white.opacity(0.6)

    // Elements
    static let ringTrack = Color.white.opacity(0.15)
    static let cardBg = Color.white.opacity(0.10)
    static let buttonBg = Color.white
    static let buttonText = Color(red: 0.72, green: 0.18, blue: 0.15)
}

// MARK: - Main View

struct ContentView: View {
    @Bindable var model: TimerModel
    @State private var reflection: String = ""
    @State private var comment: String = ""
    @State private var recentNotes: [String] = []
    @State private var selectedTab: Tab = .timer

    var body: some View {
        VStack(spacing: 0) {
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

            toolbar
        }
        .frame(width: 300)
        .background(
            LinearGradient(
                colors: [Theme.bgTop, Theme.bgBottom],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 2) {
            toolbarButton(icon: "timer", isActive: selectedTab == .timer) {
                selectedTab = .timer
            }
            toolbarButton(icon: "gear", isActive: selectedTab == .settings) {
                selectedTab = .settings
            }

            Spacer()

            toolbarButton(icon: "xmark.circle", isActive: false) {
                NSApplication.shared.terminate(nil)
            }
            .help("Quit Pomodoro")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Theme.toolbarBg)
    }

    private func toolbarButton(icon: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isActive ? Theme.primaryText : Theme.dimText)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Timer View

    private var timerView: some View {
        VStack(spacing: 20) {
            if model.phase == .idle {
                idleView
            } else {
                activeTimerView
            }
        }
        .padding(24)
    }

    private var idleView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Theme.ringTrack, lineWidth: 6)
                    .frame(width: 140, height: 140)

                VStack(spacing: 4) {
                    Text("25:00")
                        .font(.system(size: 36, weight: .light, design: .rounded))
                        .foregroundStyle(Theme.secondaryText)

                    Text("READY")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.dimText)
                        .tracking(1.5)
                }
            }

            VStack(spacing: 12) {
                TextField("What will you work on?", text: $model.currentTask)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.primaryText)
                    .padding(10)
                    .background(Color.white.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onSubmit { startWithLog() }

                actionButton(
                    "Start Focus",
                    enabled: !model.currentTask.trimmingCharacters(in: .whitespaces).isEmpty
                ) {
                    startWithLog()
                }
            }
        }
    }

    private var activeTimerView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Theme.ringTrack, lineWidth: 6)
                    .frame(width: 140, height: 140)

                Circle()
                    .trim(from: 0, to: model.progress)
                    .stroke(
                        phaseColor,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: model.progress)

                VStack(spacing: 4) {
                    Text(model.displayTime)
                        .font(.system(size: 36, weight: .light, design: .rounded))
                        .foregroundStyle(Theme.primaryText)
                        .contentTransition(.numericText())

                    Text(model.phase.rawValue.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(phaseAccentColor)
                        .tracking(1.5)
                }
            }

            if !model.currentTask.isEmpty {
                Text(model.currentTask)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.secondaryText)
                    .lineLimit(1)
            }

            if model.phase == .working {
                noteInputView
            }

            HStack(spacing: 10) {
                if model.isPaused {
                    pillButton("Resume", icon: "play.fill", color: Theme.warmBlue) {
                        model.resume()
                    }
                } else {
                    pillButton("Pause", icon: "pause.fill", color: Theme.warmOrange) {
                        model.pause()
                    }
                }

                pillButton("Reset", icon: "arrow.counterclockwise", color: Theme.warmGray) {
                    model.reset()
                }
            }
        }
    }

    // MARK: - Note Input

    private var noteInputView: some View {
        VStack(spacing: 6) {
            if !recentNotes.isEmpty {
                notesListView(recentNotes)
            }

            HStack(spacing: 8) {
                TextField("Add a note...", text: $comment)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.primaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .onSubmit { addNote() }

                Button {
                    addNote()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(
                            comment.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Theme.dimText
                                : Theme.primaryText
                        )
                }
                .buttonStyle(.plain)
                .disabled(comment.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private func notesListView(_ notes: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(notes.enumerated()), id: \.offset) { _, note in
                HStack(alignment: .top, spacing: 6) {
                    Circle()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: 5, height: 5)
                        .padding(.top, 5)
                    Text(note)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.secondaryText)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Theme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 6))
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
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 6)
                    .frame(width: 140, height: 140)

                Circle()
                    .trim(from: 0, to: 1)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(Theme.primaryText)

                    Text("DONE")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.primaryText)
                        .tracking(1.5)
                }
            }

            if !model.currentTask.isEmpty {
                Text(model.currentTask)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.secondaryText)
            }

            if !recentNotes.isEmpty {
                notesListView(recentNotes)
            }

            VStack(spacing: 10) {
                TextField("What did you accomplish?", text: $reflection)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.primaryText)
                    .padding(10)
                    .background(Color.white.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onSubmit { saveReflectionAndStartBreak() }

                HStack(spacing: 10) {
                    actionButton(
                        "Save & Break",
                        enabled: !reflection.trimmingCharacters(in: .whitespaces).isEmpty
                    ) {
                        saveReflectionAndStartBreak()
                    }

                    Button {
                        reflection = ""
                        recentNotes = []
                        model.startBreak()
                    } label: {
                        Text("Skip")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.secondaryText)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(24)
    }

    // MARK: - Settings View

    private var settingsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.primaryText)

            VStack(alignment: .leading, spacing: 8) {
                Text("LOG FILE")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.dimText)
                    .tracking(1)

                Text(PomodoroLog.shared.filePath)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Theme.secondaryText)
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Theme.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Button {
                    chooseLogFile()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "folder")
                            .font(.system(size: 11))
                        Text("Change Location")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(Theme.primaryText)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
    }

    // MARK: - Reusable Components

    private func actionButton(_ title: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(enabled ? Theme.buttonText : Theme.dimText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(enabled ? Theme.buttonBg : Color.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private func pillButton(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(Theme.primaryText)
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .background(Color.white.opacity(0.2))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
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
        case .idle: return Theme.dimText
        case .working: return Theme.warmGreen
        case .onBreak: return Theme.warmGreen
        }
    }

    private var phaseAccentColor: Color {
        switch model.phase {
        case .idle: return Theme.dimText
        case .working: return Theme.warmOrange
        case .onBreak: return Theme.warmGreen
        }
    }
}
