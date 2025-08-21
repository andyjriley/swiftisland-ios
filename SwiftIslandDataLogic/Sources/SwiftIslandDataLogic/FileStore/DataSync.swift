//
//  FileStore.swift
//  SwiftIslandDataLogic
//
//  Created by Niels van Hoorn on 2025-08-11.
//

import Foundation

enum Conf {
    static let org = "SwiftIsland"     // fill
    static let repo = "app"   // fill
    
    /// Get the branch name from environment variable, defaults to "main"
    static var branch: String {
        ProcessInfo.processInfo.environment["SWIFTISLAND_BRANCH"] ?? "main"
    }
    
    /// Force use of bundled data only (useful for iteration and offline testing)
    static var useBundledDataOnly: Bool {
        ProcessInfo.processInfo.environment["SWIFTISLAND_USE_BUNDLED_DATA"] == "YES"
    }
    
    /// Check if this is likely a first app launch (no cached data exists)
    static var isFirstLaunch: Bool {
        !FileManager.default.fileExists(atPath: FileStore.base.path)
    }
}


// MARK: - ETag + Net

final class ETagStore {
    static let shared = ETagStore()
    private let d = UserDefaults.standard
    func get(_ url: URL) -> String? { d.string(forKey: "eetag::" + url.absoluteString) }
    func set(_ v: String?, _ url: URL) { let k = "eetag::" + url.absoluteString; v == nil ? d.removeObject(forKey: k) : d.set(v, forKey: k) }
}

private enum Net {
    static func getWithETag(_ url: URL, etag: String?) async throws -> (code: Int, data: Data?, etag: String?) {
        var req = URLRequest(url: url)
//        req.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        if let etag { req.setValue(etag, forHTTPHeaderField: "If-None-Match") }
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        return (http.statusCode, data, http.value(forHTTPHeaderField: "ETag"))
    }
}

// MARK: - File store (atomic)

struct FileStore {
    static let base: URL = {
        let dir = try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let folder = dir.appendingPathComponent("DataCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }()
    static func writeAtomic(_ data: Data, to url: URL) throws {
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        let tmp = url.appendingPathExtension("tmp")
        try data.write(to: tmp, options: .atomic)
        if FileManager.default.fileExists(atPath: url.path) {
            _ = try FileManager.default.replaceItemAt(url, withItemAt: tmp)
        } else {
            try FileManager.default.moveItem(at: tmp, to: url)
        }
    }
    
    static func read(from url: URL) throws -> Data {
        return try Data(contentsOf: url)
    }
}

// MARK: - Sync

public final class DataSync {
    
    static func fetchURL(_ path: String) async throws -> Data {
        // If forced to use bundled data only, skip network requests
        if Conf.useBundledDataOnly {
            debugPrint("🔒 Using bundled data only for: \(path)")
            return try fetchBundledData(path)
        }
        
        // On first launch, prioritize bundled data for immediate availability
        if Conf.isFirstLaunch {
            do {
                let bundledData = try fetchBundledData(path)
                debugPrint("🚀 First launch: using bundled data for: \(path)")
                
                // Start background sync for future use (don't wait for it)
                Task {
                    do {
                        let url = try fileURL(for: path)
                        let res = try await Net.getWithETag(url, etag: nil)
                        if let body = res.data {
                            let storeURL = FileStore.base.appendingPathComponent(path)
                            try FileStore.writeAtomic(body, to: storeURL)
                            if let e = res.etag { ETagStore.shared.set(e, url) }
                            debugPrint("✅ Background sync completed for: \(path)")
                        }
                    } catch {
                        debugPrint("⚠️ Background sync failed for \(path): \(error)")
                    }
                }
                
                return bundledData
            } catch {
                debugPrint("⚠️ Bundled data not available for \(path), falling back to network: \(error)")
            }
        }
        
        // Try to fetch from network with fallback to bundled data
        do {
            let url = try fileURL(for: path)
            let etag0 = ETagStore.shared.get(url)
            let res = try await Net.getWithETag(url, etag: etag0)
            let storeURL = FileStore.base.appendingPathComponent(path)
            guard res.code != 304 else {
                return try FileStore.read(from: storeURL)
            }
            guard let body = res.data else { throw URLError(.badURL) }
            try FileStore.writeAtomic(body, to: storeURL)
            if let e = res.etag { ETagStore.shared.set(e, url) }
            return body
        } catch {
            debugPrint("⚠️ Network fetch failed for \(path), falling back to bundled data: \(error)")
            return try fetchBundledData(path)
        }
    }
    
    /// Fetch data from the app bundle
    static func fetchBundledData(_ path: String) throws -> Data {
        // Automatically add "api/" prefix if not already present
        let apiPath = path.hasPrefix("api/") ? path : "api/\(path)"
        
        // Try to find the file in the bundle
        guard let bundleURL = Bundle.main.url(forResource: apiPath, withExtension: nil) else {
            debugPrint("❌ Bundled file not found: \(apiPath)")
            throw URLError(.fileDoesNotExist)
        }
        
        debugPrint("📦 Loading bundled data: \(apiPath)")
        return try Data(contentsOf: bundleURL)
    }
    
    public static func fetchImage(_ imagePath: String) async throws -> Data {
        return try await fetchURL(imagePath)
    }
    
    public static func localImageURL(for imagePath: String) -> URL {
        // Automatically add "api/" prefix if not already present for consistent local storage
        let apiPath = imagePath.hasPrefix("api/") ? imagePath : "api/\(imagePath)"
        return FileStore.base.appendingPathComponent(apiPath)
    }
    
    public static func hasLocalImage(for imagePath: String) -> Bool {
        let localURL = localImageURL(for: imagePath)
        return FileManager.default.fileExists(atPath: localURL.path)
    }

    
    private static func fileURL(for path: String) throws -> URL {
        // Automatically add "api/" prefix if not already present
        let apiPath = path.hasPrefix("api/") ? path : "api/\(path)"
        let s = "https://raw.githubusercontent.com/\(Conf.org)/\(Conf.repo)/refs/heads/\(Conf.branch)/\(apiPath)"
        debugPrint("➡️ Fetching from: \(s)")
        guard let u = URL(string: s) else { throw URLError(.badURL) }
        return u
    }

}
