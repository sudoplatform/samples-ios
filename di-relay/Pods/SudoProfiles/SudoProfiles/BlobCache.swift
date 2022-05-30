//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Simple blob cache implementation that uses the file store.
class BlobCache {

    /// Cache container URL.
    let containerURL: URL

    /// Cache entry.
    struct Entry {

        /// Cache container URL.
        let containerURL: URL

        /// Entry ID.
        let id: String

        /// Returns the URL representation of this entry.
        ///
        /// - Returns: URL representation of this entry.
        func toURL() -> URL {
            return self.containerURL.appendingPathComponent(self.id)
        }

        /// Loads the cache entry from the file store.
        ///
        /// - Returns: Blob as Data.
        func load() throws -> Data {
            return try Data(contentsOf: self.toURL())
        }

    }

    /// Initializes `BlobCache`.
    ///
    /// - Parameter containerURL: Container URL for the cache.
    init(containerURL: URL) throws {
        self.containerURL = containerURL
        if !FileManager.default.fileExists(atPath: containerURL.path) {
            try FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true)
        }
    }

    /// Replaces a cache entry with a blob located at a specified URL.
    ///
    /// - Parameters:
    ///   - fileURL: Blob URL.
    ///   - id: Cache entry ID.
    /// - Returns: Newly created cache entry.
    func replace(fileURL: URL, id: String) throws -> Entry {
        let entry = Entry(containerURL: self.containerURL, id: id)
        let entryURL = entry.toURL()
        if fileURL != entryURL {
            try self.remove(id: entry.id)
            let parent = entryURL.deletingLastPathComponent()
            if !FileManager.default.fileExists(atPath: parent.path) {
                try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
            }
            try FileManager.default.copyItem(at: fileURL, to: entryURL)
        }
        return entry
    }

    /// Replaces a cache entry with the specific blob.
    ///
    /// - Parameters:
    ///   - data: Blob data.
    ///   - id: Cache entry ID.
    /// - Returns: Updated cache entry.
    func replace(data: Data, id: String) throws -> Entry {
        let entry = Entry(containerURL: self.containerURL, id: id)
        let entryURL = entry.toURL()
        let parent = entryURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: parent.path) {
            try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        }
        try data.write(to: entryURL, options: [.atomic])
        return entry
    }

    /// Removes a cache entry.
    ///
    /// - Parameter id: Cache entry ID.
    func remove(id: String) throws {
        let url = self.containerURL.appendingPathComponent(id)

        guard FileManager.default.fileExists(atPath: url.path) else {
            return
        }

        try FileManager.default.removeItem(at: url)
    }

    /// Removes a cache entry located at the specified URL.
    ///
    /// - Parameter url: Cache entry URL.
    func remove(url: URL) throws {
        guard url.standardizedFileURL.path.starts(with: self.containerURL.standardizedFileURL.path) else {
            return
        }

        guard FileManager.default.fileExists(atPath: url.path) else {
            return
        }

        try FileManager.default.removeItem(at: url)
    }

    /// Retrieves a cache entry.
    ///
    /// - Parameter id: Cache entry ID.
    /// - Returns: Cache entry.
    func get(id: String) -> Entry? {
        let url = self.containerURL.appendingPathComponent(id)
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        return Entry(containerURL: self.containerURL, id: id)
    }

    /// Retrieves a cache entry located at the specified URL.
    ///
    /// - Parameter url: Cache entry URL.
    /// - Returns: Cache entry.
    func get(url: URL) -> Entry? {
        let path = url.standardizedFileURL.path
        let containerPath = self.containerURL.standardizedFileURL.path
        guard path.starts(with: containerPath) else {
            return nil
        }

        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        return Entry(containerURL: self.containerURL, id: String(path.dropFirst(containerPath.count + 1)))
    }

    /// Generates a cache URL from an ID.
    ///
    /// - Parameter id: Cache entry ID.
    /// - Returns: Cache entry URL.
    func cacheUrlFromId(id: String) -> URL {
        return self.containerURL.appendingPathComponent(id)
    }

    /// Returns the number of entries in the cache.
    ///
    /// - Returns: Number of entries in the cache.
    func count() throws -> Int {
        var count = 0

        if let enumerator = FileManager.default.enumerator(at: self.containerURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
            for case let url as URL in enumerator {
                let fileAttributes = try url.resourceValues(forKeys: [.isRegularFileKey])
                if let status = fileAttributes.isRegularFile, status {
                    count += 1
                }
            }
        }

        return count
    }

    /// Removes all entries from the cache.
    func reset() throws {
        let dirContents = try FileManager.default.contentsOfDirectory(
            at: self.containerURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        )
        for url in dirContents {
            try FileManager.default.removeItem(at: url)
        }
    }

}
