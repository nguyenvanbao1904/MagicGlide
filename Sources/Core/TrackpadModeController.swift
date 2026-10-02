import Foundation
import CoreGraphics
import AppKit

/// Controls Virtual Trackpad Mode: turns the Magic Mouse surface into a stationary trackpad.
/// When active, finger stroke on the surface moves the cursor, tap clicks, and 2 fingers scroll.
final class TrackpadModeController: ObservableObject {
    static let shared = TrackpadModeController()

    @Published private(set) var isActive = false

    private var trackedTouchID: Int32?
    private var lastTouchPos: CGPoint = .zero
    private var touchStartPos: CGPoint = .zero
    private var touchStartTime: TimeInterval = 0
    private var touchPathLength: CGFloat = 0
    private var touchFrameCount: Int = 0

    private var lock = os_unfair_lock()

    private init() {}

    func toggle() {
        if Thread.isMainThread {
            if isActive { deactivate() } else { activate() }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.toggle()
            }
        }
    }

    func activate() {
        os_unfair_lock_lock(&lock)
        guard !isActive else {
            os_unfair_lock_unlock(&lock)
            return
        }
        isActive = true
        resetTracking()
        os_unfair_lock_unlock(&lock)

        TrackpadModeHUD.flash(active: true)
        NotificationCenter.default.post(name: .trackpadModeDidChange, object: nil)
    }

    func deactivate() {
        os_unfair_lock_lock(&lock)
        guard isActive else {
            os_unfair_lock_unlock(&lock)
            return
        }
        isActive = false
        resetTracking()
        os_unfair_lock_unlock(&lock)

        TrackpadModeHUD.flash(active: false)
        NotificationCenter.default.post(name: .trackpadModeDidChange, object: nil)
    }

    private func resetTracking() {
        trackedTouchID = nil
        lastTouchPos = .zero
        touchStartPos = .zero
        touchStartTime = 0
        touchPathLength = 0
        touchFrameCount = 0
    }

    /// Processes touch frames when Virtual Trackpad Mode is active.
    /// Returns true if the touch was consumed by Virtual Trackpad Mode.
    func handleTouches(_ touches: [SurfaceTouch], timestamp: TimeInterval) -> Bool {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }

        guard isActive else { return false }

        // 1. All fingers lifted
        if touches.isEmpty {
            if let _ = trackedTouchID {
                let duration = timestamp - touchStartTime
                let straightDist = hypot(lastTouchPos.x - touchStartPos.x, lastTouchPos.y - touchStartPos.y)

                // Tap detection for left click
                if duration <= 0.22 && straightDist <= 0.04 && touchPathLength <= 0.06 && touchFrameCount >= 2 {
                    let loc = CGEvent(source: nil)?.location ?? .zero
                    ClickSynthesizer.synthesizeClick(at: loc, isRightClick: false)
                }
            }
            resetTracking()
            return true
        }

        // 2. Exactly 1 finger: Cursor movement
        if touches.count == 1 {
            let touch = touches[0]

            if trackedTouchID == touch.identifier {
                touchFrameCount += 1
                let dx = touch.position.x - lastTouchPos.x
                let dy = touch.position.y - lastTouchPos.y
                let stepDist = hypot(dx, dy)
                touchPathLength += stepDist

                lastTouchPos = touch.position

                // Move cursor
                // Note: normalized coordinates: x is 0..1 (left to right), y is 0..1 (bottom to top)
                let currentCursor = CGEvent(source: nil)?.location ?? .zero
                let sensitivityFactor: CGFloat = 1600.0

                let deltaScreenX = dx * sensitivityFactor
                let deltaScreenY = -dy * sensitivityFactor // Invert Y: sliding finger down (decreasing Y) moves cursor down (+Y)

                let targetX = currentCursor.x + deltaScreenX
                let targetY = currentCursor.y + deltaScreenY

                let newPos = CGPoint(x: targetX, y: targetY)
                CGWarpMouseCursorPosition(newPos)
            } else {
                // New touch tracking began
                trackedTouchID = touch.identifier
                lastTouchPos = touch.position
                touchStartPos = touch.position
                touchStartTime = timestamp
                touchPathLength = 0
                touchFrameCount = 1
            }
            return true
        }

        // 3. Exactly 2 fingers: Two-finger scroll is handled natively by macOS driver
        // via EventTapController passthrough. We consume the touch frame here so 2-finger gestures don't conflict.
        if touches.count == 2 {
            trackedTouchID = nil
            touchFrameCount = 0
            touchPathLength = 0
            return true
        }

        // 4. 3 or more fingers: allow gestures like 3-finger swipe (Mission Control, Tab Switching)
        // or 3-finger tap / physical click
        return false
    }
}

extension Notification.Name {
    static let trackpadModeDidChange = Notification.Name("trackpadModeDidChange")
}
