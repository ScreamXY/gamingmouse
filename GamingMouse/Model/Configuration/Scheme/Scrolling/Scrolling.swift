// MIT License
// Copyright (c) 2021-2024 LinearMouse

import Foundation

extension Scheme {
    struct Scrolling: Codable, Equatable, ImplicitInitable {
        @ImplicitOptional var reverse: Bidirectional<Bool>
        @ImplicitOptional var distance: Bidirectional<Distance>
        @ImplicitOptional var acceleration: Bidirectional<Decimal>
        @ImplicitOptional var speed: Bidirectional<Decimal>

        init() {}

        init(reverse: Bidirectional<Bool>? = nil,
             distance: Bidirectional<Distance>? = nil,
             acceleration: Bidirectional<Decimal>? = nil,
             speed: Bidirectional<Decimal>? = nil) {
            $reverse = reverse
            $distance = distance
            $acceleration = acceleration
            $speed = speed
        }
    }
}

extension Scheme.Scrolling {
    func merge(into scrolling: inout Self) {
        $reverse?.merge(into: &scrolling.reverse)
        $distance?.merge(into: &scrolling.distance)
        $acceleration?.merge(into: &scrolling.acceleration)
        $speed?.merge(into: &scrolling.speed)
    }

    func merge(into scrolling: inout Self?) {
        if scrolling == nil {
            scrolling = Self()
        }

        merge(into: &scrolling!)
    }
}
