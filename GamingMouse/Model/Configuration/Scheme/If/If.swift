// MIT License
// Copyright (c) 2021-2024 LinearMouse

import AppKit
import Foundation

extension Scheme {
    struct If: Codable, Equatable {
        var device: DeviceMatcher?

        var app: String?
        var parentApp: String?
        var groupApp: String?

        var display: String?
    }
}

extension Scheme.If {
    func isSatisfied(withDevice targetDevice: Device? = nil) -> Bool {
        if let device = device {
            guard let targetDevice = targetDevice else {
                return false
            }

            guard device.match(with: targetDevice) else {
                return false
            }
        }

        return true
    }
}
