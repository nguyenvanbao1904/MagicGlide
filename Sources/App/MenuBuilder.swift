import Cocoa

/// Builds and manages the NSMenu for the system status bar item.
final class MenuBuilder {
    weak var target: AppDelegate?

    private(set) weak var accessibilityStatusItem: NSMenuItem?
    private(set) weak var tapToClickStatusItem: NSMenuItem?
    private(set) weak var dragLockStatusItem: NSMenuItem?
    private(set) weak var edgeSlidersStatusItem: NSMenuItem?
    private(set) weak var threeFingerTapStatusItem: NSMenuItem?
    private(set) weak var threeFingerSwipeStatusItem: NSMenuItem?
    private(set) weak var smartZoomStatusItem: NSMenuItem?
    private(set) weak var pinchZoomStatusItem: NSMenuItem?
    private(set) weak var moveZoomStatusItem: NSMenuItem?
    private(set) weak var trackpadModeStatusItem: NSMenuItem?

    init(target: AppDelegate) {
        self.target = target
    }

    func buildMenu(isTrusted: Bool) -> NSMenu {
        let menu = NSMenu()

        // 0. Settings Window
        let settingsItem = NSMenuItem(
            title: "MagicGlide Settings…",
            action: #selector(AppDelegate.openSettingsWindow),
            keyEquivalent: ","
        )
        settingsItem.target = target
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        // 1. Accessibility Status
        let accessTitle = isTrusted ? "Accessibility: Granted ✓" : "⚠️ Accessibility: NOT GRANTED (Click to Fix)"
        let accessItem = NSMenuItem(
            title: accessTitle,
            action: #selector(AppDelegate.showAccessibilityInstructions),
            keyEquivalent: ""
        )
        accessItem.target = target
        menu.addItem(accessItem)
        self.accessibilityStatusItem = accessItem

        menu.addItem(NSMenuItem.separator())

        // 2. Tap to Click
        let tapToClickItem = NSMenuItem(
            title: Preferences.isTapToClickEnabled ? "Tap to Click: Enabled" : "Tap to Click: Disabled",
            action: #selector(AppDelegate.toggleTapToClick),
            keyEquivalent: ""
        )
        tapToClickItem.state = Preferences.isTapToClickEnabled ? .on : .off
        tapToClickItem.target = target
        menu.addItem(tapToClickItem)
        self.tapToClickStatusItem = tapToClickItem

        // 3. Drag Lock / Two-Finger Tap Status
        let dragLockItem = NSMenuItem(title: twoFingerTapTitle(), action: nil, keyEquivalent: "")
        dragLockItem.isEnabled = false
        menu.addItem(dragLockItem)
        self.dragLockStatusItem = dragLockItem

        // 4. Edge Sliders
        let edgeSlidersItem = NSMenuItem(
            title: edgeSlidersTitle(),
            action: #selector(AppDelegate.toggleEdgeSliders),
            keyEquivalent: ""
        )
        edgeSlidersItem.state = Preferences.isEdgeSlidersEnabled ? .on : .off
        edgeSlidersItem.target = target
        menu.addItem(edgeSlidersItem)
        self.edgeSlidersStatusItem = edgeSlidersItem

        // 5. 3-Finger Tap
        let threeFingerTapItem = NSMenuItem(
            title: threeFingerTapTitle(),
            action: #selector(AppDelegate.toggleThreeFingerTap),
            keyEquivalent: ""
        )
        threeFingerTapItem.state = (Preferences.isThreeFingerTapEnabled && Preferences.gestureConfiguration.threeFingerTap != .none) ? .on : .off
        threeFingerTapItem.target = target
        menu.addItem(threeFingerTapItem)
        self.threeFingerTapStatusItem = threeFingerTapItem

        // 6. 3-Finger Swipe
        let threeFingerSwipeItem = NSMenuItem(
            title: threeFingerSwipeTitle(),
            action: #selector(AppDelegate.toggleThreeFingerSwipe),
            keyEquivalent: ""
        )
        threeFingerSwipeItem.state = (Preferences.isThreeFingerSwipeEnabled && Preferences.gestureConfiguration.threeFingerSwipe != .none) ? .on : .off
        threeFingerSwipeItem.target = target
        menu.addItem(threeFingerSwipeItem)
        self.threeFingerSwipeStatusItem = threeFingerSwipeItem

        // 7. Double Tap / Smart Zoom
        let smartZoomItem = NSMenuItem(
            title: smartZoomTitle(),
            action: #selector(AppDelegate.toggleSmartZoom),
            keyEquivalent: ""
        )
        smartZoomItem.state = (Preferences.isSmartZoomEnabled && Preferences.gestureConfiguration.doubleTap != .none) ? .on : .off
        smartZoomItem.target = target
        menu.addItem(smartZoomItem)
        self.smartZoomStatusItem = smartZoomItem

        // 8. Pinch
        let pinchZoomItem = NSMenuItem(
            title: pinchTitle(),
            action: #selector(AppDelegate.togglePinchZoom),
            keyEquivalent: ""
        )
        pinchZoomItem.state = (Preferences.isPinchZoomEnabled && Preferences.gestureConfiguration.pinch != .none) ? .on : .off
        pinchZoomItem.target = target
        menu.addItem(pinchZoomItem)
        self.pinchZoomStatusItem = pinchZoomItem

        // 9. Move
        let moveZoomItem = NSMenuItem(
            title: twoFingerMoveTitle(),
            action: #selector(AppDelegate.toggleMoveZoom),
            keyEquivalent: ""
        )
        moveZoomItem.state = (Preferences.isMoveZoomEnabled && Preferences.gestureConfiguration.twoFingerMove != .none) ? .on : .off
        moveZoomItem.target = target
        menu.addItem(moveZoomItem)
        self.moveZoomStatusItem = moveZoomItem

        // 10. Virtual Trackpad Mode
        let trackpadModeItem = NSMenuItem(
            title: trackpadModeTitle(),
            action: #selector(AppDelegate.toggleTrackpadMode),
            keyEquivalent: ""
        )
        trackpadModeItem.state = TrackpadModeController.shared.isActive ? .on : .off
        trackpadModeItem.target = target
        menu.addItem(trackpadModeItem)
        self.trackpadModeStatusItem = trackpadModeItem

        menu.addItem(NSMenuItem.separator())

        // Submenus
        menu.addItem(buildRightClickZoneSubmenu())
        menu.addItem(buildTapSensitivitySubmenu())
        menu.addItem(buildTapZoneSubmenu())
        menu.addItem(buildEdgeZoneWidthSubmenu())
        menu.addItem(buildThreeFingerDirectionSubmenu())

        menu.addItem(NSMenuItem.separator())

        let accessibilityHelpItem = NSMenuItem(
            title: "Accessibility Instructions…",
            action: #selector(AppDelegate.showAccessibilityInstructions),
            keyEquivalent: ""
        )
        accessibilityHelpItem.target = target
        menu.addItem(accessibilityHelpItem)

        menu.addItem(NSMenuItem.separator())
        let aboutItem = NSMenuItem(title: "About MagicGlide", action: #selector(AppDelegate.showAbout), keyEquivalent: "")
        aboutItem.target = target
        menu.addItem(aboutItem)

        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "Quit MagicGlide", action: #selector(AppDelegate.quit), keyEquivalent: "q")
        quitItem.target = target
        menu.addItem(quitItem)

        return menu
    }

    private func buildRightClickZoneSubmenu() -> NSMenuItem {
        let parentItem = NSMenuItem(title: "Right Click Zone", action: nil, keyEquivalent: "")
        let submenu = NSMenu()

        var choices = Preferences.rightClickThresholdChoices
        let current = Preferences.rightClickThreshold
        if !choices.contains(current) {
            choices.append(current)
            choices.sort()
        }

        for threshold in choices {
            let leftPct = Int(threshold * 100)
            let rightPct = 100 - leftPct
            let title = "\(leftPct)% Left / \(rightPct)% Right"
            let item = NSMenuItem(title: title, action: #selector(AppDelegate.selectRightClickZone(_:)), keyEquivalent: "")
            item.target = target
            item.representedObject = threshold
            item.state = threshold == current ? .on : .off
            submenu.addItem(item)
        }

        parentItem.submenu = submenu
        return parentItem
    }

    private func buildTapSensitivitySubmenu() -> NSMenuItem {
        let parentItem = NSMenuItem(title: "Tap Sensitivity", action: nil, keyEquivalent: "")
        let submenu = NSMenu()
        let current = Preferences.tapSensitivity

        for sensitivity in Preferences.TapSensitivity.allCases {
            let item = NSMenuItem(title: sensitivity.title, action: #selector(AppDelegate.selectTapSensitivity(_:)), keyEquivalent: "")
            item.target = target
            item.representedObject = sensitivity
            item.state = sensitivity == current ? .on : .off
            submenu.addItem(item)
        }

        parentItem.submenu = submenu
        return parentItem
    }

    private func buildTapZoneSubmenu() -> NSMenuItem {
        let parentItem = NSMenuItem(title: "Tap Zone (Palm Rejection)", action: nil, keyEquivalent: "")
        let submenu = NSMenu()
        let current = Preferences.minTapY

        for choice in Preferences.tapZoneChoices {
            let item = NSMenuItem(title: choice.title, action: #selector(AppDelegate.selectTapZone(_:)), keyEquivalent: "")
            item.target = target
            item.representedObject = choice.minTapY
            item.state = abs(choice.minTapY - current) < 0.01 ? .on : .off
            submenu.addItem(item)
        }

        parentItem.submenu = submenu
        return parentItem
    }

    private func buildEdgeZoneWidthSubmenu() -> NSMenuItem {
        let parentItem = NSMenuItem(title: "Edge Slider Zone", action: nil, keyEquivalent: "")
        let submenu = NSMenu()
        let current = Preferences.edgeZoneWidth

        for choice in Preferences.edgeZoneChoices {
            let item = NSMenuItem(title: choice.title, action: #selector(AppDelegate.selectEdgeZoneWidth(_:)), keyEquivalent: "")
            item.target = target
            item.representedObject = choice.width
            item.state = abs(choice.width - current) < 0.01 ? .on : .off
            submenu.addItem(item)
        }

        parentItem.submenu = submenu
        return parentItem
    }

    private func buildThreeFingerDirectionSubmenu() -> NSMenuItem {
        let parentItem = NSMenuItem(title: "3-Finger Swipe Direction", action: nil, keyEquivalent: "")
        let submenu = NSMenu()

        let naturalItem = NSMenuItem(
            title: "Natural (Swipe Left: Next, Swipe Right: Prev)",
            action: #selector(AppDelegate.selectSwipeDirection(_:)),
            keyEquivalent: ""
        )
        naturalItem.target = target
        naturalItem.representedObject = true
        naturalItem.state = Preferences.isThreeFingerNaturalSwipe ? .on : .off
        submenu.addItem(naturalItem)

        let directItem = NSMenuItem(
            title: "Direct (Swipe Right: Next, Swipe Left: Prev)",
            action: #selector(AppDelegate.selectSwipeDirection(_:)),
            keyEquivalent: ""
        )
        directItem.target = target
        directItem.representedObject = false
        directItem.state = !Preferences.isThreeFingerNaturalSwipe ? .on : .off
        submenu.addItem(directItem)

        parentItem.submenu = submenu
        return parentItem
    }

    // MARK: - Dynamic Menu Titles

    private func threeFingerTapTitle() -> String {
        let l10n = L10n(lang: Preferences.appLanguage)
        guard Preferences.isThreeFingerTapEnabled && Preferences.gestureConfiguration.threeFingerTap != .none else {
            return "3-Finger Tap: Disabled"
        }
        return "3-Finger Tap: \(Preferences.gestureConfiguration.threeFingerTap.title(l10n: l10n))"
    }

    private func threeFingerSwipeTitle() -> String {
        let l10n = L10n(lang: Preferences.appLanguage)
        guard Preferences.isThreeFingerSwipeEnabled && Preferences.gestureConfiguration.threeFingerSwipe != .none else {
            return "3-Finger Swipe: Disabled"
        }
        return "3-Finger Swipe: \(Preferences.gestureConfiguration.threeFingerSwipe.title(l10n: l10n))"
    }

    private func twoFingerTapTitle() -> String {
        let l10n = L10n(lang: Preferences.appLanguage)
        if Preferences.gestureConfiguration.twoFingerTap == .dragLock {
            return "Drag Lock: Unlocked (Two-Finger Tap)"
        } else if Preferences.gestureConfiguration.twoFingerTap == .none {
            return "2-Finger Tap: Disabled"
        } else {
            return "2-Finger Tap: \(Preferences.gestureConfiguration.twoFingerTap.title(l10n: l10n))"
        }
    }

    private func edgeSlidersTitle() -> String {
        guard Preferences.isEdgeSlidersEnabled else { return "Edge Sliders: Disabled" }
        let l10n = L10n(lang: Preferences.appLanguage)
        return "Edge Sliders: Enabled (L: \(Preferences.gestureConfiguration.leftEdge.title(l10n: l10n)), R: \(Preferences.gestureConfiguration.rightEdge.title(l10n: l10n)))"
    }

    private func smartZoomTitle() -> String {
        let l10n = L10n(lang: Preferences.appLanguage)
        guard Preferences.isSmartZoomEnabled && Preferences.gestureConfiguration.doubleTap != .none else {
            return "Double Tap: Disabled (Instant Click)"
        }
        return "Double Tap: \(Preferences.gestureConfiguration.doubleTap.title(l10n: l10n))"
    }

    private func pinchTitle() -> String {
        let l10n = L10n(lang: Preferences.appLanguage)
        guard Preferences.isPinchZoomEnabled && Preferences.gestureConfiguration.pinch != .none else {
            return "Pinch: Disabled"
        }
        return "Pinch: \(Preferences.gestureConfiguration.pinch.title(l10n: l10n))"
    }

    private func twoFingerMoveTitle() -> String {
        let l10n = L10n(lang: Preferences.appLanguage)
        guard Preferences.isMoveZoomEnabled && Preferences.gestureConfiguration.twoFingerMove != .none else {
            return "2-Finger Move: Disabled"
        }
        return "2-Finger Move: \(Preferences.gestureConfiguration.twoFingerMove.title(l10n: l10n))"
    }

    private func trackpadModeTitle() -> String {
        return TrackpadModeController.shared.isActive
            ? "Virtual Trackpad Mode: On"
            : "Virtual Trackpad Mode: Off"
    }

    func updateAllMenuItems() {
        let tap = Preferences.isTapToClickEnabled
        tapToClickStatusItem?.state = tap ? .on : .off
        tapToClickStatusItem?.title = tap ? "Tap to Click: Enabled" : "Tap to Click: Disabled"

        let edge = Preferences.isEdgeSlidersEnabled
        edgeSlidersStatusItem?.state = edge ? .on : .off
        edgeSlidersStatusItem?.title = edgeSlidersTitle()

        let threeTap = Preferences.isThreeFingerTapEnabled && Preferences.gestureConfiguration.threeFingerTap != .none
        threeFingerTapStatusItem?.state = threeTap ? .on : .off
        threeFingerTapStatusItem?.title = threeFingerTapTitle()

        let threeSwipe = Preferences.isThreeFingerSwipeEnabled && Preferences.gestureConfiguration.threeFingerSwipe != .none
        threeFingerSwipeStatusItem?.state = threeSwipe ? .on : .off
        threeFingerSwipeStatusItem?.title = threeFingerSwipeTitle()

        if Preferences.gestureConfiguration.twoFingerTap != .dragLock {
            dragLockStatusItem?.title = twoFingerTapTitle()
        }

        let smart = Preferences.isSmartZoomEnabled && Preferences.gestureConfiguration.doubleTap != .none
        smartZoomStatusItem?.state = smart ? .on : .off
        smartZoomStatusItem?.title = smartZoomTitle()

        let pinch = Preferences.isPinchZoomEnabled && Preferences.gestureConfiguration.pinch != .none
        pinchZoomStatusItem?.state = pinch ? .on : .off
        pinchZoomStatusItem?.title = pinchTitle()

        let move = Preferences.isMoveZoomEnabled && Preferences.gestureConfiguration.twoFingerMove != .none
        moveZoomStatusItem?.state = move ? .on : .off
        moveZoomStatusItem?.title = twoFingerMoveTitle()

        let trackpad = TrackpadModeController.shared.isActive
        trackpadModeStatusItem?.state = trackpad ? .on : .off
        trackpadModeStatusItem?.title = trackpadModeTitle()
    }
}
