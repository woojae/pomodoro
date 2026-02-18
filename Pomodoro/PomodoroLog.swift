import Foundation

struct PomodoroComment: Codable {
    let timestamp: Date
    let text: String
}

struct PomodoroEntry: Codable {
    let date: Date
    let duration: Int
    let note: String
    var comments: [PomodoroComment]
    var reflection: String?

    init(date: Date, duration: Int, note: String) {
        self.date = date
        self.duration = duration
        self.note = note
        self.comments = []
    }
}

@MainActor
final class PomodoroLog {
    static let shared = PomodoroLog()

    private static let defaultPath: String = {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("pomodoro-log.json").path
    }()

    private static let pathKey = "logFilePath"

    var fileURL: URL {
        let path = UserDefaults.standard.string(forKey: Self.pathKey) ?? Self.defaultPath
        return URL(fileURLWithPath: path)
    }

    var filePath: String {
        get { UserDefaults.standard.string(forKey: Self.pathKey) ?? Self.defaultPath }
        set { UserDefaults.standard.set(newValue, forKey: Self.pathKey) }
    }

    private init() {}

    func save(_ entry: PomodoroEntry) {
        var entries = load()
        entries.append(entry)
        write(entries)
    }

    func addComment(_ text: String) {
        var entries = load()
        guard !entries.isEmpty else { return }
        let comment = PomodoroComment(timestamp: Date(), text: text)
        entries[entries.count - 1].comments.append(comment)
        write(entries)
    }

    func updateLastReflection(_ reflection: String) {
        var entries = load()
        guard !entries.isEmpty else { return }
        entries[entries.count - 1].reflection = reflection
        write(entries)
    }

    func load() -> [PomodoroEntry] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([PomodoroEntry].self, from: data)) ?? []
    }

    private func write(_ entries: [PomodoroEntry]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
