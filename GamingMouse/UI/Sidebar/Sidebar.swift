// MIT License
// Copyright (c) 2021-2024 LinearMouse

import SwiftUI

struct Sidebar: View {
    var body: some View {
        VStack(spacing: 0) {
            SidebarItem(id: .scrolling,
                        imageName: "Scrolling",
                        text: "Scrolling")

            SidebarItem(id: .general,
                        imageName: "General",
                        text: "General")
        }
    }
}
