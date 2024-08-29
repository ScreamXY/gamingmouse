// MIT License
// Copyright (c) 2021-2024 LinearMouse

import Foundation

enum GamingMouse {
    public static var appBundleIdentifier: String {
        Bundle.main.infoDictionary?[kCFBundleIdentifierKey as String] as? String ?? "ch.screamcode.GamingMouse"
    }

    public static var appName: String {
        Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String ?? "(unknown)"
    }

    public static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "(unknown)"
    }
}
