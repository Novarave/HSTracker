//
//  LogPathResolver.swift
//  HSTracker
//
//  Keeps log discovery independent from HearthMirror. HearthMirror remains the
//  preferred source while the game is running, but a filesystem fallback lets
//  the tracker start from a normal macOS Hearthstone installation as well.
//

import Foundation

struct LogPathResolver {
    private static let knownLogFileNames: Set<String> = [
        "Power.log",
        "LoadingScreen.log",
        "Rachelle.log",
        "Decks.log",
        "Arena.log",
        "Zone.log",
        "Net.log"
    ]

    /// Returns the best available Hearthstone log directory.
    ///
    /// `mirrorPath` is deliberately preferred: it is the exact session
    /// directory HearthMirror has already observed. The remaining candidates
    /// are ordinary macOS locations and are kept filesystem-only so this type
    /// can be tested without loading HearthMirror.
    static func resolve(mirrorPath: String?,
                        configuredGamePath: String = "",
                        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser,
                        fileManager: FileManager = .default) -> String {
        if let mirrorPath = mirrorPath?.trimmingCharacters(in: .whitespacesAndNewlines),
           !mirrorPath.isEmpty {
            return mirrorPath
        }

        for candidate in candidates(configuredGamePath: configuredGamePath,
                                    homeDirectory: homeDirectory) {
            if let directory = usableDirectory(from: candidate, fileManager: fileManager) {
                return directory.path
            }
        }

        return ""
    }

    static func candidates(configuredGamePath: String, homeDirectory: URL) -> [URL] {
        var result = [URL]()
        let configured = configuredGamePath.trimmingCharacters(in: .whitespacesAndNewlines)
        if !configured.isEmpty {
            let base = URL(fileURLWithPath: configured, isDirectory: true)
            result.append(base.appendingPathComponent("Logs", isDirectory: true))
            result.append(base.appendingPathComponent("Contents/Logs", isDirectory: true))
        }

        result.append(homeDirectory.appendingPathComponent("Library/Logs/Blizzard/Hearthstone", isDirectory: true))
        result.append(homeDirectory.appendingPathComponent("Library/Logs/Blizzard/Hearthstone/Logs", isDirectory: true))
        result.append(homeDirectory.appendingPathComponent("Library/Logs/Hearthstone", isDirectory: true))
        result.append(homeDirectory.appendingPathComponent("Library/Application Support/Blizzard/Hearthstone/Logs", isDirectory: true))
        return result
    }

    private static func usableDirectory(from candidate: URL,
                                        fileManager: FileManager) -> URL? {
        var isDirectory = ObjCBool(false)
        guard fileManager.fileExists(atPath: candidate.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            return nil
        }

        if containsLogFiles(candidate, fileManager: fileManager) {
            return candidate
        }

        let children = (try? fileManager.contentsOfDirectory(at: candidate,
                                                               includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey],
                                                               options: [.skipsHiddenFiles])) ?? []
        let sessions = children.filter { url in
            (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true &&
                containsLogFiles(url, fileManager: fileManager)
        }

        if let newest = sessions.max(by: modificationDateLessThan) {
            return newest
        }

        // An empty but valid Logs directory is still useful to LogReaderManager:
        // Hearthstone can create the session files after tracking starts.
        return candidate
    }

    private static func containsLogFiles(_ directory: URL, fileManager: FileManager) -> Bool {
        let children = (try? fileManager.contentsOfDirectory(at: directory,
                                                               includingPropertiesForKeys: [.isDirectoryKey],
                                                               options: [.skipsHiddenFiles])) ?? []
        return children.contains { url in
            guard (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) != true else {
                return false
            }
            return knownLogFileNames.contains(url.lastPathComponent) || url.pathExtension.lowercased() == "log"
        }
    }

    private static func modificationDateLessThan(_ lhs: URL, _ rhs: URL) -> Bool {
        let lhsDate = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? nil
        let rhsDate = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? nil
        return (lhsDate ?? .distantPast) < (rhsDate ?? .distantPast)
    }
}
