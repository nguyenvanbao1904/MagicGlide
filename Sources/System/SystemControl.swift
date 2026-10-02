import Foundation
import Cocoa
import CoreGraphics
import CoreAudio
import AudioToolbox

// Private DisplayServices framework functions for native brightness control
@_silgen_name("DisplayServicesGetBrightness")
func DisplayServicesGetBrightness(_ display: CGDirectDisplayID, _ brightness: UnsafeMutablePointer<Float>) -> Int32

@_silgen_name("DisplayServicesSetBrightness")
func DisplayServicesSetBrightness(_ display: CGDirectDisplayID, _ brightness: Float) -> Int32

// Private HIServices function to trigger Mission Control and Show Desktop reliably
@_silgen_name("CoreDockSendNotification")
func CoreDockSendNotification(_ notification: CFString)

enum SystemControl {
    // Auxiliary media key constants from <IOKit/hidsystem/ev_keymap.h>
    private static let NX_KEYTYPE_SOUND_UP: Int32 = 0
    private static let NX_KEYTYPE_SOUND_DOWN: Int32 = 1
    private static let NX_KEYTYPE_BRIGHTNESS_UP: Int32 = 2
    private static let NX_KEYTYPE_BRIGHTNESS_DOWN: Int32 = 3

    /// Posts native macOS auxiliary media key events directly into HID event tap.
    /// This causes macOS to automatically adjust volume/brightness, play native sound feedback,
    /// and display the native Apple OSD bezel that seamlessly floats above fullscreen applications.
    static func postAuxMediaKey(_ key: Int32) {
        func post(down: Bool) {
            let state = down ? 0xa00 : 0xb00
            let data1 = Int((key << 16) | Int32(state))
            let flags = NSEvent.ModifierFlags(rawValue: UInt(state))
            if let ev = NSEvent.otherEvent(
                with: .systemDefined,
                location: .zero,
                modifierFlags: flags,
                timestamp: 0,
                windowNumber: 0,
                context: nil,
                subtype: 8, // NX_SUBTYPE_AUX_CONTROL_BUTTONS
                data1: data1,
                data2: -1
            ), let cgEvent = ev.cgEvent {
                cgEvent.post(tap: .cghidEventTap)
            }
        }
        post(down: true)
        post(down: false)
    }

    private static var accumulatedVolumeDelta: Float = 0.0
    private static var accumulatedBrightnessDelta: Float = 0.0

    // MARK: - Native Volume Control with System OSD
    static func adjustVolume(by delta: Float) {
        if abs(delta) >= 0.05 {
            let steps = max(1, Int(round(abs(delta) / 0.0625)))
            let key = delta > 0 ? NX_KEYTYPE_SOUND_UP : NX_KEYTYPE_SOUND_DOWN
            for _ in 0..<steps {
                postAuxMediaKey(key)
            }
        } else {
            accumulatedVolumeDelta += delta
            let notchThreshold: Float = 0.04
            while accumulatedVolumeDelta >= notchThreshold {
                postAuxMediaKey(NX_KEYTYPE_SOUND_UP)
                accumulatedVolumeDelta -= notchThreshold
            }
            while accumulatedVolumeDelta <= -notchThreshold {
                postAuxMediaKey(NX_KEYTYPE_SOUND_DOWN)
                accumulatedVolumeDelta += notchThreshold
            }
        }
    }

    static func volumeUp() {
        postAuxMediaKey(NX_KEYTYPE_SOUND_UP)
    }

    static func volumeDown() {
        postAuxMediaKey(NX_KEYTYPE_SOUND_DOWN)
    }

