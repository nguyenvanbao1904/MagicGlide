import Foundation
import CoreGraphics
import AppKit
import os

/// Processes raw touch frames from MultitouchSource and emits typed GestureEvents.
///
/// Architecture:
///   MultitouchSource → GestureEngine → GestureDispatcher → ActionExecutor
///
/// GestureEngine owns all gesture detectors and runs them in a fixed priority waterfall.
/// It does not read Preferences directly — settings are injected via PreferenceStore.
/// It does not call ActionExecutor — results go out through `onRecognized`.
final class GestureEngine {
    // MARK: - Output

    /// Called (on arbitrary thread) whenever a gesture completes.
    var onRecognized: ((GestureEvent) -> Void)?

    // MARK: - Detectors (owned, concrete — extending later means adding here + AppDelegate)
    private let tapDetector: TapDetector
    private let twoFingerTapDetector: TwoFingerTapDetector
    private let twoFingerSwipeDetector: TwoFingerSwipeDetector
    private let threeFingerDetector: ThreeFingerGestureDetector
    private let pinchZoomDetector: PinchZoomDetector
    let twoFingerMoveZoomDetector: TwoFingerMoveZoomDetector   // internal: EventTapController needs it

    // MARK: - Settings
    private let store: PreferenceStore

    // MARK: - Touch tracking state
    private var activeTouch: Int32 = -1
    private var touchStartX: Float = 0.0
    private var touchStartY: Float = 0.0
    private var disqualifiedTouches = Set<Int32>()
    private var surfaceMovementThreshold: Float

    // MARK: - Finger count tracking (queried by EventTapController)
    private(set) var currentUpperFingersCount: Int = 0
    private(set) var lastTwoFingersTimestamp: TimeInterval = 0.0
    private var lastThreeFingersTimestamp: TimeInterval = 0.0
    private var lastPhysicalMiddleClickTime: TimeInterval = 0.0
    private var suppressThreeFingerTapUntil: TimeInterval = 0.0

    // MARK: - Drag lock
    private(set) var isDragLocked = false

    // MARK: - Scroll veto (layers 2 & 3)
    private var lastScrollWheelTime: TimeInterval = 0.0
    private var isMomentumScrolling = false

    // MARK: - Edge slider state
    private var candidateEdgeSide: EdgeSide?
    private var activeEdgeSide: EdgeSide?
    private var isEdgeSliding = false
    private var edgeSliderTriggerY: Float = 0.0
    private var gestureLock = os_unfair_lock_s()

    // MARK: - Double-tap tracking (used by GestureDispatcher via callback)
    private var isDoubleTapInProgress = false
    private var lastTapEndTime: TimeInterval = 0.0

    // MARK: - Shared weak reference for ActionExecutor shim
    static weak var current: GestureEngine?

    // MARK: - Init

