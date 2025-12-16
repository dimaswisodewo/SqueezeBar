//
//  AppSettings.swift
//  SqueezeBar
//
//  Created by Dimas Wisodewo on 15/12/25.
//

import Foundation
import Combine
import AppKit

class AppSettings: ObservableObject {
    @Published var outputFolderURL: URL? {
        didSet {
            // Stop accessing old URL only if it's different
            if let oldURL = oldValue, oldURL != outputFolderURL, isAccessingSecurityScope {
                oldURL.stopAccessingSecurityScopedResource()
                isAccessingSecurityScope = false
            }

            saveOutputFolder()

            // Start accessing new URL
            if let newURL = outputFolderURL, !isAccessingSecurityScope {
                isAccessingSecurityScope = newURL.startAccessingSecurityScopedResource()
            }
        }
    }

    @Published var compressionMode: CompressionMode = .quality
    @Published var compressionQuality: CompressionQuality = .medium
    @Published var customQuality: Double = 0.6 // 0.0 to 1.0
    @Published var targetSizeMB: Double = 5.0 // Target size in MB
    @Published var compressionPercentage: Double = 50.0 // Reduce by X%

    /// Get the effective quality factor based on current settings
    var effectiveQuality: Double {
        if compressionMode == .quality && compressionQuality == .custom {
            return customQuality
        }
        return compressionQuality.qualityFactor
    }

    private static let bookmarkKey = "outputFolderBookmark"
    private var isAccessingSecurityScope = false {
        didSet {
            #if DEBUG
            if isAccessingSecurityScope {
                print("Security-scoped resource access started")
            } else {
                print("Security-scoped resource access stopped")
            }
            #endif
        }
    }

    init() {
        loadOutputFolder()
    }

    /// Save output folder as security-scoped bookmark
    private func saveOutputFolder() {
        guard let url = outputFolderURL else {
            UserDefaults.standard.removeObject(forKey: Self.bookmarkKey)
            return
        }

        do {
            let bookmark = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(bookmark, forKey: Self.bookmarkKey)
        } catch {
            print("Failed to save bookmark: \(error.localizedDescription)")
        }
    }

    /// Load output folder from security-scoped bookmark
    private func loadOutputFolder() {
        guard let bookmark = UserDefaults.standard.data(forKey: Self.bookmarkKey) else {
            return
        }

        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmark,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            if !isStale {
                // Set URL which will trigger didSet and handle security scope
                outputFolderURL = url
            } else {
                // Bookmark is stale, remove it
                UserDefaults.standard.removeObject(forKey: Self.bookmarkKey)
            }
        } catch {
            #if DEBUG
            print("Failed to resolve bookmark: \(error.localizedDescription)")
            #endif
            UserDefaults.standard.removeObject(forKey: Self.bookmarkKey)
        }
    }

    /// Ensure we have access to the output folder before compression
    func ensureAccess() -> Bool {
        guard let url = outputFolderURL else {
            return false
        }

        // If already accessing, we're good
        if isAccessingSecurityScope {
            return true
        }

        // Try to start accessing
        if url.startAccessingSecurityScopedResource() {
            isAccessingSecurityScope = true
            return true
        }

        return false
    }

    /// Open the destination folder in Finder
    func openDestinationFolder() {
        guard let url = outputFolderURL else { return }

        // Perform file system operation on background queue to avoid freezing UI
        DispatchQueue.global(qos: .userInitiated).async {
            NSWorkspace.shared.open(url)
        }
    }

    deinit {
        // Stop accessing security-scoped resource when settings object is deallocated
        if let url = outputFolderURL, isAccessingSecurityScope {
            url.stopAccessingSecurityScopedResource()
            isAccessingSecurityScope = false
        }
    }
}
