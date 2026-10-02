import Foundation

extension Notification.Name {
    static let preferencesDidChange = Notification.Name("com.magicglide.preferencesDidChange")
}

/// User-adjustable settings, persisted in UserDefaults.
///
/// Note: All Bool properties use `guard UserDefaults.standard.object(forKey:) != nil`
/// before reading. This is intentional: `UserDefaults.bool(forKey:)` silently returns
/// `false` when a key does not exist, making it impossible to distinguish "never set"
/// from "deliberately set to false". The guard lets us return a non-false default safely.
enum Preferences {
    private static var isBroadcasting = false
    static func notifyChange() {
        guard !isBroadcasting else { return }
        isBroadcasting = true
        NotificationCenter.default.post(name: .preferencesDidChange, object: nil)
        isBroadcasting = false
    }

    static let rightClickThresholdKey = "rightClickThreshold"

    /// Fraction of the mouse surface (0-1) to the left of which taps count as a left click.
    /// A tap with normalized x above this value is a right click.
    static let defaultRightClickThreshold: Float = 0.6

    /// Values offered in the menu bar. Anything set outside this list (e.g. via
    /// `defaults write com.magicglide.app rightClickThreshold 0.75`) is still honoured.
    static let rightClickThresholdChoices: [Float] = [0.4, 0.5, 0.6, 0.7, 0.8, 0.9]

    static let minRightClickThreshold: Float = 0.1
    static let maxRightClickThreshold: Float = 0.95

    static var rightClickThreshold: Float {
        get {
            guard UserDefaults.standard.object(forKey: rightClickThresholdKey) != nil else {
                return defaultRightClickThreshold
            }
            return clamp(UserDefaults.standard.float(forKey: rightClickThresholdKey))
        }
        set {
            UserDefaults.standard.set(clamp(newValue), forKey: rightClickThresholdKey)
            notifyChange()
        }
    }

    static let tapSensitivityKey = "tapSensitivity"
    static let minTapYKey = "minTapY"

    enum TapSensitivity: String, CaseIterable {
        case lenient = "lenient"
        case medium = "medium"
        case strict = "strict"

        var title: String {
            switch self {
            case .lenient: return "Lenient (Original - Easiest to trigger)"
            case .medium: return "Medium (Balanced - Recommended)"
            case .strict: return "Strict (Requires crisp tap)"
            }
        }

        var tapTimeThreshold: TimeInterval {
            switch self {
            case .lenient: return 0.25
            case .medium: return 0.22
            case .strict: return 0.18
            }
        }

        var surfaceMovementThreshold: Float {
            switch self {
            case .lenient: return 0.08
            case .medium: return 0.05
            case .strict: return 0.035
            }
        }
    }

    static let defaultTapSensitivity: TapSensitivity = .medium

