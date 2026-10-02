import Foundation

/// Stores the user's binding of each GestureSlot to a GestureAction.
/// Type-safe, Codable, compiler-enforced — no missing slots possible.
struct GestureConfiguration: Codable, Equatable {
    static let `default` = GestureConfiguration()

    // MARK: - Bindings
    var twoFingerTap:     GestureAction = .none
    var threeFingerTap:   GestureAction = .none
    var threeFingerSwipe: GestureAction = .switchTabs
    var doubleTap:        GestureAction = .smartZoom
    var leftEdge:         GestureAction = .brightness
    var rightEdge:        GestureAction = .volume
    var twoFingerMove:      GestureAction = .none
    var pinch:              GestureAction = .zoom
    var twoFingerSwipeUp:   GestureAction = .missionControl
    var twoFingerSwipeDown: GestureAction = .appExpose
    var twoFingerClick:     GestureAction = .middleClick

    // MARK: - Per-gesture settings
    var isThreeFingerNaturalSwipe: Bool = true

    // MARK: - Subscript by slot
    subscript(slot: GestureSlot) -> GestureAction {
        get {
            switch slot {
            case .twoFingerTap:       return twoFingerTap
            case .threeFingerTap:     return threeFingerTap
            case .threeFingerSwipe:   return threeFingerSwipe
            case .doubleTap:          return doubleTap
            case .leftEdge:           return leftEdge
            case .rightEdge:          return rightEdge
            case .twoFingerMove:      return twoFingerMove
            case .pinch:              return pinch
            case .twoFingerSwipeUp:   return twoFingerSwipeUp
            case .twoFingerSwipeDown: return twoFingerSwipeDown
            case .twoFingerClick:     return twoFingerClick
            }
        }
        set {
            guard newValue.isCompatible(with: slot) else {
                NSLog("[GestureConfiguration] Rejected incompatible action '%@' for slot '%@'", newValue.rawValue, slot.rawValue)
                return
            }
            switch slot {
            case .twoFingerTap:       twoFingerTap = newValue
            case .threeFingerTap:     threeFingerTap = newValue
            case .threeFingerSwipe:   threeFingerSwipe = newValue
            case .doubleTap:          doubleTap = newValue
            case .leftEdge:           leftEdge = newValue
            case .rightEdge:          rightEdge = newValue
            case .twoFingerMove:      twoFingerMove = newValue
            case .pinch:              pinch = newValue
            case .twoFingerSwipeUp:   twoFingerSwipeUp = newValue
            case .twoFingerSwipeDown: twoFingerSwipeDown = newValue
            case .twoFingerClick:     twoFingerClick = newValue
            }
        }
    }

    // MARK: - Validation & Sanitization
    mutating func sanitize() {
        if !twoFingerTap.isCompatible(with: .twoFingerTap) { twoFingerTap = GestureConfiguration.default.twoFingerTap }
        if !threeFingerTap.isCompatible(with: .threeFingerTap) { threeFingerTap = GestureConfiguration.default.threeFingerTap }
        if !threeFingerSwipe.isCompatible(with: .threeFingerSwipe) { threeFingerSwipe = GestureConfiguration.default.threeFingerSwipe }
        if !doubleTap.isCompatible(with: .doubleTap) { doubleTap = GestureConfiguration.default.doubleTap }
        if !leftEdge.isCompatible(with: .leftEdge) { leftEdge = GestureConfiguration.default.leftEdge }
        if !rightEdge.isCompatible(with: .rightEdge) { rightEdge = GestureConfiguration.default.rightEdge }
        if !twoFingerMove.isCompatible(with: .twoFingerMove) { twoFingerMove = GestureConfiguration.default.twoFingerMove }
        if !pinch.isCompatible(with: .pinch) { pinch = GestureConfiguration.default.pinch }
        if !twoFingerSwipeUp.isCompatible(with: .twoFingerSwipeUp) { twoFingerSwipeUp = GestureConfiguration.default.twoFingerSwipeUp }
        if !twoFingerSwipeDown.isCompatible(with: .twoFingerSwipeDown) { twoFingerSwipeDown = GestureConfiguration.default.twoFingerSwipeDown }
        if !twoFingerClick.isCompatible(with: .twoFingerClick) { twoFingerClick = GestureConfiguration.default.twoFingerClick }
    }

    // MARK: - Migration from legacy UserDefaults keys
    static func migrateFromLegacy() -> GestureConfiguration {
        var config = GestureConfiguration()
        let ud = UserDefaults.standard
        let migrations: [(key: String, apply: (inout GestureConfiguration, GestureAction) -> Void)] = [
            ("threeFingerTapAction",       { $0.threeFingerTap = $1 }),
            ("threeFingerSwipeAction",     { $0.threeFingerSwipe = $1 }),
            ("twoFingerTapAction",         { $0.twoFingerTap = $1 }),
            ("doubleTapAction",            { $0.doubleTap = $1 }),
            ("leftEdgeAction",             { $0.leftEdge = $1 }),
            ("rightEdgeAction",            { $0.rightEdge = $1 }),
            ("twoFingerMoveAction",        { $0.twoFingerMove = $1 }),
            ("pinchAction",                { $0.pinch = $1 }),
            ("twoFingerSwipeUpAction",     { $0.twoFingerSwipeUp = $1 }),
            ("twoFingerSwipeDownAction",   { $0.twoFingerSwipeDown = $1 }),
            ("twoFingerClickAction",       { $0.twoFingerClick = $1 }),
        ]
        for (key, apply) in migrations {
            if let raw = ud.string(forKey: key), let action = GestureAction(rawValue: raw) {
                apply(&config, action)
            }
        }
        if ud.object(forKey: "threeFingerNaturalSwipe") != nil {
            config.isThreeFingerNaturalSwipe = ud.bool(forKey: "threeFingerNaturalSwipe")
        }
        if ud.object(forKey: "moveZoomEnabled") != nil && !ud.bool(forKey: "moveZoomEnabled") {
            config.twoFingerMove = .none
        }
        if ud.object(forKey: "pinchZoomEnabled") != nil && !ud.bool(forKey: "pinchZoomEnabled") {
            config.pinch = .none
        }
        return config
    }
}