    // MARK: - Native Brightness Control with System OSD
    static func adjustBrightness(by delta: Float) {
        if abs(delta) >= 0.05 {
            let steps = max(1, Int(round(abs(delta) / 0.0625)))
            let key = delta > 0 ? NX_KEYTYPE_BRIGHTNESS_UP : NX_KEYTYPE_BRIGHTNESS_DOWN
            for _ in 0..<steps {
                postAuxMediaKey(key)
            }
        } else {
            accumulatedBrightnessDelta += delta
            let notchThreshold: Float = 0.04
            while accumulatedBrightnessDelta >= notchThreshold {
                postAuxMediaKey(NX_KEYTYPE_BRIGHTNESS_UP)
                accumulatedBrightnessDelta -= notchThreshold
            }
            while accumulatedBrightnessDelta <= -notchThreshold {
                postAuxMediaKey(NX_KEYTYPE_BRIGHTNESS_DOWN)
                accumulatedBrightnessDelta += notchThreshold
            }
        }
    }

    static func brightnessUp() {
        postAuxMediaKey(NX_KEYTYPE_BRIGHTNESS_UP)
    }

    static func brightnessDown() {
        postAuxMediaKey(NX_KEYTYPE_BRIGHTNESS_DOWN)
    }

    // MARK: - Browser / Editor Tab Switching (Cmd + Shift + [ / ])
    static func switchTab(forward: Bool) {
        // 30 = ']' (Show Next Tab), 33 = '[' (Show Previous Tab) in standard macOS US layout
        let key: CGKeyCode = forward ? 30 : 33
        postSystemKeyChord(
            key: key,
            modifiers: [
                (key: 55, flag: .maskCommand),
                (key: 56, flag: .maskShift)
            ]
        )
    }

    // MARK: - Native Pinch-to-Zoom Magnification
    static func postMagnification(magnification: Double, phase: Int64, location: CGPoint) {
        guard let event = CGEvent(source: nil) else { return }
        event.type = CGEventType(rawValue: 29) ?? .null
        event.location = location
        event.setIntegerValueField(CGEventField(rawValue: 110)!, value: 8) // kIOHIDEventTypeZoom
        event.setIntegerValueField(CGEventField(rawValue: 132)!, value: phase) // Began = 1, Changed = 2, Ended = 4
        event.setDoubleValueField(CGEventField(rawValue: 113)!, value: magnification)
        event.post(tap: .cghidEventTap)
    }

    // MARK: - Mission Control & Exposé State Tracking
    private(set) static var isMissionControlActive: Bool = false
    private(set) static var isAppExposeActive: Bool = false
    private static var lastMissionControlToggleTime: TimeInterval = 0

    // MARK: - Mission Control
    static func missionControl() {
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastMissionControlToggleTime > 0.25 else { return }
        lastMissionControlToggleTime = now

        isMissionControlActive.toggle()
        CoreDockSendNotification("com.apple.expose.awake" as CFString)
    }

    // MARK: - App Exposé (Application Windows: Control + Down Arrow)
    static func appExpose() {
        isAppExposeActive.toggle()
        postSystemKeyChord(
            key: 125, // kVK_DownArrow = 125
            modifiers: [
                (key: 59, flag: .maskControl) // kVK_Control = 59
            ]
        )
    }

    /// Dismisses Mission Control if it is active, returning to normal desktop.
    /// Returns true if Mission Control was dismissed.
    @discardableResult
    static func dismissMissionControlIfActive() -> Bool {
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastMissionControlToggleTime > 0.20 else { return false }

        if isMissionControlActive || isMissionControlShowing {
            lastMissionControlToggleTime = now
            isMissionControlActive = false
            CoreDockSendNotification("com.apple.expose.awake" as CFString)
            return true
        }
        return false
    }

    /// Dismisses App Exposé if it is active, returning to normal desktop.
    /// Returns true if App Exposé was dismissed.
    @discardableResult
    static func dismissAppExposeIfActive() -> Bool {
        if isAppExposeActive {
            isAppExposeActive = false
            postSystemKeyChord(key: 53, modifiers: []) // kVK_Escape = 53
            return true
        }
        return false
    }

    static func markMissionControlInactive() {
        isMissionControlActive = false
        isAppExposeActive = false
    }

