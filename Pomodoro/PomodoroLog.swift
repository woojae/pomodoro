import Foundation

@MainActor
final class PomodoroLog {
    static let shared = PomodoroLog()

    private static let defaultDirectory: String = {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("pomodoro").path
    }()

    private static let pathKey = "logDirectoryPath"

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.timeZone = .current
        return f
    }()

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f
    }()

    var directoryPath: String {
        get { UserDefaults.standard.string(forKey: Self.pathKey) ?? Self.defaultDirectory }
        set { UserDefaults.standard.set(newValue, forKey: Self.pathKey) }
    }

    private var hasWrittenNotesHeader = false

    private init() {}

    private func todayFilePath() -> String {
        let date = dateFormatter.string(from: Date())
        return (directoryPath as NSString).appendingPathComponent("\(date).md")
    }

    private func ensureDirectory() {
        let fm = FileManager.default
        if !fm.fileExists(atPath: directoryPath) {
            try? fm.createDirectory(atPath: directoryPath, withIntermediateDirectories: true)
        }
    }

    private func append(_ text: String) {
        ensureDirectory()
        let path = todayFilePath()
        let url = URL(fileURLWithPath: path)
        if let handle = try? FileHandle(forWritingTo: url) {
            handle.seekToEndOfFile()
            handle.write(text.data(using: .utf8)!)
            handle.closeFile()
        } else {
            try? text.data(using: .utf8)?.write(to: url)
        }
    }

    func start(_ task: String) {
        let time = timeFormatter.string(from: Date())
        let path = todayFilePath()
        let fileExists = FileManager.default.fileExists(atPath: path)
        let prefix = fileExists ? "\n" : ""
        append("\(prefix)## \(time) — \(task)\n\n")
        hasWrittenNotesHeader = false
    }

    func note(_ text: String) {
        if !hasWrittenNotesHeader {
            append("### Notes\n\n")
            hasWrittenNotesHeader = true
        }
        append("\(text)\n\n")
    }

    func done(_ text: String) {
        append("### Reflection\n\n\(text)\n\n---\n")
    }
}
