import XCTest
import CoreGraphics

@testable import MagicGlideLib

final class TwoFingerTapDetectorTests: XCTestCase {
    private var detector: TwoFingerTapDetector!

    override func setUp() {
        super.setUp()
        detector = TwoFingerTapDetector(tapTimeThreshold: 0.25, movementThreshold: 0.08)
    }

    override func tearDown() {
        detector = nil
        super.tearDown()
    }

    func testTwoFingerTap_WithStaggeredLandingAndLift_IsRecognized() {
        XCTAssertEqual(detector.process(touches: [touch(1, 0.3, 0.5)], timestamp: 10.00), .none)
        XCTAssertFalse(detector.suppressesSingleFingerTap)

        XCTAssertEqual(detector.process(touches: [touch(1, 0.3, 0.5), touch(2, 0.7, 0.5)], timestamp: 10.03), .none)
        XCTAssertTrue(detector.suppressesSingleFingerTap)

        XCTAssertEqual(detector.process(touches: [touch(2, 0.7, 0.5)], timestamp: 10.10), .none)
        XCTAssertTrue(detector.suppressesSingleFingerTap)

        XCTAssertEqual(detector.process(touches: [], timestamp: 10.14), .recognized)
        XCTAssertFalse(detector.suppressesSingleFingerTap)
    }

    func testSingleFingerTap_IsNotClaimed() {
        XCTAssertEqual(detector.process(touches: [touch(1, 0.4, 0.5)], timestamp: 1.0), .none)
        XCTAssertEqual(detector.process(touches: [], timestamp: 1.1), .none)
    }

    func testTwoFingerTap_AtTimeThreshold_IsRejected() {
        XCTAssertEqual(detector.process(touches: [touch(1), touch(2)], timestamp: 2.0), .none)
        XCTAssertEqual(
            detector.process(touches: [], timestamp: 2.25),
            .rejectedMultiTouchGesture
        )
    }

    func testTwoFingerTap_WithTooMuchMovement_IsRejected() {
        XCTAssertEqual(detector.process(touches: [touch(1, 0.2, 0.5), touch(2, 0.7, 0.5)], timestamp: 3.0), .none)
        XCTAssertEqual(detector.process(touches: [touch(1, 0.281, 0.5), touch(2, 0.7, 0.5)], timestamp: 3.1), .none)
        XCTAssertEqual(
            detector.process(touches: [], timestamp: 3.15),
            .rejectedMultiTouchGesture
        )
    }

    func testThreeFingerGesture_IsRejected() {
        XCTAssertEqual(
            detector.process(
                touches: [touch(1, 0.2, 0.5), touch(2, 0.5, 0.5), touch(3, 0.8, 0.5)],
                timestamp: 4.0
            ),
            .none
        )
        XCTAssertTrue(detector.suppressesSingleFingerTap)
        XCTAssertEqual(
            detector.process(touches: [], timestamp: 4.1),
            .rejectedMultiTouchGesture
        )
    }

    func testTwoIdentifiersWithoutOverlap_AreRejected() {
        XCTAssertEqual(detector.process(touches: [touch(1)], timestamp: 5.0), .none)
        XCTAssertEqual(detector.process(touches: [touch(2)], timestamp: 5.05), .none)
        XCTAssertTrue(detector.suppressesSingleFingerTap)
        XCTAssertEqual(
            detector.process(touches: [], timestamp: 5.1),
            .rejectedMultiTouchGesture
        )
    }

    func testResetClearsPartialGesture() {
        _ = detector.process(touches: [touch(1), touch(2)], timestamp: 6.0)
        XCTAssertTrue(detector.suppressesSingleFingerTap)

        detector.reset()

        XCTAssertFalse(detector.suppressesSingleFingerTap)
        XCTAssertEqual(detector.process(touches: [], timestamp: 6.1), .none)
    }

    func testInvalidGesture_DoesNotPoisonNextTap() {
        _ = detector.process(touches: [touch(1), touch(2), touch(3)], timestamp: 7.0)
        XCTAssertEqual(detector.process(touches: [], timestamp: 7.1), .rejectedMultiTouchGesture)

        _ = detector.process(touches: [touch(4), touch(5)], timestamp: 8.0)
        XCTAssertEqual(detector.process(touches: [], timestamp: 8.1), .recognized)
    }

    private func touch(
        _ identifier: Int32,
        _ x: CGFloat = 0.3,
        _ y: CGFloat = 0.5
    ) -> SurfaceTouch {
        SurfaceTouch(identifier: identifier, position: CGPoint(x: x, y: y))
    }
}
