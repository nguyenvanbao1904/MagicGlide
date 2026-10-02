import Foundation
import CoreGraphics

/// Detects two-finger vertical swipe gestures (Swipe Up and Swipe Down) on the Magic Mouse surface.
/// Coordinates on Magic Mouse: Y = 1.0 (fingertips / front), Y = 0.0 (palm / logo / rear).
/// - Swiping towards fingertips (increasing Y, deltaY > 0) triggers Swipe Up.
/// - Swiping towards palm (decreasing Y, deltaY < 0) triggers Swipe Down.
final class TwoFingerSwipeDetector {
    var isSwipeUpEnabled: Bool = true
    var isSwipeDownEnabled: Bool = true

    /// Minimum vertical displacement required to recognize a swipe (~5mm of travel)
    let swipeThreshold: CGFloat

    /// Maximum allowable finger-distance change before classifying as pinch instead of parallel swipe
    let maxDistanceChange: CGFloat

    private var initialPositions: [Int32: CGPoint] = [:]
    private var initialFingerDistance: CGFloat?
    private var hasTriggeredInCurrentStroke = false
    private var lastSwipeEndTime: TimeInterval = 0.0

    /// When true (e.g. system is actively scrolling or in momentum phase), 2-finger swipe is suppressed.
    var isScrollVetoActive: Bool = false

    var onSwipeUp: ((CGPoint) -> Void)?
    var onSwipeDown: ((CGPoint) -> Void)?

    init(
        swipeThreshold: CGFloat = 0.035,
        maxDistanceChange: CGFloat = 0.075
    ) {
        self.swipeThreshold = swipeThreshold
        self.maxDistanceChange = maxDistanceChange
    }

    /// True while actively swiping or within cooldown to suppress scrollWheel events
    var isGestureActive: Bool {
        hasTriggeredInCurrentStroke || (Date().timeIntervalSinceReferenceDate - lastSwipeEndTime < 0.20)
    }

    /// Process incoming touch frames.
    /// Returns true if a swipe gesture was triggered on this frame.
    @discardableResult
    func process(touches: [SurfaceTouch], timestamp: TimeInterval) -> Bool {
        // Prevent starting a new swipe sequence if scroll veto (momentum) is active.
        // Once fingers are anchored, ongoing motion of the swipe itself must not be killed by scroll events.
        if initialPositions.isEmpty && isScrollVetoActive {
            return false
        }

        guard touches.count == 2 else {
            if hasTriggeredInCurrentStroke {
                lastSwipeEndTime = Date().timeIntervalSinceReferenceDate
            }
            initialPositions.removeAll(keepingCapacity: true)
            initialFingerDistance = nil
            hasTriggeredInCurrentStroke = false
            return false
        }

        let t1 = touches[0]
        let t2 = touches[1]

        // Aspect ratio correction (110mm height vs 58mm width)
        let dx = t1.position.x - t2.position.x
        let dy = (t1.position.y - t2.position.y) * CGFloat(110.0 / 58.0)
        let currentDistance = hypot(dx, dy)

        // Store initial positions if fresh 2-finger contact
        if initialPositions.count < 2 {
            initialPositions[t1.identifier] = t1.position
            initialPositions[t2.identifier] = t2.position
            initialFingerDistance = currentDistance
            hasTriggeredInCurrentStroke = false
            return false
        }

        guard !hasTriggeredInCurrentStroke,
              let init1 = initialPositions[t1.identifier],
              let init2 = initialPositions[t2.identifier],
              let initDist = initialFingerDistance else {
            return false
        }

        // 1. Reject if fingers are clearly pinching or spreading apart (intentional pinch)
        if abs(currentDistance - initDist) > maxDistanceChange {
            return false
        }

        let deltaY1 = t1.position.y - init1.y
        let deltaY2 = t2.position.y - init2.y
        let deltaX1 = t1.position.x - init1.x
        let deltaX2 = t2.position.x - init2.x

        let avgDeltaY = (deltaY1 + deltaY2) / 2.0
        let avgDeltaX = (deltaX1 + deltaX2) / 2.0

        // 2. Movement must be predominantly vertical
        guard abs(avgDeltaY) > abs(avgDeltaX) else {
            return false
        }

        // 3. Threshold and direction verification:
        // CRITICAL REQUIREMENT:
        // A true two-finger swipe requires BOTH fingers to actively move together in the same vertical direction.
        // If a user rests 2 fingers on the mouse surface (index + middle) but only scrolls with 1 finger,
        // the resting finger remains virtually stationary (|deltaY| < 0.015).
        // This MUST NOT trigger a two-finger swipe!
        let minPerFinger = swipeThreshold * 0.60 // ~0.021 (~2.3mm travel for EVERY finger)
        let cgLocation = CGEvent(source: nil)?.location ?? .zero

        if avgDeltaY >= swipeThreshold {
            // Moving towards fingertips -> Swipe Up
            // Both fingers MUST individually move upwards by at least minPerFinger
            guard deltaY1 >= minPerFinger && deltaY2 >= minPerFinger else {
                return false
            }

            // Symmetry check: prevent extreme asymmetric drift
            let minMove = min(deltaY1, deltaY2)
            let maxMove = max(deltaY1, deltaY2)
            guard maxMove <= 3.5 * minMove else {
                return false
            }

            hasTriggeredInCurrentStroke = true
            lastSwipeEndTime = Date().timeIntervalSinceReferenceDate
            if isSwipeUpEnabled {
                onSwipeUp?(cgLocation)
                return true
            }
        } else if avgDeltaY <= -swipeThreshold {
            // Moving towards palm -> Swipe Down
            // Both fingers MUST individually move downwards by at least minPerFinger
            guard deltaY1 <= -minPerFinger && deltaY2 <= -minPerFinger else {
                return false
            }

            // Symmetry check: prevent extreme asymmetric drift
            let minAbsMove = min(abs(deltaY1), abs(deltaY2))
            let maxAbsMove = max(abs(deltaY1), abs(deltaY2))
            guard maxAbsMove <= 3.5 * minAbsMove else {
                return false
            }

            hasTriggeredInCurrentStroke = true
            lastSwipeEndTime = Date().timeIntervalSinceReferenceDate
            if isSwipeDownEnabled {
                onSwipeDown?(cgLocation)
                return true
            }
        }

        return false
    }

    func reset() {
        initialPositions.removeAll(keepingCapacity: true)
        initialFingerDistance = nil
        hasTriggeredInCurrentStroke = false
    }
}
