import XCTest
import CoreGraphics
@testable import MagicGlideLib

final class GestureArchitectureTests: XCTestCase {

    func testGestureSlotsAreComplete() {
        let expectedSlots: [GestureSlot] = [
            .twoFingerTap,
            .threeFingerTap,
            .threeFingerSwipe,
            .doubleTap,
            .leftEdge,
            .rightEdge,
            .twoFingerMove,
            .pinch,
            .twoFingerSwipeUp,
            .twoFingerSwipeDown,
            .twoFingerClick
        ]
        XCTAssertEqual(GestureSlot.allCases.count, expectedSlots.count)
        for slot in expectedSlots {
            XCTAssertTrue(GestureSlot.allCases.contains(slot))
        }
    }

    func testCompatibilityMatrix() {
        // Discrete tap slots
        let twoFingerCompatible = GestureAction.compatible(with: .twoFingerTap)
        XCTAssertTrue(twoFingerCompatible.contains(.none))
        XCTAssertTrue(twoFingerCompatible.contains(.middleClick))
        XCTAssertTrue(twoFingerCompatible.contains(.missionControl))
        XCTAssertTrue(twoFingerCompatible.contains(.showDesktop))
        XCTAssertTrue(twoFingerCompatible.contains(.smartZoom))
        XCTAssertTrue(twoFingerCompatible.contains(.dragLock))
        XCTAssertTrue(twoFingerCompatible.contains(.toggleTrackpadMode))
        XCTAssertFalse(twoFingerCompatible.contains(.switchTabs))
        XCTAssertFalse(twoFingerCompatible.contains(.zoom))

        // Physical two finger click slot
        let twoFingerClickCompatible = GestureAction.compatible(with: .twoFingerClick)
        XCTAssertTrue(twoFingerClickCompatible.contains(.none))
        XCTAssertTrue(twoFingerClickCompatible.contains(.middleClick))
        XCTAssertTrue(twoFingerClickCompatible.contains(.missionControl))
        XCTAssertTrue(twoFingerClickCompatible.contains(.showDesktop))
        XCTAssertTrue(twoFingerClickCompatible.contains(.smartZoom))
        XCTAssertTrue(twoFingerClickCompatible.contains(.toggleTrackpadMode))
        XCTAssertFalse(twoFingerClickCompatible.contains(.switchTabs))
        XCTAssertFalse(twoFingerClickCompatible.contains(.zoom))

        // Directional swipe slot
        let swipeCompatible = GestureAction.compatible(with: .threeFingerSwipe)
        XCTAssertTrue(swipeCompatible.contains(.none))
        XCTAssertTrue(swipeCompatible.contains(.switchTabs))
        XCTAssertTrue(swipeCompatible.contains(.switchSpaces))
        XCTAssertTrue(swipeCompatible.contains(.navigateHistory))
        XCTAssertFalse(swipeCompatible.contains(.middleClick))
        XCTAssertFalse(swipeCompatible.contains(.zoom))

        // Continuous edge slots
        let leftEdgeCompatible = GestureAction.compatible(with: .leftEdge)
        XCTAssertTrue(leftEdgeCompatible.contains(.none))
        XCTAssertTrue(leftEdgeCompatible.contains(.brightness))
        XCTAssertTrue(leftEdgeCompatible.contains(.volume))
        XCTAssertFalse(leftEdgeCompatible.contains(.zoom))
        XCTAssertFalse(leftEdgeCompatible.contains(.middleClick))

        let rightEdgeCompatible = GestureAction.compatible(with: .rightEdge)
        XCTAssertTrue(rightEdgeCompatible.contains(.none))
        XCTAssertTrue(rightEdgeCompatible.contains(.volume))
        XCTAssertTrue(rightEdgeCompatible.contains(.brightness))
        XCTAssertFalse(rightEdgeCompatible.contains(.zoom))

        // Continuous 2-finger move slot
        let moveCompatible = GestureAction.compatible(with: .twoFingerMove)
        XCTAssertTrue(moveCompatible.contains(.none))
        XCTAssertTrue(moveCompatible.contains(.zoom))
        XCTAssertTrue(moveCompatible.contains(.volume))
        XCTAssertTrue(moveCompatible.contains(.brightness))
        XCTAssertFalse(moveCompatible.contains(.middleClick))

        // Continuous pinch slot
        let pinchCompatible = GestureAction.compatible(with: .pinch)
        XCTAssertTrue(pinchCompatible.contains(.none))
        XCTAssertTrue(pinchCompatible.contains(.zoom))
        XCTAssertFalse(pinchCompatible.contains(.middleClick))
        XCTAssertFalse(pinchCompatible.contains(.volume))

        // 2-Finger Swipe Up / Down slots
        let swipeUpCompatible = GestureAction.compatible(with: .twoFingerSwipeUp)
        XCTAssertTrue(swipeUpCompatible.contains(.none))
        XCTAssertTrue(swipeUpCompatible.contains(.missionControl))
        XCTAssertTrue(swipeUpCompatible.contains(.appExpose))
        XCTAssertTrue(swipeUpCompatible.contains(.showDesktop))
        XCTAssertFalse(swipeUpCompatible.contains(.zoom))

        let swipeDownCompatible = GestureAction.compatible(with: .twoFingerSwipeDown)
        XCTAssertTrue(swipeDownCompatible.contains(.none))
        XCTAssertTrue(swipeDownCompatible.contains(.appExpose))
        XCTAssertTrue(swipeDownCompatible.contains(.showDesktop))
        XCTAssertTrue(swipeDownCompatible.contains(.missionControl))
        XCTAssertFalse(swipeDownCompatible.contains(.zoom))
    }

