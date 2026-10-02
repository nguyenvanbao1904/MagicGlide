import Foundation
import CoreGraphics
import AppKit
import os

// Swift wrapper for Multitouch framework
final class MultitouchManager {
    private var devices: [MTDeviceRef] = []
    private var tapDetector: TapDetector
    private var twoFingerTapDetector = TwoFingerTapDetector(tapTimeThreshold: 0.35, movementThreshold: 0.12)
    private var twoFingerSwipeDetector = TwoFingerSwipeDetector()
    private var threeFingerDetector = ThreeFingerGestureDetector()
    private var pinchZoomDetector = PinchZoomDetector()
    private var isEnabled = true
    private var isDragLockAvailable = false
    private var activeTouch: Int32 = -1
    private var touchStartX: Float = 0.0
    private var touchStartY: Float = 0.0
    private var disqualifiedTouches = Set<Int32>()
    private var surfaceMovementThreshold: Float = Preferences.tapSensitivity.surfaceMovementThreshold

    var onTwoFingerSwipeUp: ((CGPoint) -> Void)?
    var onTwoFingerSwipeDown: ((CGPoint) -> Void)?

    /// Taps with a normalized x above this are right clicks. Configurable from the menu bar / settings.
    var rightClickThreshold: Float {
        get { Preferences.rightClickThreshold }
        set { Preferences.rightClickThreshold = newValue }
    }

    /// Minimum normalized Y position required to initiate a tap (1.0 = fingertips/away from logo, 0.0 = palm/near logo).
    /// Touches with Y >= minTapY are accepted.
    var minTapY: Float {
        get { Preferences.minTapY }
        set { Preferences.minTapY = newValue }
    }
    var isTapToClickEnabled: Bool {
        get { Preferences.isTapToClickEnabled }
        set { Preferences.isTapToClickEnabled = newValue }
    }

    /// Tap sensitivity configuration
    var tapSensitivity: Preferences.TapSensitivity {
        get { Preferences.tapSensitivity }
        set {
            Preferences.tapSensitivity = newValue
            applySensitivity(newValue)
        }
    }

    internal static var sharedInstance: MultitouchManager?

    var onClickSynthesized: ((CGPoint, Bool) -> Void)?
    var onMiddleClickSynthesized: ((CGPoint) -> Void)?
    var onTabSwitch: ((Bool) -> Void)?
    var onTwoFingerTap: ((CGPoint) -> Void)?
    var onDragLockChanged: ((CGPoint, Bool) -> Void)?
    var onMagnification: ((Double, Int64, CGPoint) -> Void)?
    private(set) var isDragLocked = false

    var isPinchZoomEnabled: Bool {
        get { Preferences.isPinchZoomEnabled }
        set {
            Preferences.isPinchZoomEnabled = newValue
            pinchZoomDetector.isEnabled = newValue
        }
    }

    let twoFingerMoveZoomDetector = TwoFingerMoveZoomDetector()
    var isMoveZoomEnabled: Bool {
        get { Preferences.isMoveZoomEnabled }
        set {
            Preferences.isMoveZoomEnabled = newValue
            twoFingerMoveZoomDetector.isEnabled = newValue
        }
    }

    // MARK: - Smart Zoom Support (Disambiguation Buffer)
    var isSmartZoomEnabled: Bool {
        get { Preferences.isSmartZoomEnabled }
        set { Preferences.isSmartZoomEnabled = newValue }
    }
    private var pendingTapWorkItem: DispatchWorkItem?
    private var isDoubleTapInProgress = false
    private var lastTapEndTime: TimeInterval = 0.0
    private var tapLock = os_unfair_lock_s()

    private func cancelPendingTap() {
        os_unfair_lock_lock(&tapLock)
        if let pending = pendingTapWorkItem {
            pending.cancel()
            pendingTapWorkItem = nil
        }
        os_unfair_lock_unlock(&tapLock)
    }

    private func scheduleBufferedTap(at location: CGPoint) {
        cancelPendingTap()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            var shouldFire = false
            os_unfair_lock_lock(&self.tapLock)
            if self.pendingTapWorkItem != nil {
                self.pendingTapWorkItem = nil
                shouldFire = true
            }
            os_unfair_lock_unlock(&self.tapLock)

            if shouldFire {
                self.onClickSynthesized?(location, false)
            }
        }

        os_unfair_lock_lock(&tapLock)
        self.pendingTapWorkItem = workItem
        self.lastTapEndTime = ProcessInfo.processInfo.systemUptime
        os_unfair_lock_unlock(&tapLock)