    static var tapSensitivity: TapSensitivity {
        get {
            guard let raw = UserDefaults.standard.string(forKey: tapSensitivityKey),
                  let sensitivity = TapSensitivity(rawValue: raw) else {
                return defaultTapSensitivity
            }
            return sensitivity
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: tapSensitivityKey)
            notifyChange()
        }
    }

    /// On Magic Mouse, normalized Y = 1.0 is the front edge (fingertips, away from Apple logo)
    /// and Y = 0.0 is the rear edge (palm rest, near Apple logo).
    /// minTapY defines the lower threshold (touches below this Y towards the palm rest are ignored).
    static let defaultMinTapY: Float = 0.40

    struct TapZoneChoice {
        let title: String
        let minTapY: Float
    }

    static let tapZoneChoices: [TapZoneChoice] = [
        TapZoneChoice(title: "Entire Surface (No filter)", minTapY: 0.00),
        TapZoneChoice(title: "Top 75% (Filters palm base)", minTapY: 0.25),
        TapZoneChoice(title: "Top 60% (Fingertips area)", minTapY: 0.40),
        TapZoneChoice(title: "Top 50% (Upper half)", minTapY: 0.50)
    ]

    static var minTapY: Float {
        get {
            guard UserDefaults.standard.object(forKey: minTapYKey) != nil else {
                return defaultMinTapY
            }
            let val = UserDefaults.standard.float(forKey: minTapYKey)
            guard val.isFinite else { return defaultMinTapY }
            return min(max(val, 0.0), 0.8)
        }
        set {
            let clamped = min(max(newValue, 0.0), 0.8)
            UserDefaults.standard.set(clamped, forKey: minTapYKey)
            notifyChange()
        }
    }

    static func clamp(_ value: Float) -> Float {
        guard value.isFinite else { return defaultRightClickThreshold }
        return min(max(value, minRightClickThreshold), maxRightClickThreshold)
    }

    // MARK: - Edge Sliders (Volume & Brightness)

    static let edgeSlidersEnabledKey = "edgeSlidersEnabled"
    static let defaultEdgeSlidersEnabled = true

    static var isEdgeSlidersEnabled: Bool {
        get {
            guard UserDefaults.standard.object(forKey: edgeSlidersEnabledKey) != nil else {
                return defaultEdgeSlidersEnabled
            }
            return UserDefaults.standard.bool(forKey: edgeSlidersEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: edgeSlidersEnabledKey)
            notifyChange()
        }
    }

    static let edgeZoneWidthKey = "edgeZoneWidth"
    static let defaultEdgeZoneWidth: Float = 0.18 // Outer 18% by default (leaves 64% center for normal scrolling)

    struct EdgeZoneChoice {
        let title: String
        let width: Float
    }

    static let edgeZoneChoices: [EdgeZoneChoice] = [
        EdgeZoneChoice(title: "Outer 15% (Ultra-narrow - Maximum scroll space)", width: 0.15),
        EdgeZoneChoice(title: "Outer 18% (Narrow - Recommended, easy scroll)", width: 0.18),
        EdgeZoneChoice(title: "Outer 22% (Balanced)", width: 0.22),
        EdgeZoneChoice(title: "Outer 28% (Wide)", width: 0.28)
    ]

    static var edgeZoneWidth: Float {
        get {
            guard UserDefaults.standard.object(forKey: edgeZoneWidthKey) != nil else {
                return defaultEdgeZoneWidth
            }
            let val = UserDefaults.standard.float(forKey: edgeZoneWidthKey)
            guard val.isFinite else { return defaultEdgeZoneWidth }
            return min(max(val, 0.10), 0.35)
        }
        set {
            let clamped = min(max(newValue, 0.10), 0.35)
            UserDefaults.standard.set(clamped, forKey: edgeZoneWidthKey)
            notifyChange()
        }
    }

    /// Left edge threshold: touches starting with X <= leftEdgeThreshold are brightness slider candidates
    static var leftEdgeThreshold: Float {
        return edgeZoneWidth
    }

    /// Right edge threshold: touches starting with X >= rightEdgeThreshold are volume slider candidates
    static var rightEdgeThreshold: Float {
        return 1.0 - edgeZoneWidth
    }

    /// Vertical distance (normalized Y) required to trigger one notch of volume/brightness (~3.3mm of slide)
    static let edgeSliderStepDistance: Float = 0.030

    /// Minimum vertical slide before edge slider activates (~2.8mm deadzone to distinguish from a tap)
    static let edgeSliderActivationThreshold: Float = 0.025

    // MARK: - Three-Finger Gestures

    static let threeFingerTapEnabledKey = "threeFingerTapEnabled"
    static let defaultThreeFingerTapEnabled = true

    static var isThreeFingerTapEnabled: Bool {
        get {
            guard UserDefaults.standard.object(forKey: threeFingerTapEnabledKey) != nil else {
                return defaultThreeFingerTapEnabled
            }
            return UserDefaults.standard.bool(forKey: threeFingerTapEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: threeFingerTapEnabledKey)
            notifyChange()
        }
    }

    /// Write the three-finger-tap enabled flag to UserDefaults WITHOUT posting a change notification.
    /// Use this when the caller will post a single notification itself (e.g., alongside a gestureConfiguration write).
    static func setThreeFingerTapEnabledSilently(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: threeFingerTapEnabledKey)
    }

    static let threeFingerSwipeEnabledKey = "threeFingerSwipeEnabled"
    static let defaultThreeFingerSwipeEnabled = true

    static var isThreeFingerSwipeEnabled: Bool {
        get {
            guard UserDefaults.standard.object(forKey: threeFingerSwipeEnabledKey) != nil else {
                return defaultThreeFingerSwipeEnabled
            }
            return UserDefaults.standard.bool(forKey: threeFingerSwipeEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: threeFingerSwipeEnabledKey)
            notifyChange()
        }
    }

    /// Write the three-finger-swipe enabled flag to UserDefaults WITHOUT posting a change notification.
    static func setThreeFingerSwipeEnabledSilently(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: threeFingerSwipeEnabledKey)
    }

    static let threeFingerNaturalSwipeKey = "threeFingerNaturalSwipe"
    static let defaultThreeFingerNaturalSwipe = true

    static var isThreeFingerNaturalSwipe: Bool {
        get {
            return gestureConfiguration.isThreeFingerNaturalSwipe
        }
        set {
            var config = gestureConfiguration
            config.isThreeFingerNaturalSwipe = newValue
            gestureConfiguration = config
        }
    }

    // MARK: - Smart Zoom Support

    static let smartZoomEnabledKey = "smartZoomEnabled"
    static let defaultSmartZoomEnabled = true

    static var isSmartZoomEnabled: Bool {
        get {
            guard UserDefaults.standard.object(forKey: smartZoomEnabledKey) != nil else {
                return defaultSmartZoomEnabled
            }
            return UserDefaults.standard.bool(forKey: smartZoomEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: smartZoomEnabledKey)
            notifyChange()
        }
    }

    /// Write the smart-zoom enabled flag to UserDefaults WITHOUT posting a change notification.
    static func setSmartZoomEnabledSilently(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: smartZoomEnabledKey)
    }

    /// Delay in seconds to disambiguate a single tap from a double tap (macOS Smart Zoom).
    /// 200ms allows humans comfortable time to double-tap while remaining responsive for single click.
    static let smartZoomBufferDelay: TimeInterval = 0.20

    // MARK: - Pinch to Zoom
    static let pinchZoomEnabledKey = "pinchZoomEnabled"
    static let defaultPinchZoomEnabled = true

    static var isPinchZoomEnabled: Bool {
        get {
            return gestureConfiguration.pinch != .none
        }
        set {
            var config = gestureConfiguration
            config.pinch = newValue ? .zoom : .none
            gestureConfiguration = config
            UserDefaults.standard.set(newValue, forKey: pinchZoomEnabledKey)
        }
    }

    static func setPinchZoomEnabledSilently(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: pinchZoomEnabledKey)
    }

    // MARK: - Tap to Click
    static let tapToClickEnabledKey = "tapToClickEnabled"
    static let defaultTapToClickEnabled = true

    static var isTapToClickEnabled: Bool {
        get {
            guard UserDefaults.standard.object(forKey: tapToClickEnabledKey) != nil else {
                return defaultTapToClickEnabled
            }
            return UserDefaults.standard.bool(forKey: tapToClickEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: tapToClickEnabledKey)
            notifyChange()
        }
    }

    // MARK: - 2-Finger Move to Zoom (Push/Pull Mouse)
    static let moveZoomEnabledKey = "moveZoomEnabled"
    static let defaultMoveZoomEnabled = true

    static var isMoveZoomEnabled: Bool {
        get {
            return gestureConfiguration.twoFingerMove != .none
        }
        set {
            var config = gestureConfiguration
            config.twoFingerMove = newValue ? .zoom : .none
            gestureConfiguration = config
            UserDefaults.standard.set(newValue, forKey: moveZoomEnabledKey)
        }
    }

    static func setMoveZoomEnabledSilently(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: moveZoomEnabledKey)
    }

    // MARK: - Language
    enum AppLanguage: String, CaseIterable {
        case vi = "vi"
        case en = "en"

        var title: String {
            switch self {
            case .vi: return "Tiếng Việt"
            case .en: return "English"
            }
        }
    }

    static let appLanguageKey = "appLanguage"
    static let defaultAppLanguage: AppLanguage = .vi

    static var appLanguage: AppLanguage {
        get {
            guard let raw = UserDefaults.standard.string(forKey: appLanguageKey),
                  let lang = AppLanguage(rawValue: raw) else {
                return defaultAppLanguage
            }
            return lang
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: appLanguageKey)
            notifyChange()
        }
    }

    // MARK: - Secondary Click Mode

    enum SecondaryClickMode: String, CaseIterable, Identifiable {
        case clickRight = "clickRight"
        case clickLeft = "clickLeft"
        case none = "none"

        var id: String { rawValue }

        func title(l10n: L10n) -> String {
            switch self {
            case .clickRight: return l10n.actionClickRight
            case .clickLeft: return l10n.actionClickLeft
            case .none: return l10n.actionNone
            }
        }
    }

    static let secondaryClickModeKey = "secondaryClickMode"

    static var secondaryClickMode: SecondaryClickMode {
        get {
            guard let raw = UserDefaults.standard.string(forKey: secondaryClickModeKey),
                  let mode = SecondaryClickMode(rawValue: raw) else {
                return .clickRight
            }
            return mode
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: secondaryClickModeKey)
            notifyChange()
        }
    }

    // MARK: - Gesture Configuration

    static let gestureConfigurationKey = "gestureConfiguration"

    private static var _cachedGestureConfiguration: GestureConfiguration?

    static var gestureConfiguration: GestureConfiguration {
        get {
            if let cached = _cachedGestureConfiguration {
                return cached
            }
            var config: GestureConfiguration
            if let data = UserDefaults.standard.data(forKey: gestureConfigurationKey),
               let decoded = try? JSONDecoder().decode(GestureConfiguration.self, from: data) {
                config = decoded
            } else {
                config = GestureConfiguration.migrateFromLegacy()
            }
            config.sanitize()
            _cachedGestureConfiguration = config
            return config
        }
        set {
            _cachedGestureConfiguration = newValue
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: gestureConfigurationKey)
            }
            notifyChange()
        }
    }

    /// Invalidate the in-memory cache if settings were changed externally
    static func invalidateGestureConfigurationCache() {
        _cachedGestureConfiguration = nil
    }
}


