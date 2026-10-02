import SwiftUI

struct SettingsPreferencesView: View {
    @ObservedObject var vm: SettingsViewModel
    @ObservedObject var deviceInfo = MouseDeviceInfo.shared

    var body: some View {
        let l10n = vm.l10n

        VStack(spacing: 0) {
            headerBar(l10n: l10n)

            if deviceInfo.isConnected {
                connectedContent(l10n: l10n)
            } else {
                disconnectedView(l10n: l10n)
            }
        }
        .frame(width: 640, height: 630)
    }

    // MARK: - Header Bar
    private func headerBar(l10n: L10n) -> some View {
        HStack(spacing: 12) {
            // Title + Battery Badge / Status
            HStack(spacing: 8) {
                Image(systemName: "magicmouse")
                    .font(.system(size: 15))
                    .foregroundColor(deviceInfo.isConnected ? .accentColor : .secondary)

                Text(deviceInfo.isConnected ? deviceInfo.name : "Magic Mouse")
                    .font(.system(size: 14, weight: .bold))

                if deviceInfo.isConnected {
                    if deviceInfo.batteryLevel >= 0 {
                        HStack(spacing: 4) {
                            Image(systemName: batteryIcon(for: deviceInfo.batteryLevel))
                                .foregroundColor(deviceInfo.batteryLevel > 20 ? .primary : .red)
                            Text("\(deviceInfo.batteryLevel)%")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                        }
                        .foregroundColor(.secondary)
                    }
                } else {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 7, height: 7)
                        Text(deviceInfo.isBluetoothOn ? (vm.appLanguage == .vi ? "Chưa kết nối" : "Disconnected") : (vm.appLanguage == .vi ? "Bluetooth tắt" : "Bluetooth Off"))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Language Switcher Capsule [ 🇻🇳 VN | 🇺🇸 EN ]
            Picker("", selection: $vm.appLanguage) {
                Text("🇻🇳 VN").tag(Preferences.AppLanguage.vi)
                Text("🇺🇸 EN").tag(Preferences.AppLanguage.en)
            }
            .pickerStyle(SegmentedPickerStyle())
            .labelsHidden()
            .frame(width: 120)
            .transaction { $0.animation = nil }
        }
        .padding(.horizontal, 22)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Connected Content
    private func connectedContent(l10n: L10n) -> some View {
        VStack(spacing: 0) {
            // 2. Apple Dual-Card Preview Stage (Mouse + Animated Screen Demo)
            MagicMouseCanvasView(
                deviceInfo: deviceInfo,
                currentDemo: vm.hoveredDemo ?? vm.currentDemo,
                rightClickThreshold: vm.rightClickThreshold,
                edgeZoneWidth: vm.edgeZoneWidth,
                minTapY: vm.minTapY,
                l10n: l10n,
                gestureConfiguration: vm.gestureConfiguration
            )
            .padding(.horizontal, 22)
            .padding(.bottom, 14)

            // 3. Apple-style Full Width Segmented Tab Picker
            Picker("", selection: $vm.selectedTab) {
                Text(l10n.pointAndClick).tag(0)
                Text(l10n.edgeSliders).tag(1)
                Text(l10n.moreGestures).tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .labelsHidden()
            .padding(.horizontal, 22)
            .padding(.bottom, 14)

            Divider()

            // 4. Native macOS Settings List with OnHover Live Preview Trigger
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if vm.selectedTab == 0 {
                        pointAndClickTab(l10n: l10n)
                    } else if vm.selectedTab == 1 {
                        edgeSlidersTab(l10n: l10n)
                    } else {
                        moreGesturesTab(l10n: l10n)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 14)
            }

            Divider()

            // 5. Apple-style Bottom Action Buttons
            HStack(spacing: 12) {
                Spacer()

                Button(l10n.accessibilityBtn) {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                        NSWorkspace.shared.open(url)
                    }
                }

                Button(l10n.bluetoothBtn) {
                    openBluetoothSettings()
                }

                Button(action: {
                    showAboutDialog()
                }) {
                    Image(systemName: "questionmark")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 16, height: 16)
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))
        }
    }

