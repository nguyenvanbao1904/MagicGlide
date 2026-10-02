import XCTest
import CoreGraphics

@testable import MagicGlideLib

final class ThreeFingerGestureDetectorTests: XCTestCase {
    private var detector: ThreeFingerGestureDetector!

    override func setUp() {
        super.setUp()
        detector = ThreeFingerGestureDetector(
            tapTimeThreshold: 0.35,
            tapMovementThreshold: 0.07,
            swipeActivationThreshold: 0.045,
            swipeStepDistance: 0.038,
            minStepInterval: 0.20
        )
    }

    override func tearDown() {
        detector = nil
        super.tearDown()
    }

    func testThreeFingerTap_TriggersMiddleClick() {
        let t1 = [touch(1, 0.3, 0.5), touch(2, 0.5, 0.5), touch(3, 0.7, 0.5)]
        XCTAssertEqual(detector.process(touches: t1, timestamp: 1.0), .none)
        XCTAssertTrue(detector.suppressesOtherGestures)

        // Lift fingers after 100ms
        XCTAssertEqual(detector.process(touches: [], timestamp: 1.10), .middleClick)
        XCTAssertFalse(detector.suppressesOtherGestures)
    }

    func testContinuousSwipe_StepsThroughMultipleTabsWithoutLifting() {
        // Step 0: 3 fingers land around avg X = 0.40
        let land = [touch(1, 0.30, 0.5), touch(2, 0.40, 0.5), touch(3, 0.50, 0.5)]
        XCTAssertEqual(detector.process(touches: land, timestamp: 1.0), .none)

        // Step 1: Slide right to avg X = 0.45 (dx = +0.05 >= 0.045) -> Tab 1 switches!
        let move1 = [touch(1, 0.35, 0.5), touch(2, 0.45, 0.5), touch(3, 0.55, 0.5)]
        XCTAssertEqual(detector.process(touches: move1, timestamp: 1.08), .swipeRight)

        // Step 2: Keep sliding to avg X = 0.49 (dx = +0.04 >= 0.038) after 210ms -> Tab 2 switches!
        let move2 = [touch(1, 0.39, 0.5), touch(2, 0.49, 0.5), touch(3, 0.59, 0.5)]
        XCTAssertEqual(detector.process(touches: move2, timestamp: 1.30), .swipeRight)

        // Pause/stop hand at avg X = 0.49 after 210ms -> No tabs switch! Stops on Tab 2!
        XCTAssertEqual(detector.process(touches: move2, timestamp: 1.55), .none)

        // Step 3 (Reverse): Slide backwards to avg X = 0.45 (dx = -0.04 <= -0.038) -> Steps back to Tab 1!
        let moveBack = [touch(1, 0.35, 0.5), touch(2, 0.45, 0.5), touch(3, 0.55, 0.5)]
        XCTAssertEqual(detector.process(touches: moveBack, timestamp: 1.80), .swipeLeft)

        // Step 4 (Lift-off): 1 finger lifts first (trailing finger peels off)
        // Even if centroid jumps from 0.45 to 0.50, it MUST be frozen (return .none)!
        let peelOneFinger = [touch(2, 0.48, 0.5), touch(3, 0.58, 0.5)]
        XCTAssertEqual(detector.process(touches: peelOneFinger, timestamp: 1.85), .none)

        // All fingers lifted: should NOT trigger middle click either
        XCTAssertEqual(detector.process(touches: [], timestamp: 1.90), .none)
    }

    func testTooFastMovement_DoesNotSpamTabsWithinCooldown() {
        let land = [touch(1, 0.30, 0.5), touch(2, 0.40, 0.5), touch(3, 0.50, 0.5)]
        XCTAssertEqual(detector.process(touches: land, timestamp: 1.0), .none)

        // First step
        let move1 = [touch(1, 0.35, 0.5), touch(2, 0.45, 0.5), touch(3, 0.55, 0.5)]
        XCTAssertEqual(detector.process(touches: move1, timestamp: 1.05), .swipeRight)

        // Too fast (only 50ms later, minStepInterval is 200ms) -> should be suppressed
        let move2 = [touch(1, 0.40, 0.5), touch(2, 0.50, 0.5), touch(3, 0.60, 0.5)]
        XCTAssertEqual(detector.process(touches: move2, timestamp: 1.10), .none)
    }

