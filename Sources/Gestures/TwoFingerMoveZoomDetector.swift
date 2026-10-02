import Foundation
import CoreGraphics

/// Detects two-finger mouse movement (hold 2 fingers and push/pull physical mouse) to zoom,
/// while freezing the cursor in place.
final class TwoFingerMoveZoomDetector {
    var isEnabled: Bool = true
    /// Injected by GestureEngine; used to decide zoom vs volume/brightness.
    var assignedAction: GestureAction = .zoom
    var sensitivity: Double = 0.012

    private(set) var isZooming = false
    private var isTwoFingerContact = false
    private var pinnedLocation: CGPoint = .zero
    private var accumulatedDeltaY: Double = 0.0
    private let activationThreshold: Double = 3.0 // 3 screen pixels movement before zoom engages

    /// When true (e.g. user is actively scrolling or gesturing with fingers across the surface),
    /// Move-to-Zoom is suppressed so physical mouse movement is not hijacked.
    var isFingersSlidingOnSurface: Bool = false

    var onMagnification: ((Double, Int64, CGPoint) -> Void)?
    var onDeltaAction: ((GestureAction, Float, CGPoint) -> Void)?

    func updateTouchState(twoFingersTouching: Bool) {
        if !twoFingersTouching && isZooming {
            endZoom()
        }
        isTwoFingerContact = twoFingersTouching
        if !twoFingersTouching {
            accumulatedDeltaY = 0.0
            isFingersSlidingOnSurface = false
        }
    }

    /// True while actively zooming or during 2-finger contact
    var isGestureActive: Bool {
        isZooming
    }

    /// Called from handleDragEvent on mouseMoved.
    /// Returns true if the event was consumed for the gesture (freezing cursor).
    func handleMouseMoved(event: CGEvent) -> Bool {
        let action = assignedAction
        guard isEnabled, action != .none, isTwoFingerContact, !isFingersSlidingOnSurface else {
            if isZooming { endZoom() }
            return false
        }

        let deltaY = event.getDoubleValueField(.mouseEventDeltaY)
        // deltaY < 0 is push forward (increase)
        // deltaY > 0 is pull backward (decrease)

        if !isZooming {
            accumulatedDeltaY += abs(deltaY)
            if accumulatedDeltaY >= activationThreshold {
                isZooming = true
                pinnedLocation = event.location
                executeAction(action, deltaY: deltaY, phase: 1)
                executeAction(action, deltaY: deltaY, phase: 2)
                return true
            }
            return false
        } else {
            executeAction(action, deltaY: deltaY, phase: 2)
            return true
        }
    }

    private func executeAction(_ action: GestureAction, deltaY: Double, phase: Int64) {
        switch action {
        case .zoom:
            let mag = phase == 1 ? 0.0 : -deltaY * sensitivity
            if phase == 1 || abs(mag) > 0.0005 {
                onMagnification?(mag, phase, pinnedLocation)
            }
        case .volume, .brightness:
            if phase == 2 {
                let step = Float(-deltaY * 0.004)
                if abs(step) > 0.001 {
                    onDeltaAction?(action, step, pinnedLocation)
                }
            }
        default:
            break
        }
    }

    func endZoom() {
        guard isZooming else {
            accumulatedDeltaY = 0.0
            return
        }
        let action = assignedAction
        isZooming = false
        accumulatedDeltaY = 0.0
        if action == .zoom {
            // Phase 4: Ended
            onMagnification?(0.0, 4, pinnedLocation)
        }
    }

    func reset() {
        endZoom()
        isTwoFingerContact = false
    }
}
