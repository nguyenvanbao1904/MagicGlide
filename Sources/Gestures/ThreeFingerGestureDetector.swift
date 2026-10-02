import Foundation
import CoreGraphics

enum ThreeFingerGestureResult: Equatable {
    case none
    case middleClick
    case swipeLeft   // Delta X < 0
    case swipeRight  // Delta X > 0
    case swipeUp     // Delta Y > 0
    case swipeDown   // Delta Y < 0
}

/// Detects three-finger tap (Middle Click) and continuous three-finger horizontal scrubbing (Tab Switching).
final class ThreeFingerGestureDetector {
    var isTapEnabled: Bool = true
    var isSwipeEnabled: Bool = true
    /// Action assigned to three-finger swipe — injected by GestureEngine, used for step timing.
    var swipeAction: GestureAction = .switchTabs

    let tapTimeThreshold: TimeInterval
    let tapMovementThreshold: CGFloat

    /// Movement required to initiate tab switching (~1.6mm)
    let swipeActivationThreshold: CGFloat

    /// Movement required for each subsequent tab step during continuous slide (~1.16mm per tab)
    let swipeStepDistance: CGFloat

    /// Minimum time between consecutive tab steps (90ms)
    let minStepInterval: TimeInterval

    private var sequenceStartTimestamp: TimeInterval?
    private var liftOffStartTimestamp: TimeInterval?
    private var initialPositions: [Int32: CGPoint] = [:]
    private var sawThreeFingersSimultaneously = false
    private var isTapValid = true

    // Continuous swipe/scrub state
    private var isContinuousSwipeActive = false
    private var referenceAvgX: CGFloat = 0.0
    private var lastStepTimestamp: TimeInterval = 0.0
    private var totalStepsTriggered = 0

    init(
        tapTimeThreshold: TimeInterval = 0.32,
        tapMovementThreshold: CGFloat = 0.08,
        swipeActivationThreshold: CGFloat = 0.028,
        swipeStepDistance: CGFloat = 0.020,
        minStepInterval: TimeInterval = 0.09
    ) {
        self.tapTimeThreshold = tapTimeThreshold
        self.tapMovementThreshold = tapMovementThreshold
        self.swipeActivationThreshold = swipeActivationThreshold
        self.swipeStepDistance = swipeStepDistance
        self.minStepInterval = minStepInterval
    }

    /// True if 3 fingers have participated in the current sequence until all lift
    var suppressesOtherGestures: Bool {
        sawThreeFingersSimultaneously && initialPositions.count >= 3
    }

    /// True while 3 fingers are on surface or within step interval
    var isGestureActive: Bool {
        let activeInterval: TimeInterval = swipeAction == .switchSpaces ? 0.45 : 0.25
        return suppressesOtherGestures || (Date().timeIntervalSinceReferenceDate - lastStepTimestamp < activeInterval)
    }