    func testGestureConfigurationSubscriptAndDefaults() {
        var config = GestureConfiguration.default
        XCTAssertEqual(config[.twoFingerTap], GestureAction.none)
        XCTAssertEqual(config[.threeFingerTap], GestureAction.none)
        XCTAssertEqual(config[.threeFingerSwipe], GestureAction.switchTabs)
        XCTAssertEqual(config[.doubleTap], GestureAction.smartZoom)
        XCTAssertEqual(config[.leftEdge], GestureAction.brightness)
        XCTAssertEqual(config[.rightEdge], GestureAction.volume)
        XCTAssertEqual(config[.twoFingerMove], GestureAction.none)
        XCTAssertEqual(config[.pinch], GestureAction.zoom)
        XCTAssertEqual(config[.twoFingerSwipeUp], GestureAction.missionControl)
        XCTAssertEqual(config[.twoFingerSwipeDown], GestureAction.appExpose)
        XCTAssertEqual(config[.twoFingerClick], GestureAction.middleClick)

        // Mutate via subscript
        config[.twoFingerSwipeUp] = .showDesktop
        XCTAssertEqual(config.twoFingerSwipeUp, GestureAction.showDesktop)
        XCTAssertEqual(config[.twoFingerSwipeUp], GestureAction.showDesktop)

        config[.twoFingerClick] = .toggleTrackpadMode
        XCTAssertEqual(config.twoFingerClick, GestureAction.toggleTrackpadMode)
        XCTAssertEqual(config[.twoFingerClick], GestureAction.toggleTrackpadMode)

        config[.twoFingerMove] = .volume
        XCTAssertEqual(config.twoFingerMove, GestureAction.volume)
        XCTAssertEqual(config[.twoFingerMove], GestureAction.volume)

        config[.pinch] = .none
        XCTAssertEqual(config.pinch, GestureAction.none)
        XCTAssertEqual(config[.pinch], GestureAction.none)
    }

    func testGestureConfigurationSerialization() throws {
        var config = GestureConfiguration.default
        config.twoFingerMove = .brightness
        config.pinch = .none
        config.leftEdge = .volume
        config.twoFingerClick = .toggleTrackpadMode

        let encoder = JSONEncoder()
        let data = try encoder.encode(config)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(GestureConfiguration.self, from: data)

        XCTAssertEqual(decoded.twoFingerMove, GestureAction.brightness)
        XCTAssertEqual(decoded.pinch, GestureAction.none)
        XCTAssertEqual(decoded.leftEdge, GestureAction.volume)
        XCTAssertEqual(decoded.rightEdge, GestureAction.volume)
        XCTAssertEqual(decoded.twoFingerClick, GestureAction.toggleTrackpadMode)
    }

