import Foundation
import SwiftUI

extension GestureAction {
    /// Human-readable title for display in Settings UI and menu bar.
    func title(l10n: L10n) -> String {
        switch self {
        case .none:            return l10n.actionNone
        case .middleClick:     return l10n.actionMiddleClick
        case .missionControl:  return l10n.actionMissionControl
        case .appExpose:       return l10n.actionAppExpose
        case .showDesktop:     return l10n.actionShowDesktop
        case .smartZoom:       return l10n.actionSmartZoom
        case .zoom:            return l10n.actionZoom
        case .switchTabs:      return l10n.actionSwitchTabs
        case .switchSpaces:    return l10n.actionSwitchSpaces
        case .navigateHistory: return l10n.actionNavigateHistory
        case .dragLock:        return l10n.actionDragLock
        case .nextTab:         return l10n.actionSwitchNextTab
        case .volume:          return l10n.actionVolume
        case .brightness:      return l10n.actionBrightness
        case .toggleTrackpadMode: return l10n.actionToggleTrackpadMode
        }
    }

    /// SF Symbol name for Settings UI icons.
    var iconName: String {
        switch self {
        case .none:            return "slash.circle"
        case .middleClick:     return "computermouse"
        case .missionControl:  return "rectangle.3.group"
        case .appExpose:       return "rectangle.topthird.inset.filled"
        case .showDesktop:     return "menubar.rectangle"
        case .smartZoom:       return "text.magnifyingglass"
        case .zoom:            return "arrow.up.left.and.arrow.down.right"
        case .switchTabs:      return "rectangle.2.swap"
        case .switchSpaces:    return "macwindow.on.rectangle"
        case .navigateHistory: return "arrow.uturn.backward"
        case .dragLock:        return "lock.open"
        case .nextTab:         return "chevron.right.to.line"
        case .volume:          return "speaker.wave.2"
        case .brightness:      return "sun.max"
        case .toggleTrackpadMode: return "hand.draw"
        }
    }

    /// Color for edge slider icon overlay in Settings and Canvas.
    var edgeIconColor: Color {
        switch self {
        case .volume:     return .blue
        case .brightness: return .orange
        case .zoom:       return .green
        default:          return .secondary
        }
    }
}
