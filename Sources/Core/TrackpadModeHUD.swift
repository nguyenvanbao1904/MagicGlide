import AppKit
import SwiftUI

/// Floating toast HUD indicating when Virtual Trackpad Mode is toggled ON or OFF.
enum TrackpadModeHUD {
    private static var panel: NSPanel?
    private static var generation = 0

    static func flash(active: Bool) {
        if Thread.isMainThread {
            flashOnMain(active: active)
        } else {
            DispatchQueue.main.async { flashOnMain(active: active) }
        }
    }

    private static func flashOnMain(active: Bool) {
        generation += 1
        let currentGen = generation

        let view = HUDContentView(isActive: active)
        let hostingView = NSHostingView(rootView: view)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor

        let fitting = hostingView.fittingSize
        let size = CGSize(width: max(fitting.width, 220), height: max(fitting.height, 48))
        hostingView.frame = CGRect(origin: .zero, size: size)

        let p = panel ?? makePanel()
        panel = p
        p.contentView = hostingView

        let origin = positionOnScreen(for: size)
        p.setFrame(CGRect(origin: origin, size: size), display: true)

        if !p.isVisible { p.alphaValue = 0 }
        p.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            p.animator().alphaValue = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            guard generation == currentGen, let p = panel else { return }
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.25
                p.animator().alphaValue = 0.0
            }, completionHandler: {
                guard generation == currentGen else { return }
                p.orderOut(nil)
            })
        }
    }

    private static func makePanel() -> NSPanel {
        let p = NSPanel(
            contentRect: .zero,
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        p.isFloatingPanel = true
        p.level = .floating
        p.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = true
        p.ignoresMouseEvents = true
        return p
    }

    private static func positionOnScreen(for size: CGSize) -> CGPoint {
        let mouseLoc = NSEvent.mouseLocation
        let targetScreen = NSScreen.screens.first { NSMouseInRect(mouseLoc, $0.frame, false) } ?? NSScreen.main ?? NSScreen.screens[0]
        let screenFrame = targetScreen.visibleFrame
        let x = screenFrame.origin.x + (screenFrame.width - size.width) / 2.0
        let y = screenFrame.origin.y + screenFrame.height - size.height - 24.0
        return CGPoint(x: x, y: y)
    }

    private struct HUDContentView: View {
        let isActive: Bool

        var body: some View {
            let lang = Preferences.appLanguage
            let title = isActive
                ? (lang == .vi ? "Trackpad ảo: BẬT" : "Virtual Trackpad: ON")
                : (lang == .vi ? "Trackpad ảo: TẮT" : "Virtual Trackpad: OFF")

            HStack(spacing: 10) {
                Image(systemName: isActive ? "hand.draw.fill" : "hand.draw")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isActive ? .green : .secondary)

                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                VisualEffectBlurView()
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
        }
    }

    private struct VisualEffectBlurView: NSViewRepresentable {
        func makeNSView(context: Context) -> NSVisualEffectView {
            let v = NSVisualEffectView()
            v.material = .hudWindow
            v.blendingMode = .withinWindow
            v.state = .active
            return v
        }
        func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
    }
}
