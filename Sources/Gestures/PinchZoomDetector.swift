import Foundation
import CoreGraphics

/// Detects two-finger pinch-to-zoom gestures on Magic Mouse and synthesizes native macOS magnification events.
final class PinchZoomDetector {
    var isEnabled: Bool = true

    /// Distance change threshold to initiate pinch (~2.2mm)
    let activationThreshold: CGFloat

    /// Sensitivity multiplier mapping surface distance change to magnification delta
    let sensitivity: CGFloat

    /// When true (e.g. system is actively scrolling or in momentum phase), pinch zoom is suppressed.
    var isScrollVetoActive: Bool = false

    private var initialPositions: [Int32: CGPoint] = [:]
    private var initialDistance: CGFloat?
    private var lastDistance: CGFloat?
    private var smoothedDistance: CGFloat?
    private(set) var isPinching = false
    private var lastPinchEndTime: TimeInterval = 0.0

    var onMagnification: ((Double, Int64, CGPoint) -> Void)?

    init(
        activationThreshold: CGFloat = 0.038,
        sensitivity: CGFloat = 2.4
    ) {
        self.activationThreshold = activationThreshold
        self.sensitivity = sensitivity
    }

    /// True while actively pinching or within residual cooldown (suppresses scrollWheel)
    var isGestureActive: Bool {
        isPinching || (Date().timeIntervalSinceReferenceDate - lastPinchEndTime < 0.18)
    }

    func process(touches: [SurfaceTouch], timestamp: TimeInterval) {
        guard isEnabled, !isScrollVetoActive else {
            if isPinching { endPinch() }
            initialPositions.removeAll(keepingCapacity: true)
            initialDistance = nil
            lastDistance = nil
            smoothedDistance = nil
            return
        }

        guard touches.count == 2 else {
            if isPinching {
                endPinch()
            } else {
                initialPositions.removeAll(keepingCapacity: true)
                initialDistance = nil
                lastDistance = nil
                smoothedDistance = nil
            }
            return
        }

        let t1 = touches[0]
        let t2 = touches[1]

        // Calculate aspect-ratio corrected surface distance (Magic Mouse is 110mm tall, 58mm wide)
        let dx = t1.position.x - t2.position.x
        let dy = (t1.position.y - t2.position.y) * CGFloat(110.0 / 58.0)
        let rawDist = hypot(dx, dy)

        // EMA smoothing: alpha=0.35 → ~65% weight on history, kills high-freq jitter
        let alpha: CGFloat = 0.35
        let currentDist: CGFloat
        if let prev = smoothedDistance {
            currentDist = alpha * rawDist + (1 - alpha) * prev
        } else {
            currentDist = rawDist
        }
        smoothedDistance = currentDist

        if initialPositions.count < 2 {
            initialPositions[t1.identifier] = t1.position
            initialPositions[t2.identifier] = t2.position
            initialDistance = currentDist
            lastDistance = currentDist
            return
        }

        guard let init1 = initialPositions[t1.identifier],
              let init2 = initialPositions[t2.identifier],
              let initDist = initialDistance,
              let lastDist = lastDistance else {
            initialPositions[t1.identifier] = t1.position
            initialPositions[t2.identifier] = t2.position
            initialDistance = currentDist
            lastDistance = currentDist
            return
        }

        let totalDelta = currentDist - initDist
        let frameDelta = currentDist - lastDist

        if !isPinching {
            // CRITICAL: BOTH fingers must move to constitute a pinch!
            // If one finger is scrolling while the other rests stationary, the euclidean distance changes,
            // but the resting finger's movement is near 0.
            let move1 = hypot(t1.position.x - init1.x, (t1.position.y - init1.y) * CGFloat(110.0 / 58.0))
            let move2 = hypot(t2.position.x - init2.x, (t2.position.y - init2.y) * CGFloat(110.0 / 58.0))
            let minPinchPerFinger: CGFloat = 0.016

            guard move1 >= minPinchPerFinger && move2 >= minPinchPerFinger else {
                return
            }

            if abs(totalDelta) >= activationThreshold {
                isPinching = true
                let cgLocation = CGEvent(source: nil)?.location ?? .zero
                // Phase 1: Began (kIOHIDEventPhaseBegan)
                onMagnification?(0.0, 1, cgLocation)

                // Initial frame delta
                let mag = Double(frameDelta * sensitivity)
                // Phase 2: Changed (kIOHIDEventPhaseChanged)
                onMagnification?(mag, 2, cgLocation)
                lastDistance = currentDist
            }
        } else {
            // Dead zone: ignore micro-jitter below 0.003 per frame
            if abs(frameDelta) > 0.003 {
                let mag = Double(frameDelta * sensitivity)
                let cgLocation = CGEvent(source: nil)?.location ?? .zero
                // Phase 2: Changed (kIOHIDEventPhaseChanged)
                onMagnification?(mag, 2, cgLocation)
                lastDistance = currentDist
            }
        }
    }

    private func endPinch() {
        guard isPinching else {
            initialPositions.removeAll(keepingCapacity: true)
            initialDistance = nil
            lastDistance = nil
            return
        }
        isPinching = false
        lastPinchEndTime = Date().timeIntervalSinceReferenceDate
        let cgLocation = CGEvent(source: nil)?.location ?? .zero
        // Phase 4: Ended (kIOHIDEventPhaseEnded)
        onMagnification?(0.0, 4, cgLocation)
        initialPositions.removeAll(keepingCapacity: true)
        initialDistance = nil
        lastDistance = nil
    }

    func reset() {
        if isPinching {
            endPinch()
        }
        initialPositions.removeAll(keepingCapacity: true)
        initialDistance = nil
        lastDistance = nil
        smoothedDistance = nil
        isPinching = false
    }
}
