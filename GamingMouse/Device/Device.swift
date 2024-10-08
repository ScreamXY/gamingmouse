// MIT License
// Copyright (c) 2021-2024 LinearMouse

import Defaults
import Foundation
import ObservationToken
import os.log
import PointerKit

class Device {
    private static let log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "Device")

    private struct Product: Hashable {
        let vendorID: Int
        let productID: Int
    }

    private weak var manager: DeviceManager?
    private let device: PointerDevice

    private var removed = false

    @Default(.verbosedLoggingOn) private var verbosedLoggingOn

    private var inputObservationToken: ObservationToken?
    private var reportObservationToken: ObservationToken?

    private var lastButtonStates: UInt8 = 0

    init(_ manager: DeviceManager, _ device: PointerDevice) {
        self.manager = manager
        self.device = device

        // TODO: More elegant way?
        inputObservationToken = device.observeInput(using: { [weak self] in
            self?.inputValueCallback($0, $1)
        })

        os_log("Device initialized: %{public}@: HIDPointerAccelerationType=%{public}@",
               log: Self.log, type: .info,
               String(describing: device),
               device.pointerAccelerationType ?? "(unknown)")
    }

    func markRemoved() {
        removed = true

        inputObservationToken = nil
        reportObservationToken = nil
    }
}

extension Device {
    var name: String {
        device.name
    }

    var productName: String? {
        device.product
    }

    var vendorID: Int? {
        device.vendorID
    }

    var productID: Int? {
        device.productID
    }

    var serialNumber: String? {
        device.serialNumber
    }

    var buttonCount: Int? {
        device.buttonCount
    }

    enum Category {
        case mouse, trackpad
    }
    
    var isGamingMouse: Bool? {
        if let vendorID: Int = device.vendorID,
           let productID: Int = device.productID {
            return !isAppleMagicMouse(vendorID: vendorID, productID: productID) && category == .mouse
        }
        return true
    }

    private func isAppleMagicMouse(vendorID: Int, productID: Int) -> Bool {
        [0x004C, 0x05AC].contains(vendorID) && [0x0269, 0x030D].contains(productID)
    }

    var category: Category {
        if let vendorID: Int = device.vendorID,
           let productID: Int = device.productID {
            if isAppleMagicMouse(vendorID: vendorID, productID: productID) {
                return .mouse
            }
        }
        if device.confirmsTo(kHIDPage_Digitizer, kHIDUsage_Dig_TouchPad) {
            return .trackpad
        }
        return .mouse
    }

    private func inputValueCallback(_ device: PointerDevice, _ value: IOHIDValue) {
        if verbosedLoggingOn {
            os_log("Received input value from: %{public}@: %{public}@", log: Self.log, type: .info,
                   String(describing: device), String(describing: value))
        }

        guard let manager = manager else {
            os_log("manager is nil", log: Self.log, type: .error)
            return
        }

        guard manager.lastActiveDeviceRef?.value != self else {
            return
        }

        let element = value.element

        let usagePage = element.usagePage
        let usage = element.usage

        switch Int(usagePage) {
        case kHIDPage_GenericDesktop:
            switch Int(usage) {
            case kHIDUsage_GD_X, kHIDUsage_GD_Y, kHIDUsage_GD_Z:
                guard IOHIDValueGetIntegerValue(value) != 0 else {
                    return
                }
            default:
                return
            }
        case kHIDPage_Button:
            break
        default:
            return
        }

        manager.lastActiveDeviceRef = .init(self)

        os_log("""
               Last active device changed: %{public}@, category=%{public}@ \
               (Reason: Received input value: usagePage=0x%{public}02X, usage=0x%{public}02X)
               """,
               log: Self.log, type: .info,
               String(describing: device),
               String(describing: category),
               usagePage,
               usage)
    }

    private func inputReportCallback(_ device: PointerDevice, _ report: Data) {
        if verbosedLoggingOn {
            let reportHex = report.map { String(format: "%02X", $0) }.joined(separator: " ")
            os_log("Received input report from: %{public}@: %{public}@", log: Self.log, type: .info,
                   String(describing: device), String(describing: reportHex))
        }

        // FIXME: Correct HID Report parsing?
        guard report.count >= 2 else {
            return
        }
        // | Button 0 (1 bit) | ... | Button 4 (1 bit) | Not Used (3 bits) |
        let buttonStates = report[1] & 0x18
        let toggled = lastButtonStates ^ buttonStates
        guard toggled != 0 else {
            return
        }
        for button in 3 ... 4 {
            guard toggled & (1 << button) != 0 else {
                continue
            }
            let down = buttonStates & (1 << button) != 0
            os_log("Simulate button %{public}d %{public}@ event for device: %{public}@", log: Self.log, type: .info,
                   button, down ? "down" : "up", String(describing: device))
            guard let location = CGEvent(source: nil)?.location else {
                continue
            }
            guard let event = CGEvent(mouseEventSource: nil,
                                      mouseType: down ? .otherMouseDown : .otherMouseUp,
                                      mouseCursorPosition: location,
                                      mouseButton: .init(rawValue: UInt32(button))!) else {
                continue
            }
            event.post(tap: .cghidEventTap)
        }
        lastButtonStates = buttonStates
    }
}

extension Device: Hashable {
    static func == (lhs: Device, rhs: Device) -> Bool {
        lhs.device == rhs.device
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(device)
    }
}

extension Device: CustomStringConvertible {
    var description: String {
        device.description
    }
}