    func testTwoFingerMoveZoomDetector_WithZoomAction() {
        let detector = TwoFingerMoveZoomDetector()
        detector.isEnabled = true
        var config = Preferences.gestureConfiguration
        config.twoFingerMove = .zoom
        Preferences.gestureConfiguration = config

        var magnifications: [(mag: Double, phase: Int64)] = []
        detector.onMagnification = { mag, phase, loc in
            magnifications.append((mag, phase))
        }

        // Contact began
        detector.updateTouchState(twoFingersTouching: true)
        XCTAssertFalse(detector.isGestureActive)

        // Mouse moved small delta (below activation threshold 3.0)
        let smallEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: CGPoint(x: 100, y: 100), mouseButton: .left)!
        smallEvent.setDoubleValueField(.mouseEventDeltaY, value: 1.0)
        let smallHandled = detector.handleMouseMoved(event: smallEvent)
        XCTAssertFalse(smallHandled)
        XCTAssertFalse(detector.isGestureActive)

        // Mouse moved further to cross threshold
        let engageEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: CGPoint(x: 100, y: 100), mouseButton: .left)!
        engageEvent.setDoubleValueField(.mouseEventDeltaY, value: 3.5)
        let engageHandled = detector.handleMouseMoved(event: engageEvent)
        XCTAssertTrue(engageHandled)
        XCTAssertTrue(detector.isGestureActive)

        // Phase 1 (Began) and Phase 2 (Changed) should have fired
        XCTAssertEqual(magnifications.count, 2)
        XCTAssertEqual(magnifications[0].phase, 1)
        XCTAssertEqual(magnifications[1].phase, 2)

        // Lifting fingers ends zoom
        detector.updateTouchState(twoFingersTouching: false)
        XCTAssertFalse(detector.isGestureActive)
        XCTAssertEqual(magnifications.last?.phase, 4) // Phase 4: Ended
    }

    func testTwoFingerMoveZoomDetector_WithVolumeAction() {
        let detector = TwoFingerMoveZoomDetector()
        detector.isEnabled = true
        detector.assignedAction = .volume
        var config = Preferences.gestureConfiguration
        config.twoFingerMove = .volume
        Preferences.gestureConfiguration = config

        var deltas: [(action: GestureAction, step: Float)] = []
        detector.onDeltaAction = { action, step, loc in
            deltas.append((action, step))
        }

        detector.updateTouchState(twoFingersTouching: true)

        let engageEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: CGPoint(x: 100, y: 100), mouseButton: .left)!
        engageEvent.setDoubleValueField(.mouseEventDeltaY, value: -5.0) // push forward
        let handled = detector.handleMouseMoved(event: engageEvent)
        XCTAssertTrue(handled)
        XCTAssertTrue(detector.isGestureActive)

        XCTAssertFalse(deltas.isEmpty)
        XCTAssertEqual(deltas[0].action, .volume)
        XCTAssertGreaterThan(deltas[0].step, 0) // push forward increases

        detector.endZoom()
        XCTAssertFalse(detector.isGestureActive)
    }

    func testTwoFingerMoveZoomDetector_DisabledOrNone() {
        let detector = TwoFingerMoveZoomDetector()
        detector.isEnabled = false

        detector.updateTouchState(twoFingersTouching: true)
        let event = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: CGPoint(x: 100, y: 100), mouseButton: .left)!
        event.setDoubleValueField(.mouseEventDeltaY, value: 10.0)
        XCTAssertFalse(detector.handleMouseMoved(event: event))
        XCTAssertFalse(detector.isGestureActive)
    }

    func testPinchZoomDetector_ThresholdAndPhases() {
        let detector = PinchZoomDetector(activationThreshold: 0.038, sensitivity: 2.0)
        detector.isEnabled = true

        var magnifications: [(mag: Double, phase: Int64)] = []
        detector.onMagnification = { mag, phase, loc in
            magnifications.append((mag, phase))
        }

        func touch(_ id: Int32, _ x: Float, _ y: Float) -> SurfaceTouch {
            SurfaceTouch(
                identifier: id,
                position: CGPoint(x: CGFloat(x), y: CGFloat(y))
            )
        }

        // Initial 2 finger contact
        detector.process(touches: [touch(1, 0.45, 0.5), touch(2, 0.55, 0.5)], timestamp: 1.0)
        XCTAssertFalse(detector.isPinching)
        XCTAssertEqual(magnifications.count, 0)

        // Pinch spread outwards (distance increases significantly)
        detector.process(touches: [touch(1, 0.35, 0.5), touch(2, 0.65, 0.5)], timestamp: 1.05)
        XCTAssertTrue(detector.isPinching)
        XCTAssertGreaterThanOrEqual(magnifications.count, 2)
        XCTAssertEqual(magnifications[0].phase, 1) // Began
        XCTAssertEqual(magnifications[1].phase, 2) // Changed

        // Release fingers
        detector.process(touches: [], timestamp: 1.10)
        XCTAssertFalse(detector.isPinching)
        XCTAssertEqual(magnifications.last?.phase, 4) // Ended
    }

    func testTwoFingerSwipeDetector() {
        let detector = TwoFingerSwipeDetector(swipeThreshold: 0.035, maxDistanceChange: 0.075)
        var swipeUpTriggered = false
        var swipeDownTriggered = false

        detector.onSwipeUp = { _ in swipeUpTriggered = true }
        detector.onSwipeDown = { _ in swipeDownTriggered = true }

        func touch(_ id: Int32, _ x: Float, _ y: Float) -> SurfaceTouch {
            SurfaceTouch(identifier: id, position: CGPoint(x: CGFloat(x), y: CGFloat(y)))
        }

        // Initial 2-finger placement
        detector.process(touches: [touch(1, 0.4, 0.4), touch(2, 0.6, 0.4)], timestamp: 1.0)
        XCTAssertFalse(swipeUpTriggered)
        XCTAssertFalse(detector.isGestureActive)

        // Move upwards (increasing Y: 0.4 -> 0.44)
        detector.process(touches: [touch(1, 0.4, 0.44), touch(2, 0.6, 0.44)], timestamp: 1.05)
        XCTAssertTrue(swipeUpTriggered)
        XCTAssertTrue(detector.isGestureActive)

        // Lift fingers
        detector.process(touches: [], timestamp: 1.10)
        swipeUpTriggered = false

        // Realistic swipe down: fingers start with index lower (0.45) and middle higher (0.52)
        // During downward motion, fingers naturally splay and move with slight lag
        detector.process(touches: [touch(1, 0.38, 0.45), touch(2, 0.58, 0.52)], timestamp: 2.0)
        XCTAssertFalse(swipeDownTriggered)

        // Touch 1 moved -0.040, Touch 2 moved -0.032, and X splays slightly (0.36 and 0.60)
        detector.process(touches: [touch(1, 0.36, 0.41), touch(2, 0.60, 0.488)], timestamp: 2.05)
        XCTAssertTrue(swipeDownTriggered)

        // Lift fingers
        detector.process(touches: [], timestamp: 2.10)
        swipeDownTriggered = false

        // Test pinch rejection: fingers move in opposite vertical directions
        detector.process(touches: [touch(1, 0.4, 0.5), touch(2, 0.6, 0.5)], timestamp: 3.0)
        detector.process(touches: [touch(1, 0.4, 0.55), touch(2, 0.6, 0.45)], timestamp: 3.05)
        XCTAssertFalse(swipeUpTriggered)
        XCTAssertFalse(swipeDownTriggered)
    }

    func testTwoFingerSwipeDetector_RejectsOneFingerScrollWithSecondFingerResting() {
        let detector = TwoFingerSwipeDetector(swipeThreshold: 0.035, maxDistanceChange: 0.075)
        var swipeUpTriggered = false
        var swipeDownTriggered = false

        detector.onSwipeUp = { _ in swipeUpTriggered = true }
        detector.onSwipeDown = { _ in swipeDownTriggered = true }

        func touch(_ id: Int32, _ x: Float, _ y: Float) -> SurfaceTouch {
            SurfaceTouch(identifier: id, position: CGPoint(x: CGFloat(x), y: CGFloat(y)))
        }

        // Two fingers resting on mouse: index finger at (0.4, 0.4), middle finger at (0.6, 0.4)
        detector.process(touches: [touch(1, 0.4, 0.4), touch(2, 0.6, 0.4)], timestamp: 1.0)

        // Case 1: User scrolls UP with index finger (+0.08 displacement), middle finger rests (0.00 movement)
        detector.process(touches: [touch(1, 0.4, 0.48), touch(2, 0.6, 0.40)], timestamp: 1.05)
        XCTAssertFalse(swipeUpTriggered, "1-finger scroll up while 2nd finger rests must NOT trigger 2-finger swipe up!")
        XCTAssertFalse(detector.isGestureActive)

        // Reset
        detector.process(touches: [], timestamp: 1.10)
        swipeUpTriggered = false

        // Case 2: User scrolls DOWN with index finger (-0.08 displacement), middle finger rests
        detector.process(touches: [touch(1, 0.4, 0.5), touch(2, 0.6, 0.5)], timestamp: 2.0)
        detector.process(touches: [touch(1, 0.4, 0.42), touch(2, 0.6, 0.50)], timestamp: 2.05)
        XCTAssertFalse(swipeDownTriggered, "1-finger scroll down while 2nd finger rests must NOT trigger 2-finger swipe down!")
        XCTAssertFalse(detector.isGestureActive)
    }

    func testTwoFingerSwipeDetector_ScrollVetoSuppressesSwipe() {
        let detector = TwoFingerSwipeDetector(swipeThreshold: 0.035, maxDistanceChange: 0.075)
        var swipeUpTriggered = false
        detector.onSwipeUp = { _ in swipeUpTriggered = true }

        func touch(_ id: Int32, _ x: Float, _ y: Float) -> SurfaceTouch {
            SurfaceTouch(identifier: id, position: CGPoint(x: CGFloat(x), y: CGFloat(y)))
        }

        // When scroll veto is active, even if both fingers move up, swipe must be suppressed
        detector.isScrollVetoActive = true
        detector.process(touches: [touch(1, 0.4, 0.4), touch(2, 0.6, 0.4)], timestamp: 1.0)
        detector.process(touches: [touch(1, 0.4, 0.45), touch(2, 0.6, 0.45)], timestamp: 1.05)

        XCTAssertFalse(swipeUpTriggered, "Swipe must be suppressed while scroll veto is active!")
    }

    func testPinchZoomDetector_RejectsOneFingerScrollWithSecondFingerResting() {
        let detector = PinchZoomDetector()
        detector.isEnabled = true
        var magnifications: [Double] = []
        detector.onMagnification = { mag, _, _ in magnifications.append(mag) }

        func touch(_ id: Int32, _ x: Float, _ y: Float) -> SurfaceTouch {
            SurfaceTouch(identifier: id, position: CGPoint(x: CGFloat(x), y: CGFloat(y)))
        }

        // Two fingers resting: finger 1 at (0.35, 0.45), finger 2 at (0.65, 0.45)
        detector.process(touches: [touch(1, 0.35, 0.45), touch(2, 0.65, 0.45)], timestamp: 1.0)

        // Finger 1 scrolls up (+0.20 vertical movement), finger 2 stays stationary
        // This causes euclidean distance to change drastically, but finger 2 didn't move!
        detector.process(touches: [touch(1, 0.35, 0.65), touch(2, 0.65, 0.45)], timestamp: 1.05)

        XCTAssertFalse(detector.isPinching, "1-finger scroll with stationary resting finger must NOT trigger pinch zoom!")
        XCTAssertEqual(magnifications.count, 0)
    }

    func testValidationAndSanitization() {
        XCTAssertTrue(GestureAction.zoom.isCompatible(with: .twoFingerMove))
        XCTAssertTrue(GestureAction.volume.isCompatible(with: .twoFingerMove))
        XCTAssertFalse(GestureAction.middleClick.isCompatible(with: .twoFingerMove))
        XCTAssertFalse(GestureAction.switchTabs.isCompatible(with: .twoFingerMove))

        XCTAssertTrue(GestureAction.missionControl.isCompatible(with: .twoFingerSwipeUp))
        XCTAssertTrue(GestureAction.appExpose.isCompatible(with: .twoFingerSwipeDown))
        XCTAssertFalse(GestureAction.zoom.isCompatible(with: .twoFingerSwipeUp))

        XCTAssertTrue(GestureAction.middleClick.isCompatible(with: .twoFingerClick))
        XCTAssertTrue(GestureAction.toggleTrackpadMode.isCompatible(with: .twoFingerClick))
        XCTAssertFalse(GestureAction.zoom.isCompatible(with: .twoFingerClick))

        var config = GestureConfiguration.default

        // Attempt to assign incompatible action via subscript should be rejected
        config[.twoFingerMove] = .middleClick
        XCTAssertEqual(config.twoFingerMove, GestureAction.none) // Unchanged!

        // If corrupted struct is created, sanitize() fixes it
        config.twoFingerMove = .middleClick
        config.threeFingerSwipe = .middleClick
        config.twoFingerSwipeUp = .zoom
        config.twoFingerClick = .zoom
        config.sanitize()

        XCTAssertEqual(config.twoFingerMove, GestureAction.none)
        XCTAssertEqual(config.threeFingerSwipe, GestureAction.switchTabs)
        XCTAssertEqual(config.twoFingerSwipeUp, GestureAction.missionControl)
        XCTAssertEqual(config.twoFingerClick, GestureAction.middleClick)
    }
}