    func testThreeFingerTap_FastCrispTap_TriggersMiddleClick() {
        // Fast 30ms tap
        let t1 = [touch(1, 0.3, 0.5), touch(2, 0.5, 0.5), touch(3, 0.7, 0.5)]
        XCTAssertEqual(detector.process(touches: t1, timestamp: 2.0), .none)
        XCTAssertEqual(detector.process(touches: [], timestamp: 2.030), .middleClick)
    }

    func testThreeFingerTap_WithThumbResting_TriggersMiddleClick() {
        // 4 contacts (3 tapping fingers + thumb on mouse edge)
        let t1 = [touch(1, 0.1, 0.8), touch(2, 0.3, 0.5), touch(3, 0.5, 0.5), touch(4, 0.7, 0.5)]
        XCTAssertEqual(detector.process(touches: t1, timestamp: 3.0), .none)
        XCTAssertEqual(detector.process(touches: [], timestamp: 3.12), .middleClick)
    }

    func testFiveFingers_PalmResting_DoesNotTriggerMiddleClick() {
        // 5 contacts (palm / whole hand)
        let t1 = [touch(1, 0.1, 0.8), touch(2, 0.3, 0.5), touch(3, 0.5, 0.5), touch(4, 0.7, 0.5), touch(5, 0.9, 0.8)]
        XCTAssertEqual(detector.process(touches: t1, timestamp: 4.0), .none)
        XCTAssertEqual(detector.process(touches: [], timestamp: 4.10), .none)
    }

    func testThreeFingerTap_LiftingFingersWhileThumbStays_TriggersMiddleClick() {
        // 4 contacts (thumb + 3 fingers)
        let t1 = [touch(1, 0.1, 0.8), touch(2, 0.3, 0.5), touch(3, 0.5, 0.5), touch(4, 0.7, 0.5)]
        XCTAssertEqual(detector.process(touches: t1, timestamp: 5.0), .none)
        // 3 fingers lift, but thumb (id 1) stays on surface
        let thumbOnly = [touch(1, 0.1, 0.8)]
        XCTAssertEqual(detector.process(touches: thumbOnly, timestamp: 5.15), .middleClick)
    }

    func testDefaultTuned_MultiTabFluidStepping() {
        let tuned = ThreeFingerGestureDetector() // uses new default thresholds

        // Landing at center (0.45)
        let land = [touch(1, 0.35, 0.5), touch(2, 0.45, 0.5), touch(3, 0.55, 0.5)]
        XCTAssertEqual(tuned.process(touches: land, timestamp: 1.0), .none)

        // Step 1: Slide right by 0.030 (avg X = 0.48) -> Tab 1
        let step1 = [touch(1, 0.38, 0.5), touch(2, 0.48, 0.5), touch(3, 0.58, 0.5)]
        XCTAssertEqual(tuned.process(touches: step1, timestamp: 1.05), .swipeRight)

        // Step 2: Slide right by 0.022 (avg X = 0.502) at 100ms later -> Tab 2
        let step2 = [touch(1, 0.402, 0.5), touch(2, 0.502, 0.5), touch(3, 0.602, 0.5)]
        XCTAssertEqual(tuned.process(touches: step2, timestamp: 1.15), .swipeRight)

        // Step 3: Slide right by 0.022 (avg X = 0.524) at 100ms later -> Tab 3
        let step3 = [touch(1, 0.424, 0.5), touch(2, 0.524, 0.5), touch(3, 0.624, 0.5)]
        XCTAssertEqual(tuned.process(touches: step3, timestamp: 1.25), .swipeRight)

        // Step 4: Slide right by 0.022 (avg X = 0.546) at 100ms later -> Tab 4
        let step4 = [touch(1, 0.446, 0.5), touch(2, 0.546, 0.5), touch(3, 0.646, 0.5)]
        XCTAssertEqual(tuned.process(touches: step4, timestamp: 1.35), .swipeRight)
    }

    private func touch(_ id: Int32, _ x: CGFloat, _ y: CGFloat) -> SurfaceTouch {
        SurfaceTouch(identifier: id, position: CGPoint(x: x, y: y))
    }
}
