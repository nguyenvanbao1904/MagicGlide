import Foundation

/// Represents user's intent — what they want the gesture to do.
/// Decoupled from HOW macOS performs it (ActionExecutor) and
/// from WHICH gesture triggers it (GestureSlot).
enum GestureAction: String, CaseIterable, Codable, Identifiable {
    case none             = "none"
    case middleClick      = "middleClick"
    case missionControl   = "missionControl"
    case appExpose        = "appExpose"
    case showDesktop      = "showDesktop"
    case smartZoom        = "smartZoom"
    /// Continuous smooth magnification zoom (pinch or push/pull)
    case zoom             = "zoom"
    /// Directional tab switching (advances or reverses based on swipe direction)
    case switchTabs       = "switchTabs"
    case switchSpaces     = "switchSpaces"
    case navigateHistory  = "navigateHistory"
    case dragLock         = "dragLock"
    case nextTab          = "nextTab"
    case volume           = "volume"
    case brightness       = "brightness"
    case toggleTrackpadMode = "toggleTrackpadMode"

    var id: String { rawValue }
}