        DispatchQueue.main.asyncAfter(deadline: .now() + Preferences.smartZoomBufferDelay, execute: workItem)
    }

    // MARK: - Edge Sliders (Volume & Brightness)
    var isEdgeSlidersEnabled: Bool {
        get { Preferences.isEdgeSlidersEnabled }
        set { Preferences.isEdgeSlidersEnabled = newValue }
    }
    private(set) var isEdgeSliding = false
    var onEdgeSlidingChanged: ((Bool) -> Void)?

    private enum EdgeSide {
        case left
        case right
    }

    private var candidateEdgeSlider: EdgeSide?
    private var activeEdgeSlider: EdgeSide?
    private var edgeSliderTriggerY: Float = 0.0
    private var gestureLock = os_unfair_lock_s()

    var isEdgeActive: Bool {
        os_unfair_lock_lock(&gestureLock)
        defer { os_unfair_lock_unlock(&gestureLock) }
        return isEdgeSlidersEnabled && isEdgeSliding
    }

    var isThreeFingerActive: Bool {
        os_unfair_lock_lock(&gestureLock)
        defer { os_unfair_lock_unlock(&gestureLock) }
        return threeFingerDetector.isGestureActive
    }

    var isPinchActive: Bool {
        os_unfair_lock_lock(&gestureLock)
        defer { os_unfair_lock_unlock(&gestureLock) }
        return pinchZoomDetector.isGestureActive
    }

    var isMoveZoomActive: Bool {
        os_unfair_lock_lock(&gestureLock)
        defer { os_unfair_lock_unlock(&gestureLock) }
        return twoFingerMoveZoomDetector.isGestureActive
    }

    var isTwoFingerSwipeActive: Bool {
        os_unfair_lock_lock(&gestureLock)
        defer { os_unfair_lock_unlock(&gestureLock) }
        return twoFingerSwipeDetector.isGestureActive
    }

    private(set) var currentUpperFingersCount: Int = 0
    private(set) var lastTwoFingersTimestamp: TimeInterval = 0.0
    private var lastThreeFingersTimestamp: TimeInterval = 0.0
    private var lastPhysicalMiddleClickTime: TimeInterval = 0.0
    private var suppressThreeFingerTapUntil: TimeInterval = 0.0

    func isTwoFingersTouching(within interval: TimeInterval = 0.08) -> Bool {
        let now = ProcessInfo.processInfo.systemUptime
        return currentUpperFingersCount >= 2 || (now - lastTwoFingersTimestamp < interval)
    }

    // Scroll Veto & Momentum Veto (Layers 2 & 3 from 4-layer defense)
    private var lastScrollWheelTime: TimeInterval = 0.0
    private var isMomentumScrolling: Bool = false

    func notifyScrollWheelOccurred(momentumPhase: Int64) {
        lastScrollWheelTime = ProcessInfo.processInfo.systemUptime
        isMomentumScrolling = (momentumPhase == 1 || momentumPhase == 2)
    }

    var isScrollVetoActive: Bool {
        let now = ProcessInfo.processInfo.systemUptime
        if isMomentumScrolling { return true }
        if now - lastScrollWheelTime < 0.22 { return true }
        return false
    }

    func shouldTransformTwoFingerPhysicalClick() -> Bool {
        guard Preferences.gestureConfiguration.twoFingerClick != .none else { return false }
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastPhysicalMiddleClickTime > 0.15 else { return false }
        guard !isScrollVetoActive else { return false }

        let isTwoFingersPresent = (currentUpperFingersCount == 2) || (now - lastTwoFingersTimestamp < 0.06)
        guard isTwoFingersPresent else { return false }

        lastPhysicalMiddleClickTime = now
        cancelSingleTouchTracking()
        resetEdgeSliderState()
        twoFingerTapDetector.reset()
        return true
    }

    func shouldTransformPhysicalClickToMiddleClick() -> Bool {
        guard Preferences.isThreeFingerTapEnabled && Preferences.gestureConfiguration.threeFingerTap != .none else { return false }
        let now = ProcessInfo.processInfo.systemUptime
        // Debounce physical click: at least 150ms between clicks to prevent mechanical switch bounce
        guard now - lastPhysicalMiddleClickTime > 0.15 else { return false }

        // Require that 3 distinct fingers are actively touching the upper surface right now,
        // or touched within the last 60ms (to account for tiny driver event delivery timing)
        let isThreeFingersPresent = (currentUpperFingersCount >= 3) || (now - lastThreeFingersTimestamp < 0.06)
        guard isThreeFingersPresent else { return false }

        lastPhysicalMiddleClickTime = now
        suppressThreeFingerTap(for: 0.7)
        cancelSingleTouchTracking()
        resetEdgeSliderState()
        twoFingerTapDetector.reset()
        return true
    }

    func suppressThreeFingerTap(for duration: TimeInterval) {
        suppressThreeFingerTapUntil = max(suppressThreeFingerTapUntil, ProcessInfo.processInfo.systemUptime + duration)
        threeFingerDetector.reset()
    }

    private func resetEdgeSliderState() {
        os_unfair_lock_lock(&gestureLock)
        candidateEdgeSlider = nil
        isEdgeSliding = false
        activeEdgeSlider = nil
        os_unfair_lock_unlock(&gestureLock)
    }

    private func setCandidateEdgeSlider(_ candidate: EdgeSide?) {
        os_unfair_lock_lock(&gestureLock)
        candidateEdgeSlider = candidate
        os_unfair_lock_unlock(&gestureLock)
    }

    private func activateEdgeSlider(side: EdgeSide, triggerY: Float) {
        os_unfair_lock_lock(&gestureLock)
        candidateEdgeSlider = nil
        isEdgeSliding = true
        activeEdgeSlider = side
        edgeSliderTriggerY = triggerY
        os_unfair_lock_unlock(&gestureLock)
    }

    private func candidateFor(x: Float) -> EdgeSide? {
        guard Preferences.isEdgeSlidersEnabled else { return nil }
        if x <= Preferences.leftEdgeThreshold {
            return Preferences.gestureConfiguration.leftEdge != .none ? .left : nil
        } else if x >= Preferences.rightEdgeThreshold {
            return Preferences.gestureConfiguration.rightEdge != .none ? .right : nil
        }
        return nil
    }

    init() {
        let sensitivity = Preferences.tapSensitivity
        self.tapDetector = TapDetector(
            tapTimeThreshold: sensitivity.tapTimeThreshold,
            tapMovementThreshold: 8.0 // 8.0 screen pixels cursor jitter tolerance
        )
        self.surfaceMovementThreshold = sensitivity.surfaceMovementThreshold
        self.minTapY = Preferences.minTapY
        self.threeFingerDetector.isTapEnabled = Preferences.isThreeFingerTapEnabled
        self.threeFingerDetector.isSwipeEnabled = Preferences.isThreeFingerSwipeEnabled
        self.pinchZoomDetector.isEnabled = Preferences.isPinchZoomEnabled
        self.pinchZoomDetector.onMagnification = { [weak self] mag, phase, loc in
            self?.onMagnification?(mag, phase, loc)
        }
        self.twoFingerMoveZoomDetector.isEnabled = Preferences.isMoveZoomEnabled
        self.twoFingerMoveZoomDetector.onMagnification = { [weak self] mag, phase, loc in
            self?.onMagnification?(mag, phase, loc)
        }
        self.twoFingerMoveZoomDetector.onDeltaAction = { action, delta, loc in
            ActionExecutor.shared.execute(action, context: ActionContext(delta: delta, location: loc))
        }
        self.twoFingerSwipeDetector.onSwipeUp = { [weak self] loc in
            self?.onTwoFingerSwipeUp?(loc)
        }
        self.twoFingerSwipeDetector.onSwipeDown = { [weak self] loc in
            self?.onTwoFingerSwipeDown?(loc)
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleSystemWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleSystemWake),
            name: NSWorkspace.screensDidWakeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePreferencesDidChange),
            name: .preferencesDidChange,
            object: nil
        )
    }

    @objc private func handlePreferencesDidChange() {
        applySensitivity(Preferences.tapSensitivity)
        threeFingerDetector.isTapEnabled = Preferences.isThreeFingerTapEnabled && Preferences.gestureConfiguration.threeFingerTap != .none
        threeFingerDetector.isSwipeEnabled = Preferences.isThreeFingerSwipeEnabled && Preferences.gestureConfiguration.threeFingerSwipe != .none
        pinchZoomDetector.isEnabled = Preferences.isPinchZoomEnabled
        twoFingerMoveZoomDetector.isEnabled = Preferences.isMoveZoomEnabled
        if !Preferences.isEdgeSlidersEnabled {
            resetEdgeSliderState()
            onEdgeSlidingChanged?(false)
        }
    }

    @objc private func handleSystemWake() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.restart()
        }
    }

    private var deviceCheckTimer: DispatchSourceTimer?

    private func startDeviceCheckTimer() {
        stopDeviceCheckTimer()
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        timer.schedule(deadline: .now() + 2.5, repeating: 2.5)
        timer.setEventHandler { [weak self] in
            self?.checkDevices()
        }
        timer.resume()
        deviceCheckTimer = timer
    }

    private func stopDeviceCheckTimer() {
        deviceCheckTimer?.cancel()
        deviceCheckTimer = nil
    }

    func checkDevices() {
        guard isEnabled else { return }
        guard let deviceList = MTDeviceCreateList() else {
            if !devices.isEmpty {
                restart()
            }
            return
        }

        let deviceArray = deviceList.takeRetainedValue() as NSArray
        let count = CFArrayGetCount(deviceArray)
        var externalCount = 0
        for i in 0..<count {
            let device = unsafeBitCast(CFArrayGetValueAtIndex(deviceArray, i), to: MTDeviceRef.self)
            if !MTDeviceIsBuiltIn(device) {
                externalCount += 1
            }
        }

        // If device count changed (e.g. mouse disconnected or reconnected), restart to rebind
        if externalCount != devices.count {
            restart()
            DispatchQueue.main.async {
                MouseDeviceInfo.shared.refresh()
            }
        }
    }

    var hasConnectedDevice: Bool {
        !devices.isEmpty
    }

    func restart() {
        stop()
        start()
    }

    func applySensitivity(_ sensitivity: Preferences.TapSensitivity) {
        tapDetector.tapTimeThreshold = sensitivity.tapTimeThreshold
        surfaceMovementThreshold = sensitivity.surfaceMovementThreshold
    }

    func start() {
        MultitouchManager.sharedInstance = self

        guard let deviceList = MTDeviceCreateList() else {
            startDeviceCheckTimer()
            return
        }

        let deviceArray = deviceList.takeRetainedValue() as NSArray
        let count = CFArrayGetCount(deviceArray)

        for i in 0..<count {
            let device = unsafeBitCast(CFArrayGetValueAtIndex(deviceArray, i), to: MTDeviceRef.self)

            // Only monitor external devices (Magic Mouse), skip built-in trackpads
            let isBuiltIn = MTDeviceIsBuiltIn(device)

            if !isBuiltIn {
                devices.append(device)
                MTRegisterContactFrameCallback(device, touchCallback)
                MTDeviceStart(device, 0)
            }
        }

        startDeviceCheckTimer()
    }

    func stop() {
        stopDeviceCheckTimer()
        releaseDragLock()
        resetTouchTracking()

        for device in devices {
            MTUnregisterContactFrameCallback(device, touchCallback)
            MTDeviceStop(device)
        }
        devices.removeAll()

        if MultitouchManager.sharedInstance === self {
            MultitouchManager.sharedInstance = nil
        }
    }

    func setEnabled(_ enabled: Bool) {
        if !enabled {
            releaseDragLock()
            resetTouchTracking()
        }
        isEnabled = enabled
    }

    func setDragLockAvailable(_ available: Bool) {
        if !available {
            releaseDragLock()
        }
        isDragLockAvailable = available
    }

    func setThreeFingerTapEnabled(_ enabled: Bool) {
        Preferences.isThreeFingerTapEnabled = enabled
    }

    func setThreeFingerSwipeEnabled(_ enabled: Bool) {
        Preferences.isThreeFingerSwipeEnabled = enabled
    }

    private func filterUpperFingers(_ touches: UnsafeMutablePointer<MTTouch>, count: Int) -> [SurfaceTouch] {
        var result: [SurfaceTouch] = []
        for i in 0..<count {
            let t = touches[i]
            // Only touches in physical contact (3: make, 4: touching, 5: break)
            guard t.state >= 3 && t.state <= 5 else { continue }
            let x = CGFloat(t.normalized.position.x)
            let y = CGFloat(t.normalized.position.y)

            // Palm rejection: The rear of the mouse (Y < 0.18) is the palm rest.
            // Lowered from 0.25 to 0.18 to allow ample runway for downward gestures without palm interference.
            guard y >= 0.18 else { continue }

            // Side grip rejection: Thumb and pinky gripping the side rails (X < 0.08 or X > 0.92)
            guard x >= 0.08 && x <= 0.92 else { continue }

            // Contact patch size rejection: Palm contact patches are large (size > 2.6)
            if t.size > 2.6 { continue }

            result.append(SurfaceTouch(identifier: t.identifier, position: CGPoint(x: x, y: y)))
        }
        return result
    }

    func processTouches(_ touches: UnsafeMutablePointer<MTTouch>, numTouches: Int, timestamp: Double) {
        guard isEnabled else { return }

        // The callback comes from a private framework; don't trust a negative count.
        guard numTouches >= 0 else { return }

        let upperFingers = filterUpperFingers(touches, count: numTouches)
        currentUpperFingersCount = upperFingers.count

        if upperFingers.count == 2 {
            lastTwoFingersTimestamp = ProcessInfo.processInfo.systemUptime
        }

        if upperFingers.count >= 3 {
            let xs = upperFingers.map { $0.position.x }
            let span = (xs.max() ?? 0) - (xs.min() ?? 0)
            if span >= 0.16 {
                lastThreeFingersTimestamp = ProcessInfo.processInfo.systemUptime
            }
        }

        // Virtual Trackpad Mode: if active, touches drive pointer movement / scroll
        if TrackpadModeController.shared.handleTouches(upperFingers, timestamp: timestamp) {
            return
        }

        if ProcessInfo.processInfo.systemUptime < suppressThreeFingerTapUntil {
            threeFingerDetector.reset()
        }

        let threeFingerResult = threeFingerDetector.process(
            touches: upperFingers,
            timestamp: timestamp
        )

        switch threeFingerResult {
        case .middleClick:
            if ProcessInfo.processInfo.systemUptime < suppressThreeFingerTapUntil {
                threeFingerDetector.reset()
                return
            }
            let cgLocation = CGEvent(source: nil)?.location ?? CGPoint.zero
            onMiddleClickSynthesized?(cgLocation)
            disqualifyAll(touches, count: numTouches)
            cancelSingleTouchTracking()
            resetEdgeSliderState()
            twoFingerTapDetector.reset()
            return
        case .swipeRight:
            // When finger moves right ->:
            // In Natural mode (default on macOS): moves to Previous Tab (left)
            // In Direct mode: moves to Next Tab (right)
            let forward = !Preferences.isThreeFingerNaturalSwipe
            onTabSwitch?(forward)
            disqualifyAll(touches, count: numTouches)
            cancelSingleTouchTracking()
            resetEdgeSliderState()
            twoFingerTapDetector.reset()
            return
        case .swipeLeft:
            // When finger moves left <-:
            // In Natural mode (default on macOS): moves to Next Tab (right)
            // In Direct mode: moves to Previous Tab (left)
            let forward = Preferences.isThreeFingerNaturalSwipe
            onTabSwitch?(forward)
            disqualifyAll(touches, count: numTouches)
            cancelSingleTouchTracking()
            resetEdgeSliderState()
            twoFingerTapDetector.reset()
            return
        case .swipeUp:
            if SystemControl.dismissAppExposeIfActive() {
                disqualifyAll(touches, count: numTouches)
                cancelSingleTouchTracking()
                resetEdgeSliderState()
                twoFingerTapDetector.reset()
                return
            }
            let loc = CGEvent(source: nil)?.location ?? CGPoint.zero
            let action = Preferences.gestureConfiguration.twoFingerSwipeUp
            if action != .none {
                ActionExecutor.shared.execute(action, context: ActionContext(location: loc))
            }
            disqualifyAll(touches, count: numTouches)
            cancelSingleTouchTracking()
            resetEdgeSliderState()
            twoFingerTapDetector.reset()
            return
        case .swipeDown:
            if SystemControl.dismissMissionControlIfActive() {
                disqualifyAll(touches, count: numTouches)
                cancelSingleTouchTracking()
                resetEdgeSliderState()
                twoFingerTapDetector.reset()
                return
            }
            let loc = CGEvent(source: nil)?.location ?? CGPoint.zero
            let action = Preferences.gestureConfiguration.twoFingerSwipeDown
            if action != .none {
                ActionExecutor.shared.execute(action, context: ActionContext(location: loc))
            }
            disqualifyAll(touches, count: numTouches)
            cancelSingleTouchTracking()
            resetEdgeSliderState()
            twoFingerTapDetector.reset()
            return
        case .none:
            break
        }

        if threeFingerDetector.suppressesOtherGestures {
            disqualifyAll(touches, count: numTouches)
            cancelSingleTouchTracking()
            resetEdgeSliderState()
            twoFingerTapDetector.reset()
            return
        }

        // Update Scroll Veto state on multi-touch detectors (only active momentum vetoes 2-finger swipe)
        twoFingerSwipeDetector.isScrollVetoActive = isMomentumScrolling
        pinchZoomDetector.isScrollVetoActive = isScrollVetoActive

        // 2-Finger Move-to-Zoom (Push/Pull Mouse) touch state tracking
        twoFingerMoveZoomDetector.updateTouchState(twoFingersTouching: upperFingers.count == 2)
        twoFingerMoveZoomDetector.isFingersSlidingOnSurface = isScrollVetoActive || twoFingerSwipeDetector.isGestureActive || pinchZoomDetector.isGestureActive
        if twoFingerMoveZoomDetector.isGestureActive {
            twoFingerTapDetector.reset()
            disqualifyAll(touches, count: numTouches)
            cancelSingleTouchTracking()
            resetEdgeSliderState()
            return
        }

        // 2-Finger Vertical Swipe (Swipe Up / Swipe Down)
        let didSwipe = twoFingerSwipeDetector.process(touches: upperFingers, timestamp: timestamp)
        if didSwipe || twoFingerSwipeDetector.isGestureActive {
            pinchZoomDetector.process(touches: [], timestamp: timestamp)
            twoFingerTapDetector.reset()
            disqualifyAll(touches, count: numTouches)
            cancelSingleTouchTracking()
            resetEdgeSliderState()
            return
        }

        // 2-Finger Pinch-to-Zoom
        pinchZoomDetector.process(touches: upperFingers, timestamp: timestamp)
        if pinchZoomDetector.isGestureActive {
            twoFingerSwipeDetector.reset()
            twoFingerMoveZoomDetector.updateTouchState(twoFingersTouching: false)
            disqualifyAll(touches, count: numTouches)
            cancelSingleTouchTracking()
            resetEdgeSliderState()
            twoFingerTapDetector.reset()
            return
        }

        let twoFingerResult = twoFingerTapDetector.process(
            touches: upperFingers,
            timestamp: timestamp
        )

        // Keep disqualifiedTouches pruned with touches currently present on surface
        if numTouches == 0 {
            disqualifiedTouches.removeAll(keepingCapacity: true)
        } else {
            let currentIDs = Set((0..<numTouches).map { touches[$0].identifier })
            disqualifiedTouches = disqualifiedTouches.intersection(currentIDs)
        }

        switch twoFingerResult {
        case .recognized:
            disqualifyAll(touches, count: numTouches)
            cancelSingleTouchTracking()
            resetEdgeSliderState()
            let cgLocation = CGEvent(source: nil)?.location ?? CGPoint.zero
            onTwoFingerTap?(cgLocation)
            return
        case .rejectedMultiTouchGesture:
            disqualifyAll(touches, count: numTouches)
            cancelSingleTouchTracking()
            resetEdgeSliderState()
            return
        case .none:
            break
        }

        // Once a second finger has participated, wait for every finger to lift. Otherwise the
        // last remaining finger could be mistaken for a fresh one-finger click.
        if twoFingerTapDetector.suppressesSingleFingerTap {
            disqualifyAll(touches, count: numTouches)
            cancelSingleTouchTracking()
            resetEdgeSliderState()
            return
        }

        if numTouches > 1 {
            disqualifyAll(touches, count: numTouches)
            cancelSingleTouchTracking()
            resetEdgeSliderState()
            return
        }

        if numTouches == 0 {
            let wasSliding = isEdgeSliding
            if isEdgeSliding {
                resetEdgeSliderState()
                onEdgeSlidingChanged?(false)
            } else {
                resetEdgeSliderState()
            }

            if activeTouch != -1 {
                // Get cursor position directly from CGEvent (already in correct coordinate space)
                let cgLocation = CGEvent(source: nil)?.location ?? CGPoint.zero

                if !wasSliding {
                    if isDragLocked {
                        // Fallback release: a clean one-finger tap releases an active drag lock without
                        // producing another click. Moving the mouse or resting a finger while dragging
                        // is not a tap and will not release the lock.
                        if tapDetector.touchEnded(at: cgLocation) != nil {
                            releaseDragLock()
                        }
                    } else if isDoubleTapInProgress {
                        isDoubleTapInProgress = false
                        tapDetector.reset()
                        DispatchQueue.main.async {
                            ActionExecutor.shared.execute(Preferences.gestureConfiguration.doubleTap, context: ActionContext())
                        }
                    } else if !isScrollVetoActive, let tapLocation = tapDetector.touchEnded(at: cgLocation) {
                        if isTapToClickEnabled {
                            let isRightClick: Bool
                            switch Preferences.secondaryClickMode {
                            case .clickRight:
                                isRightClick = touchStartX > rightClickThreshold
                            case .clickLeft:
                                isRightClick = touchStartX < (1.0 - rightClickThreshold)
                            case .none:
                                isRightClick = false
                            }
                            if Preferences.gestureConfiguration.doubleTap != .none && !isRightClick {
                                scheduleBufferedTap(at: tapLocation)
                            } else {
                                onClickSynthesized?(tapLocation, isRightClick)
                            }
                        }
                    }
                } else {
                    tapDetector.reset()
                    isDoubleTapInProgress = false
                }
                activeTouch = -1
                touchStartX = 0.0
                touchStartY = 0.0
            } else {
                isDoubleTapInProgress = false
            }
            disqualifiedTouches.removeAll(keepingCapacity: true)
            return
        }

        if numTouches == 1 {
            let touch = touches[0]
            // Get cursor position directly from CGEvent (already in correct coordinate space)
            let cgLocation = CGEvent(source: nil)?.location ?? CGPoint.zero

            // If this touch is actively edge sliding, KEEP PROCESSING IT!
            if isEdgeSliding, activeTouch == touch.identifier {
                guard Preferences.isEdgeSlidersEnabled else {
                    resetEdgeSliderState()
                    onEdgeSlidingChanged?(false)
                    return
                }
                let side = activeEdgeSlider
                if (side == .left && Preferences.gestureConfiguration.leftEdge == .none) ||
                   (side == .right && Preferences.gestureConfiguration.rightEdge == .none) {
                    resetEdgeSliderState()
                    onEdgeSlidingChanged?(false)
                    return
                }
                let currentY = touch.normalized.position.y
                let diff = currentY - edgeSliderTriggerY
                let stepDist = Preferences.edgeSliderStepDistance

                if diff >= stepDist {
                    let steps = Int(diff / stepDist)
                    let side = activeEdgeSlider
                    edgeSliderTriggerY += Float(steps) * stepDist
                    DispatchQueue.main.async {
                        for _ in 0..<steps {
                            switch side {
                            case .left:
                                ActionExecutor.shared.execute(Preferences.gestureConfiguration.leftEdge, context: ActionContext(delta: 0.0625))
                            case .right:
                                ActionExecutor.shared.execute(Preferences.gestureConfiguration.rightEdge, context: ActionContext(delta: 0.0625))
                            case .none:
                                break
                            }
                        }
                    }
                } else if diff <= -stepDist {
                    let steps = Int(-diff / stepDist)
                    let side = activeEdgeSlider
                    edgeSliderTriggerY -= Float(steps) * stepDist
                    DispatchQueue.main.async {
                        for _ in 0..<steps {
                            switch side {
                            case .left:
                                ActionExecutor.shared.execute(Preferences.gestureConfiguration.leftEdge, context: ActionContext(delta: -0.0625))
                            case .right:
                                ActionExecutor.shared.execute(Preferences.gestureConfiguration.rightEdge, context: ActionContext(delta: -0.0625))
                            case .none:
                                break
                            }
                        }
                    }
                }
                return
            }

            // If this contact is already disqualified (e.g. from multi-touch), ignore it
            if disqualifiedTouches.contains(touch.identifier) {
                return
            }

            // Accept physical contact states: MakeTouch (3), Touching (4), BreakTouch (5)
            if touch.state >= 3 && touch.state <= 5 {
                if activeTouch == -1 {
                    activeTouch = touch.identifier
                    touchStartX = touch.normalized.position.x
                    touchStartY = touch.normalized.position.y
                    edgeSliderTriggerY = touchStartY

                    // Check if this touch starts within the double-tap window
                    if isTapToClickEnabled && Preferences.gestureConfiguration.doubleTap != .none {
                        let elapsed = ProcessInfo.processInfo.systemUptime - lastTapEndTime
                        if elapsed < 0.28 {
                            cancelPendingTap()
                            isDoubleTapInProgress = true
                        }
                    }

                    setCandidateEdgeSlider(candidateFor(x: touchStartX))

                    // Only track tap if in active tap zone (Y >= minTapY) and not vetoed by scrolling
                    if touchStartY >= minTapY && !isScrollVetoActive {
                        tapDetector.touchBegan(at: cgLocation)
                    } else {
                        // Touch started in palm rest area or during scroll: not a tap!
                        tapDetector.reset()
                    }
                } else if activeTouch == touch.identifier {
                    // Check if candidate edge slider activates
                    if let side = candidateEdgeSlider, !isEdgeSliding {
                        let deltaY = touch.normalized.position.y - touchStartY
                        let absDeltaY = abs(deltaY)
                        let absDeltaX = abs(touch.normalized.position.x - touchStartX)
                        let currentX = touch.normalized.position.x

                        // Check if finger drifted away from the edge towards center of mouse
                        let driftedIntoCenter = (side == .right && currentX < Preferences.rightEdgeThreshold - 0.02) ||
                                                (side == .left && currentX > Preferences.leftEdgeThreshold + 0.02) ||
                                                absDeltaX >= 0.08

                        if absDeltaY >= Preferences.edgeSliderActivationThreshold && !driftedIntoCenter {
                            // User is sliding vertically along the edge! Activate edge slider!
                            activateEdgeSlider(side: side, triggerY: touch.normalized.position.y)
                            tapDetector.reset()
                            onEdgeSlidingChanged?(true)

                            // Fire immediate first notch in direction of slide using configured action
                            let delta: Float = deltaY > 0 ? 0.0625 : -0.0625
                            DispatchQueue.main.async {
                                switch side {
                                case .left:
                                    ActionExecutor.shared.execute(Preferences.gestureConfiguration.leftEdge, context: ActionContext(delta: delta))
                                case .right:
                                    ActionExecutor.shared.execute(Preferences.gestureConfiguration.rightEdge, context: ActionContext(delta: delta))
                                }
                            }
                            return
                        } else if driftedIntoCenter {
                            // Finger drifted towards the center of mouse: cancel candidate
                            setCandidateEdgeSlider(nil)
                        } else {
                            // Still on edge within activation deadzone: check tap tracking only
                            if tapDetector.isTracking {
                                if tapDetector.isExpired || tapDetector.touchMoved(to: cgLocation) {
                                    tapDetector.reset()
                                }
                            }
                            // Keep candidate active, DO NOT let surfaceMovementThreshold kill it!
                            return
                        }
                    }

                    // Normal tap & scroll movement tracking (when not edge sliding)
                    if tapDetector.isTracking {
                        let deltaX = abs(touch.normalized.position.x - touchStartX)
                        let deltaY = abs(touch.normalized.position.y - touchStartY) * Float(110.0 / 58.0)
                        let surfaceMovement = max(deltaX, deltaY)

                        let isExpired = tapDetector.isExpired
                        let isSurfaceMoving = surfaceMovement > surfaceMovementThreshold
                        let moved = tapDetector.touchMoved(to: cgLocation)

                        if isSurfaceMoving || isExpired || moved {
                            tapDetector.reset()
                        }
                    }
                }
            }
        }
    }

    private func disqualifyAll(_ touches: UnsafeMutablePointer<MTTouch>, count: Int) {
        for i in 0..<count {
            disqualifiedTouches.insert(touches[i].identifier)
        }
    }

    func toggleDragLock() {
        isDragLocked.toggle()
        let location = CGEvent(source: nil)?.location ?? CGPoint.zero
        onDragLockChanged?(location, isDragLocked)
    }

    private func releaseDragLock() {
        guard isDragLocked else { return }
        isDragLocked = false
        let location = CGEvent(source: nil)?.location ?? CGPoint.zero
        onDragLockChanged?(location, false)
    }

    private func resetTouchTracking() {
        cancelPendingTap()
        isDoubleTapInProgress = false
        twoFingerTapDetector.reset()
        threeFingerDetector.reset()
        pinchZoomDetector.reset()
        twoFingerMoveZoomDetector.reset()
        twoFingerSwipeDetector.reset()
        cancelSingleTouchTracking()
        disqualifiedTouches.removeAll(keepingCapacity: true)
        resetEdgeSliderState()
        onEdgeSlidingChanged?(false)
    }

    private func cancelSingleTouchTracking() {
        cancelPendingTap()
        isDoubleTapInProgress = false
        tapDetector.reset()
        activeTouch = -1
        touchStartX = 0.0
        touchStartY = 0.0
    }

    deinit {
        stop() // also clears sharedInstance if === self
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }
}

private func touchCallback(device: Int32, touches: UnsafeMutablePointer<MTTouch>?, numTouches: Int32, timestamp: Double, frame: Int32) -> Int32 {
    if let manager = MultitouchManager.sharedInstance, let touches = touches {
        manager.processTouches(touches, numTouches: Int(numTouches), timestamp: timestamp)
    }
    return 0
}
