import Foundation

extension GestureAction {
    /// Returns the ordered list of actions valid for a given gesture slot.
    /// UI uses this to populate Pickers — domain decides what's compatible,
    /// not the UI layer.
    static func compatible(with slot: GestureSlot) -> [GestureAction] {
        switch slot {
        case .twoFingerTap:
            return [.none, .middleClick, .toggleTrackpadMode, .dragLock, .missionControl, .appExpose, .showDesktop, .smartZoom]

        case .threeFingerTap:
            return [.none, .middleClick, .toggleTrackpadMode, .missionControl, .appExpose, .showDesktop, .dragLock, .nextTab]

        case .threeFingerSwipe:
            // Directional gesture — only actions with forward/backward semantics
            return [.none, .switchTabs, .switchSpaces, .navigateHistory]

        case .doubleTap:
            return [.none, .smartZoom, .missionControl, .appExpose, .showDesktop, .toggleTrackpadMode]

        case .leftEdge, .rightEdge:
            // Continuous delta gesture — actions with delta semantics
            return [.none, .volume, .brightness, .zoom]

        case .twoFingerMove:
            // Continuous 2-finger movement — delta semantics (zoom, volume, brightness)
            return [.none, .zoom, .volume, .brightness]

        case .pinch:
            // Continuous 2-finger pinch — zoom
            return [.none, .zoom]

        case .twoFingerSwipeUp:
            return [.none, .missionControl, .appExpose, .showDesktop, .smartZoom, .middleClick, .dragLock, .nextTab, .toggleTrackpadMode]

        case .twoFingerSwipeDown:
            return [.none, .appExpose, .showDesktop, .missionControl, .smartZoom, .middleClick, .dragLock, .nextTab, .toggleTrackpadMode]

        case .twoFingerClick:
            return [.none, .middleClick, .toggleTrackpadMode, .missionControl, .appExpose, .showDesktop, .smartZoom, .dragLock, .nextTab]
        }
    }

    /// Validates whether this action can be legitimately bound to a given slot.
    func isCompatible(with slot: GestureSlot) -> Bool {
        GestureAction.compatible(with: slot).contains(self)
    }
}
