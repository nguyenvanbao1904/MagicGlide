import Cocoa
import ApplicationServices

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    // Pipeline nodes — owned here, wired with closures
    private var multitouchSource: MultitouchSource?
    private var gestureEngine: GestureEngine?
    private var gestureDispatcher: GestureDispatcher?
    private var menuBuilder: MenuBuilder?
    let eventTapController = EventTapController()

    private var hasStartedMultitouch = false
    private var hasRequestedAccessibilityPrompt = false
    private var isWaitingForAccessibility = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBuilder = MenuBuilder(target: self)
        setupMenuBar()

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleSystemWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePreferencesDidChange),
            name: .preferencesDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTrackpadModeDidChange),
            name: .trackpadModeDidChange,
            object: nil
        )

        ensureAccessibilityAndStart()
        SettingsWindowController.shared.show()
    }

    @objc private func handlePreferencesDidChange() {
        DispatchQueue.main.async { [weak self] in
            self?.menuBuilder?.updateAllMenuItems()
        }
    }

    @objc private func handleTrackpadModeDidChange() {
        DispatchQueue.main.async { [weak self] in
            self?.menuBuilder?.updateAllMenuItems()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        multitouchSource?.stop()
        eventTapController.tearDown()
    }

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "computermouse.fill", accessibilityDescription: "MagicGlide")
        }

        let isTrusted = AXIsProcessTrusted()
        statusItem?.menu = menuBuilder?.buildMenu(isTrusted: isTrusted)
    }

    // MARK: - Menu Actions

    @objc func openSettingsWindow() {
        SettingsWindowController.shared.show()
    }

    @objc func toggleTapToClick() {
        let newState = !Preferences.isTapToClickEnabled
        Preferences.isTapToClickEnabled = newState
        menuBuilder?.tapToClickStatusItem?.state = newState ? .on : .off
        menuBuilder?.tapToClickStatusItem?.title = newState
            ? "Tap to Click: Enabled"
            : "Tap to Click: Disabled"
    }

    @objc func toggleThreeFingerTap() {
        let newState = !Preferences.isThreeFingerTapEnabled
        Preferences.setThreeFingerTapEnabledSilently(newState)
        var config = Preferences.gestureConfiguration
        if !newState {
            config.threeFingerTap = .none
        } else if config.threeFingerTap == .none {
            config.threeFingerTap = .middleClick
        }
        Preferences.gestureConfiguration = config
        menuBuilder?.updateAllMenuItems()
    }

    @objc func toggleThreeFingerSwipe() {
        let newState = !Preferences.isThreeFingerSwipeEnabled
        Preferences.setThreeFingerSwipeEnabledSilently(newState)
        var config = Preferences.gestureConfiguration
        if !newState {
            config.threeFingerSwipe = .none
        } else if config.threeFingerSwipe == .none {
            config.threeFingerSwipe = .switchTabs
        }
        Preferences.gestureConfiguration = config
        menuBuilder?.updateAllMenuItems()
    }

    @objc func toggleEdgeSliders() {
        Preferences.isEdgeSlidersEnabled = !Preferences.isEdgeSlidersEnabled
        menuBuilder?.updateAllMenuItems()
    }

    @objc func toggleSmartZoom() {
        let newState = !Preferences.isSmartZoomEnabled
        Preferences.setSmartZoomEnabledSilently(newState)
        var config = Preferences.gestureConfiguration
        if !newState {
            config.doubleTap = .none
        } else if config.doubleTap == .none {
            config.doubleTap = .smartZoom
        }
        Preferences.gestureConfiguration = config
        menuBuilder?.updateAllMenuItems()
    }

    @objc func togglePinchZoom() {
        let newState = !Preferences.isPinchZoomEnabled
        Preferences.isPinchZoomEnabled = newState
        menuBuilder?.pinchZoomStatusItem?.state = newState ? .on : .off
        menuBuilder?.pinchZoomStatusItem?.title = newState
            ? "Pinch to Zoom: Enabled (2-Finger)"
            : "Pinch to Zoom: Disabled"
    }

    @objc func toggleMoveZoom() {
        let newState = !Preferences.isMoveZoomEnabled
        Preferences.isMoveZoomEnabled = newState
        menuBuilder?.moveZoomStatusItem?.state = newState ? .on : .off
        menuBuilder?.moveZoomStatusItem?.title = newState
            ? "Move to Zoom: Enabled (2-Finger Push/Pull)"
            : "Move to Zoom: Disabled"
    }

    @objc func toggleTrackpadMode() {
        TrackpadModeController.shared.toggle()
        menuBuilder?.updateAllMenuItems()
    }

    @objc func selectRightClickZone(_ sender: NSMenuItem) {
        guard let threshold = sender.representedObject as? Float else { return }
        Preferences.rightClickThreshold = threshold
        guard let submenu = sender.menu else { return }
        for item in submenu.items {
            if let v = item.representedObject as? Float { item.state = abs(v - threshold) < 0.01 ? .on : .off }
        }
    }

    @objc func selectTapSensitivity(_ sender: NSMenuItem) {
        guard let sensitivity = sender.representedObject as? Preferences.TapSensitivity else { return }
        Preferences.tapSensitivity = sensitivity
        guard let submenu = sender.menu else { return }
        for item in submenu.items {
            if let v = item.representedObject as? Preferences.TapSensitivity { item.state = v == sensitivity ? .on : .off }
        }
    }

    @objc func selectTapZone(_ sender: NSMenuItem) {
        guard let minY = sender.representedObject as? Float else { return }
        Preferences.minTapY = minY
        guard let submenu = sender.menu else { return }
        for item in submenu.items {
            if let v = item.representedObject as? Float { item.state = abs(v - minY) < 0.01 ? .on : .off }
        }
    }

    @objc func selectEdgeZoneWidth(_ sender: NSMenuItem) {
        guard let width = sender.representedObject as? Float else { return }
        Preferences.edgeZoneWidth = width

        guard let submenu = sender.menu else { return }
        for item in submenu.items {
            if let choiceWidth = item.representedObject as? Float {
                item.state = abs(choiceWidth - width) < 0.01 ? .on : .off
            }
        }
    }

    @objc func selectSwipeDirection(_ sender: NSMenuItem) {
        guard let isNatural = sender.representedObject as? Bool else { return }
        Preferences.isThreeFingerNaturalSwipe = isNatural

        guard let submenu = sender.menu else { return }
        for item in submenu.items {
            if let val = item.representedObject as? Bool {
                item.state = val == isNatural ? .on : .off
            }
        }
    }

    @objc private func handleSystemWake() {
        eventTapController.setEnabled(true)
    }

    @objc func showAccessibilityInstructions() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "MagicGlide needs accessibility permissions to simulate clicks.\n\nPlease grant permission in:\nSystem Settings > Privacy & Security > Accessibility\n\nAfter enabling, return to MagicGlide. The app will begin working as soon as permission is granted."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Quit")
        alert.addButton(withTitle: "Cancel")

        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        } else if response == .alertSecondButtonReturn {
            NSApplication.shared.terminate(nil)
        }
    }

    @objc func showAbout() {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        let alert = NSAlert()
        alert.messageText = "MagicGlide"
        alert.informativeText = """
        Supercharge Magic Mouse with Trackpad-like Gestures

        • Tap-to-Click & Right Click Zone
        • Edge Sliders (Volume & Brightness with OSD)
        • Smart Zoom & 2-Finger Pinch / Move to Zoom
        • 3-Finger Middle Click & Tab Scrubbing
        • Virtual Trackpad Mode
        • Drag Lock (Two-Finger Tap)

        Version \(version)
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc func quit() {
        multitouchSource?.stop()
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Lifecycle & Initialization

    private func ensureAccessibilityAndStart() {
        let trusted = AXIsProcessTrusted()
        if trusted {
            menuBuilder?.accessibilityStatusItem?.title = "Accessibility: Granted ✓"
            startPipeline()
            return
        }
        menuBuilder?.accessibilityStatusItem?.title = "⚠️ Accessibility: NOT GRANTED (Click to Fix)"
        requestAccessibilityPermissionIfNeeded()
        waitForAccessibilityPermission()
    }

    /// Builds and wires the full pipeline:
    ///   MultitouchSource → GestureEngine → GestureDispatcher → ActionExecutor → System
    ///                                  ↑
    ///   EventTapController ────────────┘  (scroll suppression + physical click intercept)
    private func startPipeline() {
        guard !hasStartedMultitouch else { return }
        hasStartedMultitouch = true
        menuBuilder?.accessibilityStatusItem?.title = "Accessibility: Granted ✓"

        let store = UserDefaultsPreferenceStore.shared
        let executor = ActionExecutor()
        let dispatcher = GestureDispatcher(store: store, executor: executor)
        let engine = GestureEngine(store: store)
        let source = MultitouchSource()

        // ActionExecutor callbacks
        executor.onDragLockToggle = { [weak engine] in engine?.toggleDragLock() }
        executor.onToggleTrackpadMode = { TrackpadModeController.shared.toggle() }

        // Engine → Dispatcher (+ drag lock HUD)
        engine.onRecognized = { [weak self, weak dispatcher, weak engine] event in
            DispatchQueue.main.async {
                dispatcher?.handle(event)
                if case .dragLockToggle(let loc) = event, let engine {
                    let locked = engine.isDragLocked
                    ClickSynthesizer.synthesizeDragLock(at: loc, isLocked: locked)
                    self?.updateDragLockStatus(isLocked: locked)
                }
            }
        }

        // Source → Engine
        source.onTouches = { [weak engine] touches, count, ts in
            engine?.processTouches(touches, count: count, timestamp: ts)
        }
        source.onDeviceSetChanged = {
            DispatchQueue.main.async { MouseDeviceInfo.shared.refresh() }
        }

        // EventTapController → Engine
        let tapOK = eventTapController.setUp()
        eventTapController.queryEngine = { [weak engine] in engine }
        eventTapController.onPhysicalTwoFingerClick = { [weak dispatcher] loc in
            DispatchQueue.main.async { dispatcher?.handle(.physicalTwoFingerClick(location: loc)) }
        }
        eventTapController.onPhysicalThreeFingerClick = { [weak dispatcher] loc in
            DispatchQueue.main.async { dispatcher?.handle(.physicalThreeFingerClick(location: loc)) }
        }

        GestureEngine.current = engine
        gestureEngine = engine
        gestureDispatcher = dispatcher
        multitouchSource = source
        source.start()

        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil, queue: .main
        ) { _ in SystemControl.markMissionControlInactive() }

        if !tapOK {
            menuBuilder?.dragLockStatusItem?.title = "Drag Lock: Unavailable"
        }
    }

    private func updateDragLockStatus(isLocked: Bool) {
        guard Preferences.gestureConfiguration.twoFingerTap == .dragLock else { return }
        menuBuilder?.dragLockStatusItem?.title = isLocked
            ? "Drag Lock: Locked (Two-Finger Tap to Release)"
            : "Drag Lock: Unlocked (Two-Finger Tap)"
    }

    private func requestAccessibilityPermissionIfNeeded() {
        guard !hasRequestedAccessibilityPrompt else { return }
        hasRequestedAccessibilityPrompt = true

        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [promptKey: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    private func waitForAccessibilityPermission() {
        guard !isWaitingForAccessibility else { return }
        isWaitingForAccessibility = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.isWaitingForAccessibility = false

            let trusted = AXIsProcessTrusted()
            if trusted {
                self.menuBuilder?.accessibilityStatusItem?.title = "Accessibility: Granted ✓"
                self.startPipeline()
            } else {
                self.menuBuilder?.accessibilityStatusItem?.title = "⚠️ Accessibility: NOT GRANTED (Click to Fix)"
                self.waitForAccessibilityPermission()
            }
        }
    }
}
