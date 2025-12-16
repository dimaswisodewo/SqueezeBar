//
//  SqueezeBarApp.swift
//  SqueezeBar
//
//  Created by Dimas Wisodewo on 15/12/25.
//

import SwiftUI

@main
struct SqueezeBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Empty - app runs only in menu bar
        Settings {
            EmptyView()
        }
    }
}
