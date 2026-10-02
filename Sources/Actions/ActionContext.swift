import Foundation
import CoreGraphics

enum GestureDirection {
    case forward
    case backward
}

/// Carries runtime parameters for gesture execution.
/// Not all fields are relevant for every action.
struct ActionContext {
    /// For directional gestures (swipe): which way the user moved.
    var direction: GestureDirection?
    /// For continuous gestures (edge sliders, move, pinch): magnitude and sign of movement.
    var delta: Float?
    /// For click-style actions: screen coordinate for synthesis.
    var location: CGPoint?
    /// For continuous gestures with start/change/end lifecycle (e.g. magnification):
    /// 1 = Began, 2 = Changed, 4 = Ended.
    var phase: Int64?

    var cursorLocation: CGPoint { location ?? .zero }

    init(direction: GestureDirection? = nil, delta: Float? = nil, location: CGPoint? = nil, phase: Int64? = nil) {
        self.direction = direction
        self.delta = delta
        self.location = location
        self.phase = phase
    }
}
