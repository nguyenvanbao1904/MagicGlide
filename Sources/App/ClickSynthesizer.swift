import Cocoa
import ApplicationServices

/// Synthesizes mouse clicks and drag lock events into the macOS event stream.
enum ClickSynthesizer {
    private static let eventSource: CGEventSource? = {
        guard let source = CGEventSource(stateID: .hidSystemState) else { return nil }
        source.localEventsSuppressionInterval = 0
        let permitAllLocalEvents: CGEventFilterMask = [
            .permitLocalMouseEvents,
            .permitLocalKeyboardEvents,
            .permitSystemDefinedEvents
        ]
        source.setLocalEventsFilterDuringSuppressionState(
            permitAllLocalEvents,
            state: .eventSuppressionStateSuppressionInterval
        )
        source.setLocalEventsFilterDuringSuppressionState(
            permitAllLocalEvents,
            state: .eventSuppressionStateRemoteMouseDrag
        )
        return source
    }()

    /// True if the point falls on an active display. Coordinates here are in Quartz global
    /// space (origin top-left), which is what `CGEvent.location` reports.
    static func isOnActiveDisplay(_ location: CGPoint) -> Bool {
        guard location.x.isFinite, location.y.isFinite else { return false }
        var matchingDisplayCount: UInt32 = 0
        guard CGGetDisplaysWithPoint(location, 0, nil, &matchingDisplayCount) == .success else {
            return true
        }
        return matchingDisplayCount > 0
    }

    static func synthesizeClick(at location: CGPoint, isRightClick: Bool) {
        guard isOnActiveDisplay(location) else { return }

        let mouseTypeDown: CGEventType = isRightClick ? .rightMouseDown : .leftMouseDown
        let mouseTypeUp: CGEventType = isRightClick ? .rightMouseUp : .leftMouseUp
        let mouseButton: CGMouseButton = isRightClick ? .right : .left

        if let mouseDown = CGEvent(mouseEventSource: eventSource, mouseType: mouseTypeDown, mouseCursorPosition: location, mouseButton: mouseButton) {
            mouseDown.setIntegerValueField(.mouseEventClickState, value: 1)
            mouseDown.post(tap: .cghidEventTap)
        }
        if let mouseUp = CGEvent(mouseEventSource: eventSource, mouseType: mouseTypeUp, mouseCursorPosition: location, mouseButton: mouseButton) {
            mouseUp.setIntegerValueField(.mouseEventClickState, value: 1)
            mouseUp.post(tap: .cghidEventTap)
        }
    }

    static func synthesizeMiddleClick(at location: CGPoint) {
        let targetLocation: CGPoint
        if location != .zero && isOnActiveDisplay(location) {
            targetLocation = location
        } else if let loc = CGEvent(source: nil)?.location, isOnActiveDisplay(loc) {
            targetLocation = loc
        } else {
            targetLocation = location
        }

        guard isOnActiveDisplay(targetLocation) else { return }

        DispatchQueue.main.async {
            let clickLocation = (CGEvent(source: nil)?.location).flatMap { isOnActiveDisplay($0) ? $0 : nil } ?? targetLocation

            if let mouseDown = CGEvent(
                mouseEventSource: eventSource,
                mouseType: .otherMouseDown,
                mouseCursorPosition: clickLocation,
                mouseButton: .center
            ) {
                mouseDown.setIntegerValueField(.mouseEventButtonNumber, value: 2)
                mouseDown.setIntegerValueField(.mouseEventClickState, value: 1)
                mouseDown.post(tap: .cghidEventTap)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.015) {
                let releaseLocation = (CGEvent(source: nil)?.location).flatMap { isOnActiveDisplay($0) ? $0 : nil } ?? clickLocation

                if let mouseUp = CGEvent(
                    mouseEventSource: eventSource,
                    mouseType: .otherMouseUp,
                    mouseCursorPosition: releaseLocation,
                    mouseButton: .center
                ) {
                    mouseUp.setIntegerValueField(.mouseEventButtonNumber, value: 2)
                    mouseUp.setIntegerValueField(.mouseEventClickState, value: 1)
                    mouseUp.post(tap: .cghidEventTap)
                }
            }
        }
    }

    static func synthesizeDragLock(at location: CGPoint, isLocked: Bool) {
        if isLocked {
            guard isOnActiveDisplay(location) else { return }
        }

        let eventType: CGEventType = isLocked ? .leftMouseDown : .leftMouseUp
        if let event = CGEvent(
            mouseEventSource: eventSource,
            mouseType: eventType,
            mouseCursorPosition: location,
            mouseButton: .left
        ) {
            event.post(tap: .cghidEventTap)
        }
    }
}