    // MARK: - Disconnected / Bluetooth Off Guidance
    private func disconnectedView(l10n: L10n) -> some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                // Top Icon / Visual
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 88, height: 88)

                    Image(systemName: deviceInfo.isBluetoothOn ? "magicmouse" : "antenna.radiowaves.left.and.right")
                        .font(.system(size: 38))
                        .foregroundColor(.accentColor)
                }

                // Headings
                VStack(spacing: 6) {
                    Text(deviceInfo.isBluetoothOn ? l10n.mouseNotConnectedTitle : l10n.bluetoothOffTitle)
                        .font(.system(size: 18, weight: .bold))

                    Text(deviceInfo.isBluetoothOn ? l10n.mouseNotConnectedDesc : l10n.bluetoothOffDesc)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 440)
                }

                if deviceInfo.isBluetoothOn {
                    // Guidance steps
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 12) {
                            Text("1")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color.accentColor))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(l10n.stepPowerOnTitle)
                                    .font(.system(size: 13, weight: .semibold))
                                Text(l10n.stepPowerOnDesc)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Divider()

                        HStack(alignment: .top, spacing: 12) {
                            Text("2")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color.accentColor))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(l10n.stepConnectTitle)
                                    .font(.system(size: 13, weight: .semibold))
                                Text(l10n.stepConnectDesc)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(14)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                    .frame(maxWidth: 440)
                }

                // Action buttons
                HStack(spacing: 12) {
                    Button(action: {
                        openBluetoothSettings()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.forward.app")
                            Text(l10n.openBluetoothSettingsBtn)
                        }
                        .font(.system(size: 13, weight: .medium))
                    }
                    .keyboardShortcut(.defaultAction)

                    Button(action: {
                        deviceInfo.refresh()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                            Text(l10n.retryScanBtn)
                        }
                        .font(.system(size: 13))
                    }
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 28)

            Spacer()

            Divider()

            // Bottom bar in disconnected state
            HStack {
                Spacer()

                Button(action: {
                    showAboutDialog()
                }) {
                    Image(systemName: "questionmark")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 16, height: 16)
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))
        }
    }

    private func openBluetoothSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.BluetoothSettings") {
            if NSWorkspace.shared.open(url) { return }
        }
        if let fallbackUrl = URL(string: "x-apple.systempreferences:com.apple.preference.Bluetooth") {
            NSWorkspace.shared.open(fallbackUrl)
        }
    }

    // MARK: - Tab 1: Trỏ & Bấm (Point & Click)

    private func pointAndClickTab(l10n: L10n) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Tap to Click
            settingRow(demo: .tapToClick) {
                Toggle(isOn: $vm.isTapToClickEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(l10n.tapToClickTitle)
                            .font(.system(size: 13, weight: .medium))
                        Text(l10n.tapToClickDesc)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }

            Divider()

            // Secondary Click
            settingRow(demo: .secondaryClick) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(l10n.secondaryClickTitle)
                                .font(.system(size: 13, weight: .medium))
                            Text(l10n.secondaryClickDesc)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Picker("", selection: $vm.secondaryClickMode) {
                            ForEach(Preferences.SecondaryClickMode.allCases) { mode in
                                Text(mode.title(l10n: l10n)).tag(mode)
                            }
                        }
                        .pickerStyle(PopUpButtonPickerStyle())
                        .frame(width: 170)
                    }

                    if vm.secondaryClickMode != .none {
                        HStack {
                            let leftPct = Int(vm.rightClickThreshold * 100)
                            let rightPct = 100 - leftPct
                            Text("\(leftPct)% \(l10n.leftPct) / \(rightPct)% \(l10n.rightPct)")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        Slider(
                            value: Binding(
                                get: { Double(vm.rightClickThreshold) },
                                set: {
                                    let rounded = round($0 * 20) / 20
                                    vm.rightClickThreshold = Float(rounded)
                                }
                            ),
                            in: 0.40...0.85
                        )
                    }
                }
            }

            Divider()

            // Physical 2-Finger Click
            settingRow(demo: .twoFingerClick) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(l10n.twoFingerClickTitle)
                            .font(.system(size: 13, weight: .medium))
                        Text(l10n.twoFingerClickDesc)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Picker("", selection: $vm.gestureConfiguration.twoFingerClick) {
                        ForEach(GestureAction.compatible(with: .twoFingerClick)) { action in
                            Text(action.title(l10n: l10n)).tag(action)
                        }
                    }
                    .pickerStyle(PopUpButtonPickerStyle())
                    .frame(width: 220)
                }
            }

            Divider()

            // Tap Sensitivity
            settingRow(demo: .tapSensitivity) {
                HStack {
                    Text(l10n.tapSensitivityTitle)
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                    Picker("", selection: $vm.tapSensitivity) {
                        ForEach(Preferences.TapSensitivity.allCases, id: \.self) { item in
                            Text(item.title).tag(item)
                        }
                    }
                    .pickerStyle(PopUpButtonPickerStyle())
                    .frame(width: 250)
                }
            }

            Divider()

            // Palm Rejection Zone
            settingRow(demo: .palmRejection) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(l10n.palmRejectionTitle)
                            .font(.system(size: 13, weight: .medium))
                        Text(l10n.palmRejectionDesc)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Picker("", selection: $vm.minTapY) {
                        ForEach(Preferences.tapZoneChoices, id: \.minTapY) { choice in
                            Text(choice.title).tag(choice.minTapY)
                        }
                    }
                    .pickerStyle(PopUpButtonPickerStyle())
                    .frame(width: 210)
                }
            }
        }
    }

    // MARK: - Tab 2: Vuốt Viền (Edge Sliders)

    private func edgeSlidersTab(l10n: L10n) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Enable Edge Sliders Toggle
            settingRow(demo: vm.gestureConfiguration.leftEdge != .none ? .leftEdgeSlider : .rightEdgeSlider) {
                Toggle(isOn: $vm.isEdgeSlidersEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(l10n.edgeSlidersTitle)
                            .font(.system(size: 13, weight: .medium))
                        Text(l10n.edgeSlidersDesc)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }

            if vm.isEdgeSlidersEnabled {
                Divider()

                // Left Edge Action
                settingRow(demo: .leftEdgeSlider) {
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: vm.gestureConfiguration.leftEdge.iconName)
                                .foregroundColor(vm.gestureConfiguration.leftEdge.edgeIconColor)
                                .frame(width: 18)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(l10n.leftEdgeTitle)
                                    .font(.system(size: 13, weight: .medium))
                                Text(l10n.leftEdgeDesc)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Picker("", selection: $vm.gestureConfiguration.leftEdge) {
                            ForEach(GestureAction.compatible(with: .leftEdge)) { action in
                                Text(action.title(l10n: l10n)).tag(action)
                            }
                        }
                        .pickerStyle(PopUpButtonPickerStyle())
                        .frame(width: 190)
                    }
                }

                Divider()

                // Right Edge Action
                settingRow(demo: .rightEdgeSlider) {
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: vm.gestureConfiguration.rightEdge.iconName)
                                .foregroundColor(vm.gestureConfiguration.rightEdge.edgeIconColor)
                                .frame(width: 18)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(l10n.rightEdgeTitle)
                                    .font(.system(size: 13, weight: .medium))
                                Text(l10n.rightEdgeDesc)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Picker("", selection: $vm.gestureConfiguration.rightEdge) {
                            ForEach(GestureAction.compatible(with: .rightEdge)) { action in
                                Text(action.title(l10n: l10n)).tag(action)
                            }
                        }
                        .pickerStyle(PopUpButtonPickerStyle())
                        .frame(width: 190)
                    }
                }

                Divider()

                // Edge Zone Width
                settingRow(demo: .edgeWidth) {
                    HStack {
                        Text(l10n.edgeWidthTitle)
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                        Picker("", selection: $vm.edgeZoneWidth) {
                            ForEach(Preferences.edgeZoneChoices, id: \.width) { choice in
                                Text(choice.title).tag(choice.width)
                            }
                        }
                        .pickerStyle(PopUpButtonPickerStyle())
                        .frame(width: 220)
                    }
                }
            }
        }
    }

    // MARK: - Tab 3: Cử chỉ khác (More Gestures)

    private func moreGesturesTab(l10n: L10n) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 1. 3-Finger Tap / Physical Click
            settingRow(demo: .threeFingerTap) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(l10n.threeFingerTapTitle)
                            .font(.system(size: 13, weight: .medium))
                        Text(l10n.threeFingerTapDesc)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Picker("", selection: $vm.gestureConfiguration.threeFingerTap) {
                        ForEach(GestureAction.compatible(with: .threeFingerTap)) { action in
                            Text(action.title(l10n: l10n)).tag(action)
                        }
                    }
                    .pickerStyle(PopUpButtonPickerStyle())
                    .frame(width: 220)
                }
            }

            Divider()

            // 2. 3-Finger Swipe
            settingRow(demo: .threeFingerSwipe) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(l10n.threeFingerSwipeTitle)
                                .font(.system(size: 13, weight: .medium))
                            Text(l10n.threeFingerSwipeDesc)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Picker("", selection: $vm.gestureConfiguration.threeFingerSwipe) {
                            ForEach(GestureAction.compatible(with: .threeFingerSwipe)) { action in
                                Text(action.title(l10n: l10n)).tag(action)
                            }
                        }
                        .pickerStyle(PopUpButtonPickerStyle())
                        .frame(width: 220)
                    }

                    if vm.gestureConfiguration.threeFingerSwipe != .none {
                        Picker(l10n.swipeDirection, selection: $vm.gestureConfiguration.isThreeFingerNaturalSwipe) {
                            Text(l10n.naturalSwipe).tag(true)
                            Text(l10n.directSwipe).tag(false)
                        }
                        .pickerStyle(RadioGroupPickerStyle())
                        .padding(.leading, 12)
                    }
                }
            }

            Divider()

            // 3. 2-Finger Tap
            settingRow(demo: .twoFingerTap) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(l10n.twoFingerTapTitle)
                            .font(.system(size: 13, weight: .medium))
                        Text(l10n.twoFingerTapDesc)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Picker("", selection: $vm.gestureConfiguration.twoFingerTap) {
                        ForEach(GestureAction.compatible(with: .twoFingerTap)) { action in
                            Text(action.title(l10n: l10n)).tag(action)
                        }
                    }
                    .pickerStyle(PopUpButtonPickerStyle())
                    .frame(width: 220)
                }
            }

            Divider()

            // 4. Smart Zoom (Double Tap)
            settingRow(demo: .smartZoom) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(l10n.smartZoomTitle)
                            .font(.system(size: 13, weight: .medium))
                        Text(l10n.smartZoomDesc)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Picker("", selection: $vm.gestureConfiguration.doubleTap) {
                        ForEach(GestureAction.compatible(with: .doubleTap)) { action in
                            Text(action.title(l10n: l10n)).tag(action)
                        }
                    }
                    .pickerStyle(PopUpButtonPickerStyle())
                    .frame(width: 220)
                }
            }

            Divider()

            // 5. 2-Finger Pinch
            settingRow(demo: .pinchZoom) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(l10n.pinchTitle)
                            .font(.system(size: 13, weight: .medium))
                        Text(l10n.pinchDesc)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Picker("", selection: $vm.gestureConfiguration.pinch) {
                        ForEach(GestureAction.compatible(with: .pinch)) { action in
                            Text(action.title(l10n: l10n)).tag(action)
                        }
                    }
                    .pickerStyle(PopUpButtonPickerStyle())
                    .frame(width: 220)
                }
            }

            Divider()

            // 6. 2-Finger Move (Push/Pull)
            settingRow(demo: .moveZoom) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(l10n.twoFingerMoveTitle)
                            .font(.system(size: 13, weight: .medium))
                        Text(l10n.twoFingerMoveDesc)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Picker("", selection: $vm.gestureConfiguration.twoFingerMove) {
                        ForEach(GestureAction.compatible(with: .twoFingerMove)) { action in
                            Text(action.title(l10n: l10n)).tag(action)
                        }
                    }
                    .pickerStyle(PopUpButtonPickerStyle())
                    .frame(width: 220)
                }
            }

            Divider()

            // 7. 2-Finger Swipe Up
            settingRow(demo: .twoFingerSwipe) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(l10n.twoFingerSwipeUpTitle)
                            .font(.system(size: 13, weight: .medium))
                        Text(l10n.twoFingerSwipeUpDesc)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Picker("", selection: $vm.gestureConfiguration.twoFingerSwipeUp) {
                        ForEach(GestureAction.compatible(with: .twoFingerSwipeUp)) { action in
                            Text(action.title(l10n: l10n)).tag(action)
                        }
                    }
                    .pickerStyle(PopUpButtonPickerStyle())
                    .frame(width: 220)
                }
            }

            Divider()

            // 8. 2-Finger Swipe Down
            settingRow(demo: .twoFingerSwipe) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(l10n.twoFingerSwipeDownTitle)
                            .font(.system(size: 13, weight: .medium))
                        Text(l10n.twoFingerSwipeDownDesc)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Picker("", selection: $vm.gestureConfiguration.twoFingerSwipeDown) {
                        ForEach(GestureAction.compatible(with: .twoFingerSwipeDown)) { action in
                            Text(action.title(l10n: l10n)).tag(action)
                        }
                    }
                    .pickerStyle(PopUpButtonPickerStyle())
                    .frame(width: 220)
                }
            }

            Divider()

            // 9. Virtual Trackpad Mode
            settingRow(demo: .virtualTrackpad) {
                Toggle(isOn: $vm.isVirtualTrackpadMode) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(l10n.virtualTrackpadModeTitle)
                            .font(.system(size: 13, weight: .medium))
                        Text(l10n.virtualTrackpadModeDesc)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Row Helper with Hover Interaction

    @ViewBuilder
    private func settingRow<Content: View>(demo: AppleGestureDemo, @ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(vm.hoveredDemo == demo ? Color.primary.opacity(0.05) : Color.clear)
            )
            .contentShape(Rectangle())
            .onHover { isHovered in
                if isHovered {
                    vm.hoveredDemo = demo
                    vm.currentDemo = demo
                } else if vm.hoveredDemo == demo {
                    vm.hoveredDemo = nil
                }
            }
    }

    private func batteryIcon(for level: Int) -> String {
        switch level {
        case 75...100: return "battery.100"
        case 50..<75: return "battery.75"
        case 25..<50: return "battery.50"
        case 10..<25: return "battery.25"
        default: return "battery.0"
        }
    }

    private func showAboutDialog() {
        let alert = NSAlert()
        alert.messageText = "MagicGlide"
        alert.informativeText = "Trackpad gestures for Apple Magic Mouse\nVersion 1.0.0"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
