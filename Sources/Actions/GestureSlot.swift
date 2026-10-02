import Foundation

/// Identifies which physical gesture on the Magic Mouse triggered an event.
/// Each slot maps 1:1 to a user-configurable action in GestureConfiguration.
enum GestureSlot: String, CaseIterable, Codable {
    case twoFingerTap      = "twoFingerTap"
    case threeFingerTap    = "threeFingerTap"
    case threeFingerSwipe  = "threeFingerSwipe"
    case doubleTap         = "doubleTap"
    case leftEdge          = "leftEdge"
    case rightEdge         = "rightEdge"
    case twoFingerMove       = "twoFingerMove"
    case pinch               = "pinch"
    case twoFingerSwipeUp    = "twoFingerSwipeUp"
    case twoFingerSwipeDown  = "twoFingerSwipeDown"
    case twoFingerClick      = "twoFingerClick"
}
