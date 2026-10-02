import Foundation
import SwiftUI

enum AppleGestureDemo: String, CaseIterable {
    // Point & Click Tab
    case tapToClick
    case secondaryClick
    case tapSensitivity
    case palmRejection

    // Edge Sliders Tab
    case leftEdgeSlider
    case rightEdgeSlider
    case edgeWidth

    // More Gestures Tab
    case threeFingerTap
    case threeFingerSwipe
    case twoFingerTap
    case twoFingerSwipe
    case twoFingerClick
    case smartZoom
    case pinchZoom
    case moveZoom
    case virtualTrackpad
}

final class SettingsViewModel: ObservableObject {
    @Published var appLanguage: Preferences.AppLanguage = Preferences.appLanguage {
        didSet { Preferences.appLanguage = appLanguage }
    }

    var l10n: L10n { L10n(lang: appLanguage) }

    @Published var isTapToClickEnabled: Bool = Preferences.isTapToClickEnabled {
        didSet { Preferences.isTapToClickEnabled = isTapToClickEnabled }
    }
    @Published var rightClickThreshold: Float = Preferences.rightClickThreshold {
        didSet { Preferences.rightClickThreshold = rightClickThreshold }
    }
    @Published var secondaryClickMode: Preferences.SecondaryClickMode = Preferences.secondaryClickMode {
        didSet { Preferences.secondaryClickMode = secondaryClickMode }
    }
    @Published var tapSensitivity: Preferences.TapSensitivity = Preferences.tapSensitivity {
        didSet { Preferences.tapSensitivity = tapSensitivity }
    }
    @Published var minTapY: Float = Preferences.minTapY {
        didSet { Preferences.minTapY = minTapY }
    }

    @Published var isEdgeSlidersEnabled: Bool = Preferences.isEdgeSlidersEnabled {
        didSet { Preferences.isEdgeSlidersEnabled = isEdgeSlidersEnabled }
    }
    @Published var edgeZoneWidth: Float = Preferences.edgeZoneWidth {
        didSet { Preferences.edgeZoneWidth = edgeZoneWidth }
    }

    @Published var gestureConfiguration: GestureConfiguration = Preferences.gestureConfiguration {
        didSet { Preferences.gestureConfiguration = gestureConfiguration }
    }

    @Published var isMoveZoomEnabled: Bool = Preferences.isMoveZoomEnabled {
        didSet { Preferences.isMoveZoomEnabled = isMoveZoomEnabled }
    }
    @Published var isPinchZoomEnabled: Bool = Preferences.isPinchZoomEnabled {
        didSet { Preferences.isPinchZoomEnabled = isPinchZoomEnabled }
    }
    @Published var isSmartZoomEnabled: Bool = Preferences.isSmartZoomEnabled {
        didSet { Preferences.isSmartZoomEnabled = isSmartZoomEnabled }
    }
    @Published var isThreeFingerTapEnabled: Bool = Preferences.isThreeFingerTapEnabled {
        didSet { Preferences.isThreeFingerTapEnabled = isThreeFingerTapEnabled }
    }
    @Published var isThreeFingerSwipeEnabled: Bool = Preferences.isThreeFingerSwipeEnabled {
        didSet { Preferences.isThreeFingerSwipeEnabled = isThreeFingerSwipeEnabled }
    }
    @Published var isVirtualTrackpadMode: Bool = TrackpadModeController.shared.isActive {
        didSet {
            if isVirtualTrackpadMode != TrackpadModeController.shared.isActive {
                if isVirtualTrackpadMode {
                    TrackpadModeController.shared.activate()
                } else {
                    TrackpadModeController.shared.deactivate()
                }
            }
        }
    }

    @Published var selectedTab: Int = 0 {
        didSet {
            switch selectedTab {
            case 0: currentDemo = .tapToClick
            case 1: currentDemo = .leftEdgeSlider
            case 2: currentDemo = .threeFingerTap
            default: break
            }
        }
    }

    @Published var currentDemo: AppleGestureDemo = .tapToClick
    @Published var hoveredDemo: AppleGestureDemo? = nil

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePreferencesDidChange),
            name: .preferencesDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTrackpadModeDidChange),
            name: .trackpadModeDidChange,
            object: nil
        )
    }

    @objc private func handleTrackpadModeDidChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.isVirtualTrackpadMode != TrackpadModeController.shared.isActive {
                self.isVirtualTrackpadMode = TrackpadModeController.shared.isActive
            }
        }
    }

    @objc private func handlePreferencesDidChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.isTapToClickEnabled != Preferences.isTapToClickEnabled {
                self.isTapToClickEnabled = Preferences.isTapToClickEnabled
            }
            if self.rightClickThreshold != Preferences.rightClickThreshold {
                self.rightClickThreshold = Preferences.rightClickThreshold
            }
            if self.secondaryClickMode != Preferences.secondaryClickMode {
                self.secondaryClickMode = Preferences.secondaryClickMode
            }
            if self.tapSensitivity != Preferences.tapSensitivity {
                self.tapSensitivity = Preferences.tapSensitivity
            }
            if self.minTapY != Preferences.minTapY {
                self.minTapY = Preferences.minTapY
            }
            if self.isEdgeSlidersEnabled != Preferences.isEdgeSlidersEnabled {
                self.isEdgeSlidersEnabled = Preferences.isEdgeSlidersEnabled
            }
            if self.edgeZoneWidth != Preferences.edgeZoneWidth {
                self.edgeZoneWidth = Preferences.edgeZoneWidth
            }
            if self.gestureConfiguration != Preferences.gestureConfiguration {
                self.gestureConfiguration = Preferences.gestureConfiguration
            }
            if self.isMoveZoomEnabled != Preferences.isMoveZoomEnabled {
                self.isMoveZoomEnabled = Preferences.isMoveZoomEnabled
            }
            if self.isPinchZoomEnabled != Preferences.isPinchZoomEnabled {
                self.isPinchZoomEnabled = Preferences.isPinchZoomEnabled
            }
            if self.isSmartZoomEnabled != Preferences.isSmartZoomEnabled {
                self.isSmartZoomEnabled = Preferences.isSmartZoomEnabled
            }
            if self.isThreeFingerTapEnabled != Preferences.isThreeFingerTapEnabled {
                self.isThreeFingerTapEnabled = Preferences.isThreeFingerTapEnabled
            }
            if self.isThreeFingerSwipeEnabled != Preferences.isThreeFingerSwipeEnabled {
                self.isThreeFingerSwipeEnabled = Preferences.isThreeFingerSwipeEnabled
            }
            if self.appLanguage != Preferences.appLanguage {
                self.appLanguage = Preferences.appLanguage
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
