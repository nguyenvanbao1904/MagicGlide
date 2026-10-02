import Foundation
import CoreGraphics

enum TwoFingerTapResult: Equatable {
    case none
    case recognized
    case rejectedMultiTouchGesture
}

/// Detects a two-finger tap from successive MultitouchSupport frames.
///
/// The fingers do not have to land or lift in exactly the same callback frame. A gesture is
/// accepted after all fingers lift if exactly two identifiers participated, the two fingers
/// overlapped for at least one frame, and neither duration nor movement crossed its threshold.
final class TwoFingerTapDetector {
    let tapTimeThreshold: TimeInterval
    let movementThreshold: CGFloat

    private var sequenceStartTimestamp: TimeInterval?
    private var participatingIdentifiers = Set<Int32>()
    private var startPositions = [Int32: CGPoint]()
    private var maxFingerCount = 0
    private var disqualified = false

    /// True from the moment a second finger touches the surface until the tap is accepted,
    /// rejected, or abandoned. Used to suppress single-finger click processing so a two-finger
    /// tap doesn't fire a spurious one-finger click on touchdown or lift-off.
    private(set) var suppressesSingleFingerTap = false

    init(tapTimeThreshold: TimeInterval = 0.22, movementThreshold: CGFloat = 0.05) {
        self.tapTimeThreshold = tapTimeThreshold
        self.movementThreshold = movementThreshold
    }

    /// Feed the current frame's touches.
    /// Returns `.recognized` on the lift-off frame that completes a valid two-finger tap,
    /// `.rejectedMultiTouchGesture` if a multi-touch sequence finished without meeting the tap criteria,
    /// or `.none` while the gesture is in-flight or dormant.
    func process(touches: [SurfaceTouch], timestamp: TimeInterval) -> TwoFingerTapResult {
        if touches.isEmpty {
            return handleTouchSequenceEnd(timestamp: timestamp)
        }

        if sequenceStartTimestamp == nil {
            sequenceStartTimestamp = timestamp
        }

        for touch in touches {
            participatingIdentifiers.insert(touch.identifier)
            if startPositions[touch.identifier] == nil {
                startPositions[touch.identifier] = touch.position
            }
        }

        maxFingerCount = max(maxFingerCount, touches.count)

        if maxFingerCount >= 2 || participatingIdentifiers.count >= 2 {
            suppressesSingleFingerTap = true
        }

        if maxFingerCount > 2 || participatingIdentifiers.count > 2 {
            disqualified = true
        }

        for touch in touches {
            guard let start = startPositions[touch.identifier] else { continue }
            let dx = touch.position.x - start.x
            let dy = touch.position.y - start.y
            let dist = sqrt(dx * dx + dy * dy)
            if dist > movementThreshold {
                disqualified = true
            }
        }

        return .none
    }

    func reset() {
        sequenceStartTimestamp = nil
        participatingIdentifiers.removeAll()
        startPositions.removeAll()
        maxFingerCount = 0
        disqualified = false
        suppressesSingleFingerTap = false
    }

    private func handleTouchSequenceEnd(timestamp: TimeInterval) -> TwoFingerTapResult {
        guard let start = sequenceStartTimestamp else {
            reset()
            return .none
        }

        let duration = timestamp - start
        let hadTwoFingers = maxFingerCount == 2 && participatingIdentifiers.count == 2
        let withinTime = duration < tapTimeThreshold

        let success = hadTwoFingers && withinTime && !disqualified
        let wasMultiTouchAttempt = maxFingerCount >= 2 || participatingIdentifiers.count >= 2

        reset()

        if success {
            return .recognized
        } else if wasMultiTouchAttempt {
            return .rejectedMultiTouchGesture
        } else {
            return .none
        }
    }
}
