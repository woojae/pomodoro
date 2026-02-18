import Foundation

@MainActor
final class PomodoroLog {
    static let shared = PomodoroLog()

    private static let defaultPath: String = {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("pomodoro.log").path
    }()

    private static let pathKey = "logFilePath"

    private let dateFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    var filePath: String {
        get { UserDefaults.standard.string(forKey: Self.pathKey) ?? Self.defaultPath }
        set { UserDefaults.standard.set(newValue, forKey: Self.pathKey) }
    }

    private init() {}

    func log(type: String, text: String) {
        let timestamp = dateFormatter.string(from: Date())
        let line = "\(timestamp)\t\(type)\t\(text)\n"
        let url = URL(fileURLWithPath: filePath)
        if let handle = try? FileHandle(forWritingTo: url) {
            handle.seekToEndOfFile()
            handle.write(line.data(using: .utf8)!)
            handle.closeFile()
        } else {
            try? line.data(using: .utf8)?.write(to: url)
        }
    }

    func start(_ task: String) { log(type: "start", text: task) }
    func note(_ text: String)  { log(type: "note", text: text) }
    func done(_ text: String)  { log(type: "done", text: text) }
}