    init(store: PreferenceStore) {
        self.store = store
        let sensitivity = store.tapSensitivity
        self.tapDetector = TapDetector(
            tapTimeThreshold: sensitivity.tapTimeThreshold,
            tapMovementThreshold: 8.0
        )
        self.surfaceMovementThreshold = sensitivity.surfaceMovementThreshold
        self.twoFingerTapDetector = TwoFingerTapDetector()
        self.twoFingerSwipeDetector = TwoFingerSwipeDetector()
        self.threeFingerDetector = ThreeFingerGestureDetector()
        self.pinchZoomDetector = PinchZoomDetector()
        self.twoFingerMoveZoomDetector = TwoFingerMoveZoomDetector()

        // Apply initial state from preferences
        let cfg = store.gestureConfiguration
        threeFingerDetector.isTapEnabled = store.isThreeFingerTapEnabled && cfg.threeFingerTap != .none
        threeFingerDetector.isSwipeEnabled = store.isThreeFingerSwipeEnabled && cfg.threeFingerSwipe != .none
        threeFingerDetector.swipeAction = cfg.threeFingerSwipe
        pinchZoomDetector.isEnabled = cfg.pinch != .none
        twoFingerMoveZoomDetector.isEnabled = cfg.twoFingerMove != .none
        twoFingerMoveZoomDetector.assignedAction = cfg.twoFingerMove
        twoFingerSwipeDetector.isSwipeUpEnabled = cfg.twoFingerSwipeUp != .none
        twoFingerSwipeDetector.isSwipeDownEnabled = cfg.twoFingerSwipeDown != .none
        pinchZoomDetector.onMagnification = { [weak self] mag, phase, loc in
            self?.emit(.magnification(magnitude: mag, phase: phase, location: loc))
        }
        twoFingerMoveZoomDetector.onMagnification = { [weak self] mag, phase, loc in
            self?.emit(.magnification(magnitude: mag, phase: phase, location: loc))
        }
        twoFingerMoveZoomDetector.onDeltaAction = { [weak self] action, delta, loc in
            guard let self else { return }
            let side: EdgeSide = action == .brightness ? .left : .right
            self.emit(.edgeSlide(side: side, delta: delta, location: loc))
        }
        twoFingerSwipeDetector.onSwipeUp = { [weak self] loc in
            self?.emit(.twoFingerSwipeUp(location: loc))
        }
        twoFingerSwipeDetector.onSwipeDown = { [weak self] loc in
            self?.emit(.twoFingerSwipeDown(location: loc))
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePreferencesDidChange),
            name: .preferencesDidChange,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Settings sync

    @objc private func handlePreferencesDidChange() {
        let s = store.tapSensitivity
        tapDetector.tapTimeThreshold = s.tapTimeThreshold
        surfaceMovementThreshold = s.surfaceMovementThreshold
        let cfg = store.gestureConfiguration
        threeFingerDetector.isTapEnabled = store.isThreeFingerTapEnabled && cfg.threeFingerTap != .none
        threeFingerDetector.isSwipeEnabled = store.isThreeFingerSwipeEnabled && cfg.threeFingerSwipe != .none
        threeFingerDetector.swipeAction = cfg.threeFingerSwipe
        pinchZoomDetector.isEnabled = cfg.pinch != .none
        twoFingerMoveZoomDetector.isEnabled = cfg.twoFingerMove != .none
        twoFingerMoveZoomDetector.assignedAction = cfg.twoFingerMove
        twoFingerSwipeDetector.isSwipeUpEnabled = cfg.twoFingerSwipeUp != .none
        twoFingerSwipeDetector.isSwipeDownEnabled = cfg.twoFingerSwipeDown != .none
        if !store.isEdgeSlidersEnabled { resetEdgeSliderState() }
    }

    // MARK: - Scroll veto

    func notifyScrollWheelOccurred(momentumPhase: Int64) {
        lastScrollWheelTime = ProcessInfo.processInfo.systemUptime
        isMomentumScrolling = (momentumPhase == 1 || momentumPhase == 2)
    }

    var isScrollVetoActive: Bool {
        if isMomentumScrolling { return true }
        return ProcessInfo.processInfo.systemUptime - lastScrollWheelTime < 0.22
    }

    // MARK: - Active gesture state (queried by EventTapController for scroll suppression)

    var isEdgeActive: Bool {
        os_unfair_lock_lock(&gestureLock)
        defer { os_unfair_lock_unlock(&gestureLock) }
        return store.isEdgeSlidersEnabled && isEdgeSliding
    }
    var isThreeFingerActive: Bool { threeFingerDetector.isGestureActive }
    var isPinchActive: Bool { pinchZoomDetector.isGestureActive }
    var isMoveZoomActive: Bool { twoFingerMoveZoomDetector.isGestureActive }
    var isTwoFingerSwipeActive: Bool { twoFingerSwipeDetector.isGestureActive }

    func isTwoFingersTouching(within interval: TimeInterval = 0.08) -> Bool {
        ProcessInfo.processInfo.systemUptime - lastTwoFingersTimestamp < interval
            || currentUpperFingersCount >= 2
    }

    // MARK: - Physical click interception (called by EventTapController)

    func shouldTransformTwoFingerPhysicalClick() -> Bool {
        guard store.gestureConfiguration.twoFingerClick != .none else { return false }
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastPhysicalMiddleClickTime > 0.15 else { return false }
        guard !isScrollVetoActive else { return false }
        let present = currentUpperFingersCount == 2
            || (now - lastTwoFingersTimestamp < 0.06)
        guard present else { return false }
        lastPhysicalMiddleClickTime = now
        cancelSingleTouchTracking()
        resetEdgeSliderState()
        twoFingerTapDetector.reset()
        return true
    }

    func shouldTransformPhysicalClickToMiddleClick() -> Bool {
        guard store.isThreeFingerTapEnabled,
              store.gestureConfiguration.threeFingerTap != .none else { return false }
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastPhysicalMiddleClickTime > 0.15 else { return false }
        let present = currentUpperFingersCount >= 3
            || (now - lastThreeFingersTimestamp < 0.06)
        guard present else { return false }
        lastPhysicalMiddleClickTime = now
        suppressThreeFingerTapFor(0.7)
        cancelSingleTouchTracking()
        resetEdgeSliderState()
        twoFingerTapDetector.reset()
        return true
    }

    func suppressThreeFingerTapFor(_ duration: TimeInterval) {
        suppressThreeFingerTapUntil = max(
            suppressThreeFingerTapUntil,
            ProcessInfo.processInfo.systemUptime + duration
        )
        threeFingerDetector.reset()
    }

    // MARK: - Drag lock

    func toggleDragLock() {
        isDragLocked.toggle()
        let loc = CGEvent(source: nil)?.location ?? .zero
        emit(.dragLockToggle(location: loc))
    }

    private func releaseDragLock() {
        guard isDragLocked else { return }
        isDragLocked = false
        let loc = CGEvent(source: nil)?.location ?? .zero
        emit(.dragLockToggle(location: loc))
    }

    // MARK: - Main touch processing

    func processTouches(_ raw: UnsafeMutablePointer<MTTouch>, count: Int, timestamp: Double) {
        guard count >= 0 else { return }

        let upper = filterUpperFingers(raw, count: count)
        currentUpperFingersCount = upper.count

        if upper.count == 2 { lastTwoFingersTimestamp = ProcessInfo.processInfo.systemUptime }
        if upper.count >= 3 {
            let xs = upper.map { $0.position.x }
            if ((xs.max() ?? 0) - (xs.min() ?? 0)) >= 0.16 {
                lastThreeFingersTimestamp = ProcessInfo.processInfo.systemUptime
            }
        }

        // Virtual trackpad mode takes priority
        if TrackpadModeController.shared.handleTouches(upper, timestamp: timestamp) { return }

        // Three-finger gesture waterfall
        if ProcessInfo.processInfo.systemUptime < suppressThreeFingerTapUntil { threeFingerDetector.reset() }
        let threeResult = threeFingerDetector.process(touches: upper, timestamp: timestamp)
        switch threeResult {
        case .middleClick:
            guard ProcessInfo.processInfo.systemUptime >= suppressThreeFingerTapUntil else {
                threeFingerDetector.reset(); return
            }
            emit(.threeFingerTap(location: CGEvent(source: nil)?.location ?? .zero))
            disqualifyAll(raw, count: count); cancelSingleTouchTracking(); resetEdgeSliderState()
            twoFingerTapDetector.reset(); return
        case .swipeRight:
            let forward = !store.gestureConfiguration.isThreeFingerNaturalSwipe
            emit(.threeFingerSwipe(direction: forward ? .forward : .backward,
                                   location: CGEvent(source: nil)?.location ?? .zero))
            disqualifyAll(raw, count: count); cancelSingleTouchTracking(); resetEdgeSliderState()
            twoFingerTapDetector.reset(); return
        case .swipeLeft:
            let forward = store.gestureConfiguration.isThreeFingerNaturalSwipe
            emit(.threeFingerSwipe(direction: forward ? .forward : .backward,
                                   location: CGEvent(source: nil)?.location ?? .zero))
            disqualifyAll(raw, count: count); cancelSingleTouchTracking(); resetEdgeSliderState()
            twoFingerTapDetector.reset(); return
        case .swipeUp:
            if SystemControl.dismissAppExposeIfActive() {
                disqualifyAll(raw, count: count); cancelSingleTouchTracking()
                resetEdgeSliderState(); twoFingerTapDetector.reset(); return
            }
            emit(.twoFingerSwipeUp(location: CGEvent(source: nil)?.location ?? .zero))
            disqualifyAll(raw, count: count); cancelSingleTouchTracking()
            resetEdgeSliderState(); twoFingerTapDetector.reset(); return
        case .swipeDown:
            if SystemControl.dismissMissionControlIfActive() {
                disqualifyAll(raw, count: count); cancelSingleTouchTracking()
                resetEdgeSliderState(); twoFingerTapDetector.reset(); return
            }
            emit(.twoFingerSwipeDown(location: CGEvent(source: nil)?.location ?? .zero))
            disqualifyAll(raw, count: count); cancelSingleTouchTracking()
            resetEdgeSliderState(); twoFingerTapDetector.reset(); return
        case .none: break
        }

        if threeFingerDetector.suppressesOtherGestures {
            disqualifyAll(raw, count: count); cancelSingleTouchTracking()
            resetEdgeSliderState(); twoFingerTapDetector.reset(); return
        }

        // Two-finger scroll veto & detectors
        twoFingerSwipeDetector.isScrollVetoActive = isMomentumScrolling
        pinchZoomDetector.isScrollVetoActive = isScrollVetoActive

        twoFingerMoveZoomDetector.updateTouchState(twoFingersTouching: upper.count == 2)
        twoFingerMoveZoomDetector.isFingersSlidingOnSurface = isScrollVetoActive
            || twoFingerSwipeDetector.isGestureActive
            || pinchZoomDetector.isGestureActive
        if twoFingerMoveZoomDetector.isGestureActive {
            twoFingerTapDetector.reset(); disqualifyAll(raw, count: count)
            cancelSingleTouchTracking(); resetEdgeSliderState(); return
        }

        let didSwipe = twoFingerSwipeDetector.process(touches: upper, timestamp: timestamp)
        if didSwipe || twoFingerSwipeDetector.isGestureActive {
            pinchZoomDetector.process(touches: [], timestamp: timestamp)
            twoFingerTapDetector.reset(); disqualifyAll(raw, count: count)
            cancelSingleTouchTracking(); resetEdgeSliderState(); return
        }

        pinchZoomDetector.process(touches: upper, timestamp: timestamp)
        if pinchZoomDetector.isGestureActive {
            twoFingerSwipeDetector.reset()
            twoFingerMoveZoomDetector.updateTouchState(twoFingersTouching: false)
            disqualifyAll(raw, count: count); cancelSingleTouchTracking()
            resetEdgeSliderState(); twoFingerTapDetector.reset(); return
        }

        let twoFingerResult = twoFingerTapDetector.process(touches: upper, timestamp: timestamp)

        // Prune disqualified set
        if count == 0 {
            disqualifiedTouches.removeAll(keepingCapacity: true)
        } else {
            let live = Set((0..<count).map { raw[$0].identifier })
            disqualifiedTouches = disqualifiedTouches.intersection(live)
        }

        switch twoFingerResult {
        case .recognized:
            let loc = CGEvent(source: nil)?.location ?? .zero
            disqualifyAll(raw, count: count); cancelSingleTouchTracking(); resetEdgeSliderState()
            emit(.twoFingerTap(location: loc)); return
        case .rejectedMultiTouchGesture:
            disqualifyAll(raw, count: count); cancelSingleTouchTracking()
            resetEdgeSliderState(); return
        case .none: break
        }

        if twoFingerTapDetector.suppressesSingleFingerTap {
            disqualifyAll(raw, count: count); cancelSingleTouchTracking()
            resetEdgeSliderState(); return
        }
        if count > 1 {
            disqualifyAll(raw, count: count); cancelSingleTouchTracking()
            resetEdgeSliderState(); return
        }

        processOneFingerOrLift(raw, count: count, upperFingers: upper)
    }

    // MARK: - Single-finger & lift handling

    private func processOneFingerOrLift(
        _ raw: UnsafeMutablePointer<MTTouch>, count: Int, upperFingers: [SurfaceTouch]
    ) {
        if count == 0 {
            let wasSliding: Bool
            os_unfair_lock_lock(&gestureLock)
            wasSliding = isEdgeSliding
            os_unfair_lock_unlock(&gestureLock)
            resetEdgeSliderState()

            if activeTouch != -1 {
                let loc = CGEvent(source: nil)?.location ?? .zero
                if !wasSliding {
                    if isDragLocked {
                        if tapDetector.touchEnded(at: loc) != nil { releaseDragLock() }
                    } else if isDoubleTapInProgress {
                        isDoubleTapInProgress = false
                        tapDetector.reset()
                        emit(.doubleTap(location: loc))
                    } else if !isScrollVetoActive, let tapLoc = tapDetector.touchEnded(at: loc) {
                        if store.isTapToClickEnabled {
                            let isRight: Bool
                            switch store.secondaryClickMode {
                            case .clickRight: isRight = touchStartX > store.rightClickThreshold
                            case .clickLeft:  isRight = touchStartX < (1.0 - store.rightClickThreshold)
                            case .none:       isRight = false
                            }
                            emit(.tap(location: tapLoc, isRight: isRight))
                            lastTapEndTime = ProcessInfo.processInfo.systemUptime
                        }
                    }
                } else {
                    tapDetector.reset()
                    isDoubleTapInProgress = false
                }
                activeTouch = -1; touchStartX = 0; touchStartY = 0
            } else {
                isDoubleTapInProgress = false
            }
            disqualifiedTouches.removeAll(keepingCapacity: true)
            return
        }

        guard count == 1 else { return }
        let touch = raw[0]
        let loc = CGEvent(source: nil)?.location ?? .zero

        // Active edge slider tracking
        if isEdgeSliding, activeTouch == touch.identifier {
            guard store.isEdgeSlidersEnabled else {
                resetEdgeSliderState(); return
            }
            let currentY = touch.normalized.position.y
            let diff = currentY - edgeSliderTriggerY
            let step = store.edgeSliderStepDistance
            let side = activeEdgeSide!
            if diff >= step {
                let steps = Int(diff / step)
                edgeSliderTriggerY += Float(steps) * step
                for _ in 0..<steps {
                    emit(.edgeSlide(side: side, delta: 0.0625, location: loc))
                }
            } else if diff <= -step {
                let steps = Int(-diff / step)
                edgeSliderTriggerY -= Float(steps) * step
                for _ in 0..<steps {
                    emit(.edgeSlide(side: side, delta: -0.0625, location: loc))
                }
            }
            return
        }

        if disqualifiedTouches.contains(touch.identifier) { return }
        guard touch.state >= 3 && touch.state <= 5 else { return }

        if activeTouch == -1 {
            activeTouch = touch.identifier
            touchStartX = touch.normalized.position.x
            touchStartY = touch.normalized.position.y
            edgeSliderTriggerY = touchStartY

            // Double-tap window check
            if store.isTapToClickEnabled, store.gestureConfiguration.doubleTap != .none {
                let elapsed = ProcessInfo.processInfo.systemUptime - lastTapEndTime
                if elapsed < 0.28 { isDoubleTapInProgress = true }
            }

            setCandidateEdgeSide(candidateFor(x: touchStartX))
            if touchStartY >= store.minTapY && !isScrollVetoActive {
                tapDetector.touchBegan(at: loc)
            } else {
                tapDetector.reset()
            }
        } else if activeTouch == touch.identifier {
            if let side = candidateEdgeSide, !isEdgeSliding {
                let deltaY = touch.normalized.position.y - touchStartY
                let absDeltaX = abs(touch.normalized.position.x - touchStartX)
                let driftedIn = (side == .right && touch.normalized.position.x < store.rightEdgeThreshold - 0.02)
                    || (side == .left  && touch.normalized.position.x > store.leftEdgeThreshold  + 0.02)
                    || absDeltaX >= 0.08

                if abs(deltaY) >= store.edgeSliderActivationThreshold && !driftedIn {
                    activateEdgeSide(side, triggerY: touch.normalized.position.y)
                    tapDetector.reset()
                    let delta: Float = deltaY > 0 ? 0.0625 : -0.0625
                    emit(.edgeSlide(side: side, delta: delta, location: loc))
                    return
                } else if driftedIn {
                    setCandidateEdgeSide(nil)
                } else {
                    if tapDetector.isTracking {
                        if tapDetector.isExpired || tapDetector.touchMoved(to: loc) { tapDetector.reset() }
                    }
                    return
                }
            }

            if tapDetector.isTracking {
                let dx = abs(touch.normalized.position.x - touchStartX)
                let dy = abs(touch.normalized.position.y - touchStartY) * Float(110.0 / 58.0)
                if max(dx, dy) > surfaceMovementThreshold || tapDetector.isExpired || tapDetector.touchMoved(to: loc) {
                    tapDetector.reset()
                }
            }
        }
    }

    // MARK: - Palm / grip filtering

    private func filterUpperFingers(_ raw: UnsafeMutablePointer<MTTouch>, count: Int) -> [SurfaceTouch] {
        var result: [SurfaceTouch] = []
        for i in 0..<count {
            let t = raw[i]
            guard t.state >= 3 && t.state <= 5 else { continue }
            let x = CGFloat(t.normalized.position.x)
            let y = CGFloat(t.normalized.position.y)
            guard y >= 0.18, x >= 0.08, x <= 0.92, t.size <= 2.6 else { continue }
            result.append(SurfaceTouch(identifier: t.identifier, position: CGPoint(x: x, y: y)))
        }
        return result
    }

    // MARK: - Edge slider helpers

    private func candidateFor(x: Float) -> EdgeSide? {
        guard store.isEdgeSlidersEnabled else { return nil }
        let cfg = store.gestureConfiguration
        if x <= store.leftEdgeThreshold  { return cfg.leftEdge  != .none ? .left  : nil }
        if x >= store.rightEdgeThreshold { return cfg.rightEdge != .none ? .right : nil }
        return nil
    }

    private func setCandidateEdgeSide(_ side: EdgeSide?) {
        os_unfair_lock_lock(&gestureLock); candidateEdgeSide = side; os_unfair_lock_unlock(&gestureLock)
    }

    private func activateEdgeSide(_ side: EdgeSide, triggerY: Float) {
        os_unfair_lock_lock(&gestureLock)
        candidateEdgeSide = nil; isEdgeSliding = true; activeEdgeSide = side
        edgeSliderTriggerY = triggerY
        os_unfair_lock_unlock(&gestureLock)
    }

    private func resetEdgeSliderState() {
        os_unfair_lock_lock(&gestureLock)
        candidateEdgeSide = nil; isEdgeSliding = false; activeEdgeSide = nil
        os_unfair_lock_unlock(&gestureLock)
    }

    // MARK: - Disqualification & reset helpers

    private func disqualifyAll(_ raw: UnsafeMutablePointer<MTTouch>, count: Int) {
        for i in 0..<count { disqualifiedTouches.insert(raw[i].identifier) }
    }

    private func cancelSingleTouchTracking() {
        isDoubleTapInProgress = false
        tapDetector.reset()
        activeTouch = -1; touchStartX = 0; touchStartY = 0
    }

    func resetAll() {
        isDoubleTapInProgress = false
        twoFingerTapDetector.reset(); threeFingerDetector.reset()
        pinchZoomDetector.reset(); twoFingerMoveZoomDetector.reset()
        twoFingerSwipeDetector.reset(); cancelSingleTouchTracking()
        disqualifiedTouches.removeAll(keepingCapacity: true)
        resetEdgeSliderState(); releaseDragLock()
    }

    // MARK: - Emit

    private func emit(_ event: GestureEvent) {
        onRecognized?(event)
    }
}
