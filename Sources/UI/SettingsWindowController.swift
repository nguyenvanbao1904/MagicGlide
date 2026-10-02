import Cocoa
import SwiftUI

final class SettingsWindowController: NSWindowController {
    static let shared = SettingsWindowController()

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 630),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "MagicGlide Settings"
        window.titlebarAppearsTransparent = true
        window.toolbarStyle = .unified
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false

        let vm = SettingsViewModel()
        let hosting = NSHostingController(rootView: SettingsPreferencesView(vm: vm))
        window.contentViewController = hosting

        self.init(window: window)
    }

    func show() {
        guard let window = self.window else { return }
        MouseDeviceInfo.shared.refresh()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
