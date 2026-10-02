import Foundation
import CoreGraphics

/// Translates a GestureAction intent into macOS system calls.
/// This is the ONLY place that knows HOW to perform each action.
///
/// Injected into GestureDispatcher; no singleton. Use `onDragLockToggle` to avoid
/// a circular dependency back to GestureEngine.
final class ActionExecutor {
    /// Called when the .dragLock action fires. Wired by AppDelegate to GestureEngine.toggleDragLock().
    var onDragLockToggle: (() -> Void)?
    /// Called when .toggleTrackpadMode fires. Wired by AppDelegate.
    var onToggleTrackpadMode: (() -> Void)?

    init() {}

    // MARK: - Primary API (typed GestureEvent)

    /// Execute an action using a fully-typed GestureEvent as context.
    func execute(_ action: GestureAction, event: GestureEvent) {
        switch action {
        case .none:
            break
        case .middleClick:
            ClickSynthesizer.synthesizeMiddleClick(at: event.cursorLocation)
        case .missionControl:
            SystemControl.missionControl()
        case .appExpose:
            SystemControl.appExpose()
        case .showDesktop:
            SystemControl.showDesktop()
        case .smartZoom:
            SystemControl.smartZoom()
        case .zoom:
            if case .magnification(let mag, let phase, let loc) = event {
                SystemControl.postMagnification(magnification: mag, phase: phase, location: loc)
            }
        case .switchTabs:
            if case .threeFingerSwipe(let dir, _) = event {
                SystemControl.switchTab(forward: dir == .forward)
            }
        case .switchSpaces:
            if case .threeFingerSwipe(let dir, _) = event {
                SystemControl.switchSpace(forward: dir == .forward)
            }
        case .navigateHistory:
            if case .threeFingerSwipe(let dir, _) = event {
                SystemControl.navigateHistory(forward: dir == .forward)
            }
        case .nextTab:
            SystemControl.switchTab(forward: true)
        case .dragLock:
            onDragLockToggle?()
        case .volume:
            if case .edgeSlide(_, let delta, _) = event {
                SystemControl.adjustVolume(by: delta)
            }
        case .brightness:
            if case .edgeSlide(_, let delta, _) = event {
                SystemControl.adjustBrightness(by: delta)
            }
        case .toggleTrackpadMode:
            onToggleTrackpadMode?()
        }
    }

    // MARK: - Compatibility shim (old ActionContext API)
    // Kept so MenuBuilder / AppDelegate toggle handlers that haven't been migrated yet
    // still compile. Remove once all callers switch to execute(_:event:).

    static let shared = ActionExecutor._sharedInstance
    private static let _sharedInstance: ActionExecutor = {
        let e = ActionExecutor()
        e.onDragLockToggle = { GestureEngine.current?.toggleDragLock() }
        e.onToggleTrackpadMode = { TrackpadModeController.shared.toggle() }
        return e
    }()

    func execute(_ action: GestureAction, context: ActionContext = ActionContext()) {
        switch action {
        case .none: break
        case .middleClick:
            ClickSynthesizer.synthesizeMiddleClick(at: context.cursorLocation)
        case .missionControl: SystemControl.missionControl()
        case .appExpose:      SystemControl.appExpose()
        case .showDesktop:    SystemControl.showDesktop()
        case .smartZoom:      SystemControl.smartZoom()
        case .zoom:
            SystemControl.postMagnification(
                magnification: Double(context.delta ?? 0),
                phase: context.phase ?? 2,
                location: context.cursorLocation)
        case .switchTabs:
            SystemControl.switchTab(forward: context.direction == .forward)
        case .switchSpaces:
            SystemControl.switchSpace(forward: context.direction == .forward)
        case .navigateHistory:
            SystemControl.navigateHistory(forward: context.direction == .forward)
        case .nextTab:
            SystemControl.switchTab(forward: true)
        case .dragLock:
            onDragLockToggle?()
        case .volume:
            SystemControl.adjustVolume(by: context.delta ?? 0)
        case .brightness:
            SystemControl.adjustBrightness(by: context.delta ?? 0)
        case .toggleTrackpadMode:
            onToggleTrackpadMode?()
        }
    }
}

// MARK: - GestureEvent helpers

private extension GestureEvent {
    var cursorLocation: CGPoint {
        switch self {
        case .tap(let loc, _),
             .doubleTap(let loc),
             .twoFingerTap(let loc),
             .threeFingerTap(let loc),
             .physicalTwoFingerClick(let loc),
             .physicalThreeFingerClick(let loc),
             .twoFingerSwipeUp(let loc),
             .twoFingerSwipeDown(let loc),
             .threeFingerSwipe(_, let loc),
             .magnification(_, _, let loc),
             .edgeSlide(_, _, let loc),
             .dragLockToggle(let loc):
            return loc
        }
    }
}
