// MIT License
// Copyright (c) 2021-2024 LinearMouse

import Combine
import Defaults
import Foundation
import LRUCache
import os.log

class EventTransformerManager {
    static let shared = EventTransformerManager()
    static let log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "EventTransformerManager")

    private var eventTransformerCache = LRUCache<CacheKey, EventTransformer>(countLimit: 16)
    private var activeCacheKey: CacheKey?

    struct CacheKey: Hashable {
        var deviceMatcher: DeviceMatcher?
    }

    private var subscriptions = Set<AnyCancellable>()

    init() {
        ConfigurationState.shared.$configuration
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.eventTransformerCache.removeAllValues()
            }
            .store(in: &subscriptions)
    }

    func get(withCGEvent cgEvent: CGEvent,
             withSourcePid sourcePid: pid_t?,
             withTargetPid pid: pid_t?) -> EventTransformer {
        let prevActiveCacheKey = activeCacheKey
        defer {
            if let prevActiveCacheKey = prevActiveCacheKey,
               prevActiveCacheKey != activeCacheKey {
                if let eventTransformer = eventTransformerCache.value(forKey: prevActiveCacheKey) as? Deactivatable {
                    eventTransformer.deactivate()
                }
                if let activeCacheKey = activeCacheKey,
                   let eventTransformer = eventTransformerCache.value(forKey: activeCacheKey) as? Deactivatable {
                    eventTransformer.reactivate()
                }
            }
        }

        activeCacheKey = nil

        let device = DeviceManager.shared.deviceFromCGEvent(cgEvent)
        let cacheKey = CacheKey(deviceMatcher: device.map { DeviceMatcher(of: $0) })
        activeCacheKey = cacheKey
        if let eventTransformer = eventTransformerCache.value(forKey: cacheKey) {
            return eventTransformer
        }

        let scheme = ConfigurationState.shared.configuration.matchScheme(withDevice: device,
                                                                         withPid: pid)

        // TODO: Patch EventTransformer instead of rebuilding it

        os_log(
            "Initialize EventTransformer with scheme: %{public}@ (device=%{public}@, pid=%{public}@)",
            log: Self.log,
            type: .info,
            String(describing: scheme),
            String(describing: device),
            String(describing: pid)
        )

        var eventTransformer: [EventTransformer] = []

        if let reverse = scheme.scrolling.$reverse {
            let vertical = reverse.vertical ?? false
            let horizontal = reverse.horizontal ?? false

            if vertical || horizontal {
                eventTransformer.append(ReverseScrollingTransformer(vertically: vertical, horizontally: horizontal))
            }
        }

        if let distance = scheme.scrolling.distance.horizontal {
            eventTransformer.append(LinearScrollingHorizontalTransformer(distance: distance))
        }

        if let distance = scheme.scrolling.distance.vertical {
            eventTransformer.append(LinearScrollingVerticalTransformer(distance: distance))
        }

        if scheme.scrolling.acceleration.vertical ?? 1 != 1 || scheme.scrolling.acceleration.horizontal ?? 1 != 1 ||
            scheme.scrolling.speed.vertical ?? 0 != 0 || scheme.scrolling.speed.horizontal ?? 0 != 0 {
            eventTransformer
                .append(ScrollingAccelerationSpeedAdjustmentTransformer(acceleration: scheme.scrolling.acceleration,
                                                                        speed: scheme.scrolling.speed))
        }

        eventTransformerCache.setValue(eventTransformer, forKey: cacheKey)

        return eventTransformer
    }
}
