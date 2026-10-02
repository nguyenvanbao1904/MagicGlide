import Cocoa
import SwiftUI
import ImageIO
import UniformTypeIdentifiers

@main
struct GifGenerator {
    struct DemoItem {
        let filename: String
        let title: String
        let demo: AppleGestureDemo
        let configModifier: (inout GestureConfiguration) -> Void
    }

    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)

        print("🎨 Starting programmatic GIF generation from MagicMouseCanvasView...")

        // Stop the internal real-time timer so we can step frame-by-frame deterministically
        CanvasAnimationClock.shared.stopTimer()

        let outputDir = URL(fileURLWithPath: "assets", isDirectory: true)
        try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        var defaultCfg = GestureConfiguration()

        let demos: [DemoItem] = [
            DemoItem(
                filename: "demo_tap_click.gif",
                title: "Tap-to-Click",
                demo: .tapToClick,
                configModifier: { _ in }
            ),
            DemoItem(
                filename: "demo_secondary_click.gif",
                title: "Secondary (Right) Click Zone",
                demo: .secondaryClick,
                configModifier: { _ in }
            ),
            DemoItem(
                filename: "demo_edge_volume.gif",
                title: "Edge Slider: Volume Control",
                demo: .rightEdgeSlider,
                configModifier: { $0.rightEdge = .volume }
            ),
            DemoItem(
                filename: "demo_edge_brightness.gif",
                title: "Edge Slider: Brightness Control",
                demo: .leftEdgeSlider,
                configModifier: { $0.leftEdge = .brightness }
            ),
            DemoItem(
                filename: "demo_virtual_trackpad.gif",
                title: "Virtual Trackpad Mode",
                demo: .virtualTrackpad,
                configModifier: { _ in }
            ),
            DemoItem(
                filename: "demo_mission_control.gif",
                title: "Mission Control & Dismissal",
                demo: .twoFingerSwipe,
                configModifier: { $0.twoFingerSwipeUp = .missionControl }
            ),
            DemoItem(
                filename: "demo_tab_switch.gif",
                title: "Continuous 3-Finger Tab Scrubbing",
                demo: .threeFingerSwipe,
                configModifier: { $0.threeFingerSwipe = .switchTabs }
            ),
            DemoItem(
                filename: "demo_pinch_zoom.gif",
                title: "Pinch-to-Zoom",
                demo: .pinchZoom,
                configModifier: { $0.pinch = .zoom }
            ),
            DemoItem(
                filename: "demo_middle_click.gif",
                title: "2-Finger Physical Click (Middle Click)",
                demo: .twoFingerClick,
                configModifier: { $0.twoFingerClick = .middleClick }
            )
        ]

        let cardWidth: CGFloat = 540
        let cardHeight: CGFloat = 206
        let totalFrames = 26
        let frameDelay = 0.08 // ~12.5 FPS, smooth 2.1s loop

        for item in demos {
            print("⏳ Generating '\(item.title)' -> \(item.filename)...")

            var cfg = defaultCfg
            item.configModifier(&cfg)

            let view = MagicMouseCanvasView(
                deviceInfo: MouseDeviceInfo.shared,
                currentDemo: item.demo,
                rightClickThreshold: 0.60,
                edgeZoneWidth: 0.12,
                minTapY: 0.25,
                l10n: L10n(lang: .en),
                gestureConfiguration: cfg
            )
            .padding(8)
            .background(Color(NSColor.windowBackgroundColor))
            .preferredColorScheme(.dark) // Sleek dark theme that pops in GitHub light/dark mode

            let hostingView = NSHostingView(rootView: view)
            hostingView.frame = CGRect(x: 0, y: 0, width: cardWidth, height: cardHeight)

            let window = NSWindow(
                contentRect: CGRect(x: 0, y: 0, width: cardWidth, height: cardHeight),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            window.isOpaque = true
            window.backgroundColor = .windowBackgroundColor
            window.contentView = hostingView
            window.layoutIfNeeded()
            hostingView.layoutSubtreeIfNeeded()

            var capturedFrames: [CGImage] = []

            for f in 0..<totalFrames {
                let progress = Double(f) / Double(totalFrames)
                CanvasAnimationClock.shared.setProgress(progress)

                // Spin runloop briefly to allow SwiftUI layout and state refresh
                RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.005))
                hostingView.layoutSubtreeIfNeeded()

                if let bitmapRep = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) {
                    hostingView.cacheDisplay(in: hostingView.bounds, to: bitmapRep)
                    if let cgImg = bitmapRep.cgImage {
                        capturedFrames.append(cgImg)
                    }
                }
            }

            guard !capturedFrames.isEmpty else {
                print("❌ Error: No frames captured for \(item.filename)")
                continue
            }

            let fileURL = outputDir.appendingPathComponent(item.filename)
            guard let destination = CGImageDestinationCreateWithURL(
                fileURL as CFURL,
                UTType.gif.identifier as CFString,
                capturedFrames.count,
                nil
            ) else {
                print("❌ Error: Could not create CGImageDestination for \(fileURL.path)")
                continue
            }

            let gifProperties: [String: Any] = [
                kCGImagePropertyGIFDictionary as String: [
                    kCGImagePropertyGIFLoopCount as String: 0 // 0 = loop infinitely
                ]
            ]
            CGImageDestinationSetProperties(destination, gifProperties as CFDictionary)

            let frameProperties: [String: Any] = [
                kCGImagePropertyGIFDictionary as String: [
                    kCGImagePropertyGIFDelayTime as String: frameDelay
                ]
            ]

            for frame in capturedFrames {
                CGImageDestinationAddImage(destination, frame, frameProperties as CFDictionary)
            }

            if CGImageDestinationFinalize(destination) {
                let fileSize = (try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int64) ?? 0
                let kb = Double(fileSize) / 1024.0
                print("✅ Saved \(item.filename) (\(capturedFrames.count) frames, \(String(format: "%.1f", kb)) KB)")
            } else {
                print("❌ Error: Finalizing GIF failed for \(item.filename)")
            }
        }

        print("🎉 All demo GIFs generated successfully!")
    }
}