    func process(touches: [SurfaceTouch], timestamp: TimeInterval) -> ThreeFingerGestureResult {
        guard !touches.isEmpty else {
            return finishSequence(at: timestamp)
        }

        // Lift-off handling: If 3 fingers touched and now lifting begins (finger count drops below 3):
        if sawThreeFingersSimultaneously && touches.count < 3 && !isContinuousSwipeActive {
            if touches.count <= 1 {
                return finishSequence(at: timestamp)
            }
            if liftOffStartTimestamp == nil {
                liftOffStartTimestamp = timestamp
            } else if timestamp - liftOffStartTimestamp! > 0.09 {
                // If remaining fingers stay on surface for > 90ms after lifting begins,
                // this is resting hand, NOT an intentional tap! Invalidate tap!
                isTapValid = false
            }
            return .none
        }

        // CRITICAL FIX: If continuous swipe is active and finger count drops below 3,
        // the user is lifting their fingers off the surface.
        // When lifting 3 fingers, one finger (usually the trailing finger) always peels off
        // a few milliseconds first, which suddenly shifts the contact centroid by ~5mm!
        // Freezing immediately prevents that lift-off peel from triggering a phantom A+1 or A-1 step!
        if isContinuousSwipeActive && touches.count < 3 {
            return .none
        }

        if sequenceStartTimestamp == nil {
            sequenceStartTimestamp = timestamp
        }

        guard let startTimestamp = sequenceStartTimestamp else {
            return .none
        }

        // Record initial positions for newly detected touches
        for touch in touches {
            if initialPositions[touch.identifier] == nil {
                initialPositions[touch.identifier] = touch.position
            }
        }

        if touches.count >= 3 {
            // Validate that 3 fingers are present across the surface
            let xs = touches.map { $0.position.x }
            let span = (xs.max() ?? 0) - (xs.min() ?? 0)
            if span >= 0.08 {
                sawThreeFingersSimultaneously = true
            }
        }

        if touches.count > 4 {
            // More than 4 touches: invalidate tap
            isTapValid = false
        }

        // Check if held too long for a tap
        if timestamp - startTimestamp >= tapTimeThreshold {
            isTapValid = false
        }

        // Only evaluate swipe or tap if 3 fingers participated
        guard sawThreeFingersSimultaneously || initialPositions.count >= 3 else {
            return .none
        }

        // Calculate average current position and delta from initial
        var totalX: CGFloat = 0.0
        var totalY: CGFloat = 0.0
        var totalDxFromInitial: CGFloat = 0.0
        var totalDyFromInitial: CGFloat = 0.0
        var count: CGFloat = 0.0

        for touch in touches {
            totalX += touch.position.x
            totalY += touch.position.y
            count += 1.0

            if let initialPos = initialPositions[touch.identifier] {
                let dx = touch.position.x - initialPos.x
                let dy = touch.position.y - initialPos.y
                totalDxFromInitial += dx
                totalDyFromInitial += dy

                let dist = hypot(dx, dy)
                if dist >= tapMovementThreshold {
                    isTapValid = false
                }
            }
        }

        guard isSwipeEnabled, count >= 3 else {
            return .none
        }

        let currentAvgX = totalX / count
        let avgDxFromInitial = totalDxFromInitial / count
        let avgDyFromInitial = totalDyFromInitial / count

        // 1. Initial activation: check vertical or horizontal 3-finger swipe
        if !isContinuousSwipeActive {
            // Check Vertical Swipe (Swipe Up / Swipe Down)
            let minPerFingerY: CGFloat = 0.015
            if abs(avgDyFromInitial) >= swipeActivationThreshold && abs(avgDyFromInitial) > abs(avgDxFromInitial) * 0.85 {
                var allVerticalAgree = true
                if avgDyFromInitial > 0 {
                    for touch in touches {
                        if let initPos = initialPositions[touch.identifier] {
                            let dy = touch.position.y - initPos.y
                            if dy < minPerFingerY {
                                allVerticalAgree = false
                                break
                            }
                        }
                    }
                    if allVerticalAgree {
                        isTapValid = false
                        totalStepsTriggered += 1
                        lastStepTimestamp = timestamp
                        return .swipeUp
                    }
                } else {
                    for touch in touches {
                        if let initPos = initialPositions[touch.identifier] {
                            let dy = touch.position.y - initPos.y
                            if dy > -minPerFingerY {
                                allVerticalAgree = false
                                break
                            }
                        }
                    }
                    if allVerticalAgree {
                        isTapValid = false
                        totalStepsTriggered += 1
                        lastStepTimestamp = timestamp
                        return .swipeDown
                    }
                }
            }

            // Check Horizontal Swipe (Swipe Left / Swipe Right)
            // CRITICAL: ALL 3 fingers must move together in the same horizontal direction!
            // If 1 finger moves horizontally while 2 fingers rest, reject!
            let minPerFingerX: CGFloat = 0.012
            var allFingersAgree = true

            if avgDxFromInitial > 0 {
                for touch in touches {
                    if let initPos = initialPositions[touch.identifier] {
                        let dx = touch.position.x - initPos.x
                        if dx < minPerFingerX {
                            allFingersAgree = false
                            break
                        }
                    }
                }
            } else {
                for touch in touches {
                    if let initPos = initialPositions[touch.identifier] {
                        let dx = touch.position.x - initPos.x
                        if dx > -minPerFingerX {
                            allFingersAgree = false
                            break
                        }
                    }
                }
            }

            guard allFingersAgree else {
                return .none
            }

            if abs(avgDxFromInitial) >= swipeActivationThreshold && abs(avgDxFromInitial) > abs(avgDyFromInitial) * 0.75 {
                isContinuousSwipeActive = true
                isTapValid = false
                lastStepTimestamp = timestamp
                referenceAvgX = currentAvgX
                totalStepsTriggered += 1

                let result: ThreeFingerGestureResult = avgDxFromInitial > 0 ? .swipeRight : .swipeLeft
                return result
            }
            return .none
        }

        // 2. Continuous scrubbing: step through tabs / spaces as fingers keep sliding
        let deltaX = currentAvgX - referenceAvgX
        let elapsed = timestamp - lastStepTimestamp

        let requiredInterval: TimeInterval = {
            switch swipeAction {
            case .switchSpaces:    return 0.45
            case .navigateHistory: return 0.30
            default:               return minStepInterval
            }
        }()

        // Require fresh movement of swipeStepDistance and minimum interval elapsed
        if abs(deltaX) >= swipeStepDistance && elapsed >= requiredInterval {
            lastStepTimestamp = timestamp
            totalStepsTriggered += 1
            referenceAvgX = currentAvgX

            if deltaX > 0 {
                return .swipeRight
            } else {
                return .swipeLeft
            }
        }

        return .none
    }

    func reset() {
        sequenceStartTimestamp = nil
        liftOffStartTimestamp = nil
        initialPositions.removeAll(keepingCapacity: true)
        sawThreeFingersSimultaneously = false
        isContinuousSwipeActive = false
        referenceAvgX = 0.0
        lastStepTimestamp = 0.0
        totalStepsTriggered = 0
        isTapValid = true
    }

    private func finishSequence(at timestamp: TimeInterval) -> ThreeFingerGestureResult {
        guard let startTimestamp = sequenceStartTimestamp else {
            reset()
            return .none
        }

        let duration = timestamp - startTimestamp
        let qualifiesAsTap = isTapEnabled
            && isTapValid
            && !isContinuousSwipeActive
            && totalStepsTriggered == 0
            && sawThreeFingersSimultaneously
            && initialPositions.count >= 3 && initialPositions.count <= 4
            && duration >= 0.025
            && duration <= tapTimeThreshold

        reset()

        if qualifiesAsTap {
            return .middleClick
        }
        return .none
    }
}
