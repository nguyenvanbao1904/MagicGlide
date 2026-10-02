import Foundation

/// Read/write access to all user-adjustable settings.
/// Abstracting this allows detectors and engine components to receive settings via
/// injection rather than reaching for the global Preferences enum directly.
protocol PreferenceStore: AnyObject {
    // MARK: - Tap
    var isTapToClickEnabled: Bool { get set }
    var rightClickThreshold: Float { get set }
    var secondaryClickMode: Preferences.SecondaryClickMode { get set }
    var minTapY: Float { get set }
    var tapSensitivity: Preferences.TapSensitivity { get set }

    // MARK: - Gesture configuration
    var gestureConfiguration: GestureConfiguration { get set }

    // MARK: - Edge sliders
    var isEdgeSlidersEnabled: Bool { get set }
    var leftEdgeThreshold: Float { get }
    var rightEdgeThreshold: Float { get }
    var edgeSliderStepDistance: Float { get }
    var edgeSliderActivationThreshold: Float { get }

    // MARK: - Smart zoom
    var smartZoomBufferDelay: TimeInterval { get }

    // MARK: - Three-finger
    var isThreeFingerTapEnabled: Bool { get set }
    var isThreeFingerSwipeEnabled: Bool { get set }
}

/// Production implementation backed by UserDefaults via the existing Preferences enum.
final class UserDefaultsPreferenceStore: PreferenceStore {
    static let shared = UserDefaultsPreferenceStore()
    private init() {}

    var isTapToClickEnabled: Bool {
        get { Preferences.isTapToClickEnabled }
        set { Preferences.isTapToClickEnabled = newValue }
    }
    var rightClickThreshold: Float {
        get { Preferences.rightClickThreshold }
        set { Preferences.rightClickThreshold = newValue }
    }
    var secondaryClickMode: Preferences.SecondaryClickMode {
        get { Preferences.secondaryClickMode }
        set { Preferences.secondaryClickMode = newValue }
    }
    var minTapY: Float {
        get { Preferences.minTapY }
        set { Preferences.minTapY = newValue }
    }
    var tapSensitivity: Preferences.TapSensitivity {
        get { Preferences.tapSensitivity }
        set { Preferences.tapSensitivity = newValue }
    }
    var gestureConfiguration: GestureConfiguration {
        get { Preferences.gestureConfiguration }
        set { Preferences.gestureConfiguration = newValue }
    }
    var isEdgeSlidersEnabled: Bool {
        get { Preferences.isEdgeSlidersEnabled }
        set { Preferences.isEdgeSlidersEnabled = newValue }
    }
    var leftEdgeThreshold: Float { Preferences.leftEdgeThreshold }
    var rightEdgeThreshold: Float { Preferences.rightEdgeThreshold }
    var edgeSliderStepDistance: Float { Preferences.edgeSliderStepDistance }
    var edgeSliderActivationThreshold: Float { Preferences.edgeSliderActivationThreshold }
    var smartZoomBufferDelay: TimeInterval { Preferences.smartZoomBufferDelay }
    var isThreeFingerTapEnabled: Bool {
        get { Preferences.isThreeFingerTapEnabled }
        set { Preferences.isThreeFingerTapEnabled = newValue }
    }
    var isThreeFingerSwipeEnabled: Bool {
        get { Preferences.isThreeFingerSwipeEnabled }
        set { Preferences.isThreeFingerSwipeEnabled = newValue }
    }
}