    static var isMissionControlShowing: Bool {
        guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return false
        }
        for window in windowList {
            if let ownerName = window[kCGWindowOwnerName as String] as? String, ownerName == "Dock" {
                if let bounds = window[kCGWindowBounds as String] as? [String: Any],
                   let y = bounds["Y"] as? NSNumber, y.intValue == -1 {
                    return true
                }
            }
        }
        return false
    }

    // MARK: - Show Desktop
    static func showDesktop() {
        CoreDockSendNotification("com.apple.showdesktop.awake" as CFString)
    }

    // MARK: - Switch Spaces / Fullscreen Apps (Ctrl + Left / Right Arrow)
    static func switchSpace(forward: Bool) {
        let key: CGKeyCode = forward ? 124 : 123 // 124 = Right Arrow, 123 = Left Arrow
        postSystemKeyChord(
            key: key,
            modifiers: [
                (key: 59, flag: .maskControl)
            ]
        )
    }

    // MARK: - Web / Finder History (Cmd + [ / ])
    static func navigateHistory(forward: Bool) {
        let key: CGKeyCode = forward ? 30 : 33 // 30 = ']' (Forward), 33 = '[' (Back)
        postSystemKeyChord(
            key: key,
            modifiers: [
                (key: 55, flag: .maskCommand)
            ]
        )
    }

    // MARK: - Smart Zoom (Double-tap magnification toggle)
    /// Posts native smart zoom gesture events.
    /// Emits both NSEventTypeSmartMagnify (type 32) and magnification 0.0 toggle,
    /// triggering native Smart Zoom in Safari, Preview, Chrome, Maps, Pages, etc.
    static func smartZoom() {
        guard let location = CGEvent(source: nil)?.location else { return }
        // 1. Post native AppKit Smart Magnify event (NSEventTypeSmartMagnify = 32)
        if let event = CGEvent(source: nil) {
            event.type = CGEventType(rawValue: 32) ?? .null
            event.location = location
            event.post(tap: .cghidEventTap)
        }
        // 2. Also post IOHIDEventTypeZoom with 0.0 magnification toggle (Began=1, Ended=4)
        postMagnification(magnification: 0.0, phase: 1, location: location)
        postMagnification(magnification: 0.0, phase: 4, location: location)
    }

    // MARK: - Key Chord Engine
    static func postSystemKeyChord(key: CGKeyCode, modifiers: [(key: CGKeyCode, flag: CGEventFlags)]) {
        DispatchQueue.global(qos: .userInteractive).async {
            let source = CGEventSource(stateID: .hidSystemState)

            var combinedFlags: CGEventFlags = []
            for m in modifiers {
                combinedFlags.insert(m.flag)
            }

            // 1. Press modifier keys in order (e.g. Control down)
            for m in modifiers {
                if let modDown = CGEvent(keyboardEventSource: source, virtualKey: m.key, keyDown: true) {
                    modDown.flags.insert(combinedFlags)
                    modDown.post(tap: .cghidEventTap)
                }
            }

            usleep(15_000) // 15ms pause to guarantee WindowServer registers modifier state transition

            // 2. Press target key (e.g. Arrow, Bracket)
            if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: true) {
                keyDown.flags.insert(combinedFlags)
                keyDown.post(tap: .cghidEventTap)
            }

            usleep(25_000) // 25ms hold duration

            // 3. Release target key
            if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: false) {
                keyUp.flags.insert(combinedFlags)
                keyUp.post(tap: .cghidEventTap)
            }

            usleep(15_000) // 15ms pause before releasing modifiers

            // 4. Release modifier keys in reverse order
            for m in modifiers.reversed() {
                if let modUp = CGEvent(keyboardEventSource: source, virtualKey: m.key, keyDown: false) {
                    modUp.flags = []
                    modUp.post(tap: .cghidEventTap)
                }
            }
        }
    }
}
