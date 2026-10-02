import Cocoa
import ApplicationServices

/// Manages the CGEventTap that intercepts raw mouse/scroll events.
///
/// Responsibilities (exactly three):
///   1. Scroll suppression  — drop scrollWheel while a gesture is active
///   2. Physical click interception — let GestureEngine decide if 2/3-finger click should transform
///   3. Mouse movement transform — freeze cursor (move-zoom) or convert to drag (drag-lock)
///
/// All gesture decisions are delegated OUT through closures; this class does not read
/// Preferences or call ActionExecutor directly.
final class EventTapController {
    // Wired by AppDelegate to GestureEngine
    var queryEngine: (() -> GestureEngine?)?

    // Called when a physical 2-finger click is intercepted; engine decides action
    var onPhysicalTwoFingerClick: ((CGPoint) -> Void)?
    var onPhysicalThreeFingerClick: ((CGPoint) -> Void)?

    private var eventTap: CFMachPort?
    private var eventTapRunLoopSource: CFRunLoopSource?
    private var isTwoFingerPhysicalClickActive = false
    private var isThreeFingerPhysicalClickActive = false
    private var trackpadScrollPassthrough = false
    private var trackpadMomentumEligibleUntil: TimeInterval = -1e9

    func setUp() -> Bool {
        guard eventTap == nil else { return true }
        let mask = (CGEventMask(1) << CGEventType.mouseMoved.rawValue)
            | (CGEventMask(1) << CGEventType.scrollWheel.rawValue)
            | (CGEventMask(1) << CGEventType.leftMouseDown.rawValue)
            | (CGEventMask(1) << CGEventType.leftMouseUp.rawValue)
            | (CGEventMask(1) << CGEventType.leftMouseDragged.rawValue)
            | (CGEventMask(1) << CGEventType.rightMouseDown.rawValue)
            | (CGEventMask(1) << CGEventType.rightMouseUp.rawValue)
            | (CGEventMask(1) << CGEventType.rightMouseDragged.rawValue)
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: eventTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            NSLog("[MagicGlide] Warning: Failed to create CGEventTap — check Accessibility permission.")
            return false
        }
        CGEvent.tapEnable(tap: tap, enable: true)
        let src = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        eventTap = tap
        eventTapRunLoopSource = src
        CFRunLoopAddSource(CFRunLoopGetMain(), src, .commonModes)
        return true
    }

    func setEnabled(_ enabled: Bool) {
        guard let tap = eventTap else { return }
        CGEvent.tapEnable(tap: tap, enable: enabled)
    }

    func tearDown() {
        if let src = eventTapRunLoopSource { CFRunLoopRemoveSource(CFRunLoopGetMain(), src, .commonModes) }
        if let tap = eventTap { CFMachPortInvalidate(tap) }
        eventTapRunLoopSource = nil
        eventTap = nil
    }

    // MARK: - Event handling

    fileprivate func handleEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            setEnabled(true)
            return Unmanaged.passUnretained(event)
        }

        let engine = queryEngine?()

        // ── Scroll suppression ──────────────────────────────────────────────────────────────
        if type == .scrollWheel {
            let momentumPhase = event.getIntegerValueField(.scrollWheelEventMomentumPhase)
            let scrollPhase   = event.getIntegerValueField(.scrollWheelEventScrollPhase)
            engine?.notifyScrollWheelOccurred(momentumPhase: momentumPhase)

            if TrackpadModeController.shared.isActive {
                let now = ProcessInfo.processInfo.systemUptime
                let isTwoFingers = engine?.isTwoFingersTouching(within: 0.08) ?? false
                let inMomentum   = momentumPhase == 1 || momentumPhase == 2
                let endsScroll   = scrollPhase == 4 || scrollPhase == 8
                let endsMomentum = momentumPhase == 3
                let mayStart     = now <= trackpadMomentumEligibleUntil

                if endsMomentum && trackpadScrollPassthrough {
                    trackpadScrollPassthrough = false; trackpadMomentumEligibleUntil = -1e9
                    return Unmanaged.passUnretained(event)
                } else if endsScroll && trackpadScrollPassthrough {
                    trackpadScrollPassthrough = false; trackpadMomentumEligibleUntil = now + 0.12
                    return Unmanaged.passUnretained(event)
                } else if isTwoFingers {
                    trackpadScrollPassthrough = true; trackpadMomentumEligibleUntil = -1e9
                    return Unmanaged.passUnretained(event)
                } else if inMomentum && (trackpadScrollPassthrough || mayStart) {
                    trackpadScrollPassthrough = true; trackpadMomentumEligibleUntil = -1e9
                    return Unmanaged.passUnretained(event)
                } else if trackpadScrollPassthrough {
                    return Unmanaged.passUnretained(event)
                } else {
                    trackpadScrollPassthrough = false; trackpadMomentumEligibleUntil = -1e9
                    return nil
                }
            }

            if engine?.isEdgeActive == true || engine?.isThreeFingerActive == true
                || engine?.isPinchActive == true || engine?.isMoveZoomActive == true
                || engine?.isTwoFingerSwipeActive == true {
                return nil
            }
            return Unmanaged.passUnretained(event)
        }

        // ── Physical click interception ─────────────────────────────────────────────────────
        if type == .leftMouseDown { SystemControl.markMissionControlInactive() }

        if type == .leftMouseDown || type == .rightMouseDown {
            if let eng = engine, eng.shouldTransformTwoFingerPhysicalClick() {
                isTwoFingerPhysicalClickActive = true
                let loc = CGEvent(source: nil)?.location ?? .zero
                onPhysicalTwoFingerClick?(loc)
                // Suppress the raw click — GestureDispatcher will synthesize the right action
                return nil
            }
            if let eng = engine, eng.shouldTransformPhysicalClickToMiddleClick() {
                isThreeFingerPhysicalClickActive = true
                let loc = CGEvent(source: nil)?.location ?? .zero
                onPhysicalThreeFingerClick?(loc)
                return nil
            }
            return Unmanaged.passUnretained(event)
        }

        if type == .leftMouseUp || type == .rightMouseUp {
            if isTwoFingerPhysicalClickActive   { isTwoFingerPhysicalClickActive   = false; return nil }
            if isThreeFingerPhysicalClickActive {
                isThreeFingerPhysicalClickActive = false
                engine?.suppressThreeFingerTapFor(0.7)
                return nil
            }
            return Unmanaged.passUnretained(event)
        }

        if type == .leftMouseDragged || type == .rightMouseDragged {
            if isTwoFingerPhysicalClickActive || isThreeFingerPhysicalClickActive {
                event.type = .otherMouseDragged
                event.setIntegerValueField(.mouseEventButtonNumber, value: 2)
                return Unmanaged.passUnretained(event)
            }
        }

        // ── Mouse movement ──────────────────────────────────────────────────────────────────
        guard type == .mouseMoved else { return Unmanaged.passUnretained(event) }

        if let eng = engine, eng.twoFingerMoveZoomDetector.handleMouseMoved(event: event) {
            return nil  // cursor frozen for move-to-zoom
        }

        if engine?.isDragLocked == true {
            event.type = .leftMouseDragged
            event.setIntegerValueField(.mouseEventButtonNumber, value: Int64(CGMouseButton.left.rawValue))
            event.setIntegerValueField(.mouseEventClickState, value: 1)
            event.setDoubleValueField(.mouseEventPressure, value: 1.0)
            return Unmanaged.passUnretained(event)
        }

        return Unmanaged.passUnretained(event)
    }
}

private let eventTapCallback: CGEventTapCallBack = { _, type, event, userInfo in
    guard let userInfo else { return Unmanaged.passUnretained(event) }
    let ctrl = Unmanaged<EventTapController>.fromOpaque(userInfo).takeUnretainedValue()
    return ctrl.handleEvent(type: type, event: event)
}
