import Foundation
import CoreGraphics

/// A typed, fully self-contained description of a completed or continuous gesture.
/// Replaces the bag-of-optionals ActionContext: each case carries exactly the fields
/// its action needs, so callers cannot accidentally omit a required value.
enum GestureEvent {
    // MARK: - Tap gestures
    case tap(location: CGPoint, isRight: Bool)
    case doubleTap(location: CGPoint)
    case twoFingerTap(location: CGPoint)
    case threeFingerTap(location: CGPoint)
    case physicalTwoFingerClick(location: CGPoint)
    case physicalThreeFingerClick(location: CGPoint)

    // MARK: - Swipe / directional
    case threeFingerSwipe(direction: GestureDirection, location: CGPoint)
    case twoFingerSwipeUp(location: CGPoint)
    case twoFingerSwipeDown(location: CGPoint)

    // MARK: - Continuous
    /// phase: 1=began, 2=changed, 4=ended  (matches IOHIDEventPhase)
    case magnification(magnitude: Double, phase: Int64, location: CGPoint)
    case edgeSlide(side: EdgeSide, delta: Float, location: CGPoint)

    // MARK: - Special
    case dragLockToggle(location: CGPoint)
}

enum EdgeSide {
    case left
    case right
}
