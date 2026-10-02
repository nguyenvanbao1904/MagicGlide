import Foundation
import CoreGraphics
import AppKit

/// Manages MTDevice lifecycle and forwards raw touch frames up to GestureEngine.
/// Owns the private MultitouchSupport devices; does NOT interpret touches.
final class MultitouchSource {
    /// Called on every touch frame with (touches, numTouches, timestamp).
    /// Assigned by AppDelegate to `engine.processTouches`.
    var onTouches: ((_ touches: UnsafeMutablePointer<MTTouch>, _ count: Int, _ timestamp: Double) -> Void)?

    /// Fires when the set of connected external devices changes so the UI can refresh.
    var onDeviceSetChanged: (() -> Void)?

    private var devices: [MTDeviceRef] = []
    private var deviceCheckTimer: DispatchSourceTimer?

    // Shared pointer used by the C-level callback to route frames here.
    static weak var current: MultitouchSource?

    init() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleSystemWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleSystemWake),
            name: NSWorkspace.screensDidWakeNotification,
            object: nil
        )
    }

    var hasConnectedDevice: Bool { !devices.isEmpty }

    // MARK: - Lifecycle

    func start() {
        MultitouchSource.current = self

        guard let deviceList = MTDeviceCreateList() else {
            startDeviceCheckTimer()
            return
        }
        let arr = deviceList.takeRetainedValue() as NSArray
        for i in 0..<CFArrayGetCount(arr) {
            let device = unsafeBitCast(CFArrayGetValueAtIndex(arr, i), to: MTDeviceRef.self)
            guard !MTDeviceIsBuiltIn(device) else { continue }
            devices.append(device)
            MTRegisterContactFrameCallback(device, multitouchSourceCallback)
            MTDeviceStart(device, 0)
        }
        startDeviceCheckTimer()
    }

    func stop() {
        stopDeviceCheckTimer()
        for device in devices {
            MTUnregisterContactFrameCallback(device, multitouchSourceCallback)
            MTDeviceStop(device)
        }
        devices.removeAll()
        if MultitouchSource.current === self { MultitouchSource.current = nil }
    }

    func restart() { stop(); start() }

    // MARK: - Device polling

    func checkDevices() {
        guard let deviceList = MTDeviceCreateList() else {
            if !devices.isEmpty { restart() }
            return
        }
        let arr = deviceList.takeRetainedValue() as NSArray
        var externalCount = 0
        for i in 0..<CFArrayGetCount(arr) {
            let device = unsafeBitCast(CFArrayGetValueAtIndex(arr, i), to: MTDeviceRef.self)
            if !MTDeviceIsBuiltIn(device) { externalCount += 1 }
        }
        if externalCount != devices.count {
            restart()
            DispatchQueue.main.async { [weak self] in
                self?.onDeviceSetChanged?()
            }
        }
    }

    private func startDeviceCheckTimer() {
        stopDeviceCheckTimer()
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + 2.5, repeating: 2.5)
        timer.setEventHandler { [weak self] in self?.checkDevices() }
        timer.resume()
        deviceCheckTimer = timer
    }

    private func stopDeviceCheckTimer() {
        deviceCheckTimer?.cancel()
        deviceCheckTimer = nil
    }

    @objc private func handleSystemWake() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.restart()
        }
    }

    deinit {
        stop()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
}

// C-level callback — must be at file scope
private func multitouchSourceCallback(
    device: Int32,
    touches: UnsafeMutablePointer<MTTouch>?,
    numTouches: Int32,
    timestamp: Double,
    frame: Int32
) -> Int32 {
    guard let source = MultitouchSource.current, let touches else { return 0 }
    source.onTouches?(touches, Int(numTouches), timestamp)
    return 0
}
