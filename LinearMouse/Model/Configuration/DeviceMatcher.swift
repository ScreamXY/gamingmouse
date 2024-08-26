// MIT License
// Copyright (c) 2021-2024 LinearMouse

import Defaults

struct DeviceMatcher: Codable, Equatable, Hashable, Defaults.Serializable {
    var isGamingMouse: Bool?
}

extension DeviceMatcher {
    init(of device: Device) {
        self.init(isGamingMouse: device.isGamingMouse)
    }

    func match(with device: Device) -> Bool {
        func matchValue<T>(_ destination: T?, _ source: T) -> Bool where T: Equatable {
            destination == nil || source == destination
        }

        func matchValue<T>(_ destination: T?, _ source: T?) -> Bool where T: Equatable {
            destination == nil || source == destination
        }

        guard matchValue(isGamingMouse, device.isGamingMouse)
        else {
            return false
        }

        return true
    }
}
