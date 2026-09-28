import XCTest

final class LogPathResolverTests: XCTestCase {
    private var root: URL!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("HSTracker-LogPathResolver-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let root {
            try? FileManager.default.removeItem(at: root)
        }
    }

    func testMirrorPathWinsOverFilesystemCandidates() {
        let result = LogPathResolver.resolve(mirrorPath: "/mirror/session",
                                             configuredGamePath: root.path,
                                             homeDirectory: root)
        XCTAssertEqual(result, "/mirror/session")
    }

    func testNewestSessionDirectoryIsSelected() throws {
        let logs = root.appendingPathComponent("Library/Logs/Blizzard/Hearthstone", isDirectory: true)
        let oldSession = logs.appendingPathComponent("old", isDirectory: true)
        let newSession = logs.appendingPathComponent("new", isDirectory: true)
        try FileManager.default.createDirectory(at: oldSession, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: newSession, withIntermediateDirectories: true)
        try Data().write(to: oldSession.appendingPathComponent("Power.log"))
        try Data().write(to: newSession.appendingPathComponent("Power.log"))

        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 1)],
                                              ofItemAtPath: oldSession.path)
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 2)],
                                              ofItemAtPath: newSession.path)

        let result = LogPathResolver.resolve(mirrorPath: nil,
                                             configuredGamePath: "",
                                             homeDirectory: root)
        XCTAssertEqual(URL(fileURLWithPath: result).resolvingSymlinksInPath().path,
                       newSession.resolvingSymlinksInPath().path)
    }

    func testConfiguredLogsDirectoryIsUsedWhenPresent() throws {
        let logs = root.appendingPathComponent("Logs", isDirectory: true)
        try FileManager.default.createDirectory(at: logs, withIntermediateDirectories: true)

        let result = LogPathResolver.resolve(mirrorPath: "",
                                             configuredGamePath: root.path,
                                             homeDirectory: root)
        XCTAssertEqual(URL(fileURLWithPath: result).resolvingSymlinksInPath().path,
                       logs.resolvingSymlinksInPath().path)
    }

    func testEmptyCandidatesReturnEmptyPath() {
        let result = LogPathResolver.resolve(mirrorPath: nil,
                                             configuredGamePath: root.appendingPathComponent("missing").path,
                                             homeDirectory: root.appendingPathComponent("home"))
        XCTAssertEqual(result, "")
    }
}
