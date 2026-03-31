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

    // MARK: - Framerate Settings
    @Published var enableFramerateReduction: Bool = false
    @Published var targetFramerate: Double? = nil  // nil = use original

    /// Get the effective quality factor based on current settings
    var effectiveQuality: Double {
        if compressionMode == .quality && compressionQuality == .custom {
            return customQuality
        }
        return compressionQuality.qualityFactor
    }

    /// Get the effective framerate based on current settings
    var effectiveFramerate: Double? {
        return enableFramerateReduction ? targetFramerate : nil
    }

    // MARK: - Conversion Settings
    @Published var conversionCategory: ConversionCategory = .imageToImage
    @Published var imageOutputFormat: ImageOutputFormat = .jpeg
    @Published var imageConversionQuality: Double = 0.85
    @Published var videoOutputFormat: VideoOutputFormat = .mp4

    private static let bookmarkKey = "outputFolderBookmark"
    private static let enableFramerateReductionKey = "enableFramerateReduction"
    private static let targetFramerateKey = "targetFramerate"
    private static let conversionCategoryKey = "conversionCategory"
    private static let imageOutputFormatKey = "imageOutputFormat"
    private static let imageConversionQualityKey = "imageConversionQuality"
    private static let videoOutputFormatKey = "videoOutputFormat"

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
        loadFramerateSettings()
        loadConversionSettings()
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

    /// Load framerate settings from UserDefaults
    private func loadFramerateSettings() {
        enableFramerateReduction = UserDefaults.standard.bool(forKey: Self.enableFramerateReductionKey)

        if UserDefaults.standard.object(forKey: Self.targetFramerateKey) != nil {
            let savedTargetFramerate = UserDefaults.standard.double(forKey: Self.targetFramerateKey)
            if savedTargetFramerate > 0 {
                targetFramerate = savedTargetFramerate
            }
        }
    }

    /// Save framerate settings to UserDefaults
    func saveFramerateSettings() {
        UserDefaults.standard.set(enableFramerateReduction, forKey: Self.enableFramerateReductionKey)
        if let fps = targetFramerate {
            UserDefaults.standard.set(fps, forKey: Self.targetFramerateKey)
        } else {
            UserDefaults.standard.removeObject(forKey: Self.targetFramerateKey)
        }
    }

    /// Load conversion settings from UserDefaults
    private func loadConversionSettings() {
        if let raw = UserDefaults.standard.string(forKey: Self.conversionCategoryKey),
           let value = ConversionCategory(rawValue: raw) {
            conversionCategory = value
        }
        if let raw = UserDefaults.standard.string(forKey: Self.imageOutputFormatKey),
           let value = ImageOutputFormat(rawValue: raw) {
            imageOutputFormat = value
        }
        let savedQuality = UserDefaults.standard.double(forKey: Self.imageConversionQualityKey)
        if savedQuality > 0 {
            imageConversionQuality = savedQuality
        }
        if let raw = UserDefaults.standard.string(forKey: Self.videoOutputFormatKey),
           let value = VideoOutputFormat(rawValue: raw) {
            videoOutputFormat = value
        }
    }

    /// Save conversion settings to UserDefaults
    func saveConversionSettings() {
        UserDefaults.standard.set(conversionCategory.rawValue, forKey: Self.conversionCategoryKey)
        UserDefaults.standard.set(imageOutputFormat.rawValue, forKey: Self.imageOutputFormatKey)
        UserDefaults.standard.set(imageConversionQuality, forKey: Self.imageConversionQualityKey)
        UserDefaults.standard.set(videoOutputFormat.rawValue, forKey: Self.videoOutputFormatKey)
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
