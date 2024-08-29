// MIT License
// Copyright (c) 2021-2024 LinearMouse

import Foundation

/// A scheme is a set of settings to be applied to LinearMouse, for example,
/// pointer speed.
///
/// A scheme will be active only if its `if` is truthy. If multiple `if`s are
/// provided, the scheme is regarded as active if any one of them is truthy.
///
/// There can be multiple active schemes at the same time. Settings in
/// subsequent schemes will be merged into the previous ones.
struct Scheme: Codable, Equatable {
    /// Defines the conditions under which this scheme is active.
    @SingleValueOrArray var `if`: [If]?

    @ImplicitOptional var scrolling: Scrolling

    init(if: [If]? = nil,
         scrolling: Scrolling? = nil) {
        self.if = `if`
        $scrolling = scrolling
    }
}

extension Scheme {
    func isActive(withDevice device: Device? = nil) -> Bool {
        guard let `if` = `if` else {
            return true
        }

        return `if`.contains {
            $0.isSatisfied(withDevice: device)
        }
    }

    var matchedDevices: [Device] {
        DeviceManager.shared.devices.filter { isActive(withDevice: $0) }
    }

    var firstMatchedDevice: Device? {
        DeviceManager.shared.devices.first { isActive(withDevice: $0) }
    }

    func merge(into scheme: inout Self) {
        $scrolling?.merge(into: &scheme.scrolling)
    }
}

extension Scheme: CustomStringConvertible {
    var description: String {
        do {
            return try String(data: JSONEncoder().encode(self), encoding: .utf8) ?? "<Scheme>"
        } catch {
            return "<Scheme>"
        }
    }
}

extension [Scheme] {
    func allDeviceSpecficSchemes(of device: Device) -> [EnumeratedSequence<[Scheme]>.Element] {
        self.enumerated().filter { _, scheme in
            guard scheme.if?.count == 1, let `if` = scheme.if?.first else { return false }
            guard `if`.device?.match(with: device) == true else { return false }
            return true
        }
    }

    enum SchemeIndex {
        case at(Int)
        case insertAt(Int)
    }

    func schemeIndex(ofDevice device: Device) -> SchemeIndex {
        let allDeviceSpecificSchemes = allDeviceSpecficSchemes(of: device)

        guard let first = allDeviceSpecificSchemes.first,
              let last = allDeviceSpecificSchemes.last else {
            return .insertAt(self.endIndex)
        }

        return .insertAt(last.offset + 1)
    }
}
