import Cocoa

/// Floating on-screen display (OSD) overlay window that mimics native macOS volume/brightness bezels.
final class HUDOverlay {
    static let shared = HUDOverlay()

    private var window: NSPanel?
    private var progressView: NSView?
    private var progressFillLayer: CALayer?
    private var iconView: NSImageView?
    private var titleLabel: NSTextField?
    private var percentLabel: NSTextField?
    private var hideTimer: Timer?

    private init() {
        // Defer window creation until called on the main thread
    }

    private func ensureWindow() {
        guard window == nil else { return }

        let width: CGFloat = 220
        let height: CGFloat = 52

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = NSWindow.Level(Int(CGWindowLevelForKey(.maximumWindow)))
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = true

        let visualEffect = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        visualEffect.material = .hudWindow
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 18
        visualEffect.layer?.masksToBounds = true
        visualEffect.layer?.borderWidth = 0.5
        visualEffect.layer?.borderColor = NSColor.white.withAlphaComponent(0.2).cgColor

        // Icon (Left)
        let icon = NSImageView(frame: NSRect(x: 14, y: 14, width: 24, height: 24))
        icon.imageScaling = .scaleProportionallyUpOrDown
        icon.contentTintColor = .labelColor
        visualEffect.addSubview(icon)
        self.iconView = icon

        // Title (Device / Feature name)
        let title = NSTextField(frame: NSRect(x: 46, y: 26, width: 120, height: 16))
        title.isBezeled = false
        title.drawsBackground = false
        title.isEditable = false
        title.isSelectable = false
        title.font = NSFont.systemFont(ofSize: 11, weight: .semibold)
        title.textColor = .secondaryLabelColor
        title.cell?.lineBreakMode = .byTruncatingTail
        visualEffect.addSubview(title)
        self.titleLabel = title

        // Percentage text (Right)
        let percent = NSTextField(frame: NSRect(x: 165, y: 26, width: 45, height: 16))
        percent.isBezeled = false
        percent.drawsBackground = false
        percent.isEditable = false
        percent.isSelectable = false
        percent.alignment = .right
        percent.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        percent.textColor = .secondaryLabelColor
        visualEffect.addSubview(percent)
        self.percentLabel = percent

        // Progress track (Bottom)
        let trackX: CGFloat = 46
        let trackY: CGFloat = 14
        let trackWidth: CGFloat = 160
        let trackHeight: CGFloat = 6

        let trackView = NSView(frame: NSRect(x: trackX, y: trackY, width: trackWidth, height: trackHeight))
        trackView.wantsLayer = true
        trackView.layer?.cornerRadius = trackHeight / 2
        trackView.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.18).cgColor

        let fillLayer = CALayer()
        fillLayer.frame = NSRect(x: 0, y: 0, width: 0, height: trackHeight)
        fillLayer.cornerRadius = trackHeight / 2
        fillLayer.backgroundColor = NSColor.controlAccentColor.cgColor
        trackView.layer?.addSublayer(fillLayer)

        visualEffect.addSubview(trackView)
        self.progressView = trackView
        self.progressFillLayer = fillLayer

        panel.contentView = visualEffect
        self.window = panel
    }

    /// Displays the HUD in the top right corner of the active/main screen. Thread-safe.
    func show(iconName: String, title: String, value: Float) {
        if Thread.isMainThread {
            self.displayHUD(iconName: iconName, title: title, value: value)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.displayHUD(iconName: iconName, title: title, value: value)
            }
        }
    }

    private func displayHUD(iconName: String, title: String, value: Float) {
        ensureWindow()
        guard let window = self.window else { return }

        let clampedValue = max(0.0, min(1.0, value))
        let percentInt = Int(round(clampedValue * 100))

        // Update UI
        if let image = NSImage(systemSymbolName: iconName, accessibilityDescription: title) {
            self.iconView?.image = image
        }
        self.titleLabel?.stringValue = title
        self.percentLabel?.stringValue = "\(percentInt)%"

        // Update progress bar
        let trackWidth: CGFloat = 160
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.progressFillLayer?.frame.size.width = trackWidth * CGFloat(clampedValue)
        CATransaction.commit()

        // Position at top-right corner of screen (just below menu bar, with margin)
        let screen = NSScreen.main ?? NSScreen.screens.first
        if let screen = screen {
            let screenRect = screen.visibleFrame
            let x = screenRect.maxX - window.frame.width - 24
            let y = screenRect.maxY - window.frame.height - 12
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        // Cancel any pending fade out
        self.hideTimer?.invalidate()

        // Show and animate in
        if !window.isVisible || window.alphaValue < 0.95 {
            window.alphaValue = 1.0
            window.orderFrontRegardless()
        }

        // Schedule auto-hide after 1.3 seconds
        self.hideTimer = Timer.scheduledTimer(withTimeInterval: 1.3, repeats: false) { [weak self] _ in
            self?.fadeOut()
        }
    }

    private func fadeOut() {
        guard let window = window, window.isVisible else { return }
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.25
            window.animator().alphaValue = 0.0
        }, completionHandler: { [weak self] in
            guard let window = self?.window else { return }
            if window.alphaValue < 0.05 {
                window.orderOut(nil)
            }
        })
    }
}
