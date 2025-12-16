//
//  BundleResourceHelper.swift
//  SqueezeBar
//
//  Created by Dimas Wisodewo on 15/12/25.
//

import Foundation

enum BundleResourceHelper {
    /// Locates the bundled Ghostscript binary
    /// - Returns: Path to gs binary if found in bundle, nil otherwise
    static func findBundledGhostscript() -> String? {
        // Get main bundle resource path
        guard let resourcePath = Bundle.main.resourcePath else {
            return nil
        }

        // Construct path to bundled gs binary using URL
        let resourceURL = URL(fileURLWithPath: resourcePath)
        let gsURL = resourceURL
            .appendingPathComponent("Binaries")
            .appendingPathComponent("gs")
        let gsPath = gsURL.path

        // Verify binary exists and is executable
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: gsPath),
              fileManager.isExecutableFile(atPath: gsPath) else {
            return nil
        }

        return gsPath
    }

    /// Ensures the bundled binary has executable permissions
    /// Call this to verify permissions are correct
    /// - Parameter path: Path to the binary
    /// - Returns: True if permissions were set successfully
    static func ensureExecutablePermissions(for path: String) -> Bool {
        do {
            let attributes = [FileAttributeKey.posixPermissions: 0o755]
            try FileManager.default.setAttributes(attributes, ofItemAtPath: path)
            return true
        } catch {
            print("Failed to set executable permissions: \(error)")
            return false
        }
    }
}
