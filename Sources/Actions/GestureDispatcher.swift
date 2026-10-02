import Foundation
import CoreGraphics
import os

/// Maps GestureEvent → GestureAction (via GestureConfiguration) → ActionExecutor.
///
/// This is the single routing table between "what the user did" and "what should happen".
/// AppDelegate creates it and wires engine.onRecognized = dispatcher.handle.
final class GestureDispatcher {
    private let store: PreferenceStore
    private let executor: ActionExecutor
    private let log = OSLog(subsystem: "com.magicglide", category: "GestureDispatcher")

    // Smart-zoom double-tap disambiguation buffer
    private var pendingTapWorkItem: DispatchWorkItem?
    private var lastTapEndTime: TimeInterval = 0.0
    private var tapLock = os_unfair_lock_s()

    init(store: PreferenceStore, executor: ActionExecutor) {
        self.store = store
        self.executor = executor
    }

    // MARK: - Main entry point

    func handle(_ event: GestureEvent) {
        let config = store.gestureConfiguration
        switch event {

        // MARK: Tap
        case .tap(let loc, let isRight):
            guard store.isTapToClickEnabled else { return }
            if config.doubleTap != .none && !isRight {
                scheduleBufferedTap(location: loc)
            } else {
                executor.execute(isRight ? .none : .none, event: event)
                ClickSynthesizer.synthesizeClick(at: loc, isRightClick: isRight)
            }

        case .doubleTap(let loc):
            cancelPendingTap()
            executor.execute(config.doubleTap, event: .doubleTap(location: loc))

        // MARK: Two-finger
        case .twoFingerTap(let loc):
            executor.execute(config.twoFingerTap, event: .twoFingerTap(location: loc))

        case .physicalTwoFingerClick:
            executor.execute(config.twoFingerClick, event: event)

        // MARK: Three-finger
        case .threeFingerTap(let loc):
            executor.execute(config.threeFingerTap, event: .threeFingerTap(location: loc))

        case .physicalThreeFingerClick:
            executor.execute(config.threeFingerTap, event: event)

        case .threeFingerSwipe(let dir, let loc):
            let action: GestureAction
            let forward: Bool
            switch dir {
            case .forward:  // swipe right
                action = config.threeFingerSwipe
                forward = !config.isThreeFingerNaturalSwipe
            case .backward: // swipe left
                action = config.threeFingerSwipe
                forward = config.isThreeFingerNaturalSwipe
            }
            executor.execute(action, event: .threeFingerSwipe(direction: forward ? .forward : .backward, location: loc))

        // MARK: Two-finger swipe
        case .twoFingerSwipeUp(let loc):
            executor.execute(config.twoFingerSwipeUp, event: .twoFingerSwipeUp(location: loc))

        case .twoFingerSwipeDown(let loc):
            executor.execute(config.twoFingerSwipeDown, event: .twoFingerSwipeDown(location: loc))

        // MARK: Continuous
        case .magnification(let mag, let phase, let loc):
            // magnification events come from both pinch and move detectors; dispatch to whichever is configured
            executor.execute(config.pinch != .none ? config.pinch : config.twoFingerMove,
                             event: .magnification(magnitude: mag, phase: phase, location: loc))

        case .edgeSlide(let side, let delta, let loc):
            let action = side == .left ? config.leftEdge : config.rightEdge
            executor.execute(action, event: .edgeSlide(side: side, delta: delta, location: loc))

        // MARK: Drag lock
        case .dragLockToggle(let loc):
            executor.execute(.dragLock, event: .dragLockToggle(location: loc))
        }
    }

    // MARK: - Smart zoom disambiguation

    private func scheduleBufferedTap(location: CGPoint) {
        cancelPendingTap()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            var shouldFire = false
            os_unfair_lock_lock(&self.tapLock)
            if self.pendingTapWorkItem != nil {
                self.pendingTapWorkItem = nil
                shouldFire = true
            }
            os_unfair_lock_unlock(&self.tapLock)
            if shouldFire {
                ClickSynthesizer.synthesizeClick(at: location, isRightClick: false)
            }
        }
        os_unfair_lock_lock(&tapLock)
        pendingTapWorkItem = workItem
        lastTapEndTime = ProcessInfo.processInfo.systemUptime
        os_unfair_lock_unlock(&tapLock)
        DispatchQueue.main.asyncAfter(deadline: .now() + store.smartZoomBufferDelay, execute: workItem)
    }

    private func cancelPendingTap() {
        os_unfair_lock_lock(&tapLock)
        pendingTapWorkItem?.cancel()
        pendingTapWorkItem = nil
        os_unfair_lock_unlock(&tapLock)
    }

    var lastTapTimestamp: TimeInterval { lastTapEndTime }
}
