import SwiftUI

final class CanvasAnimationClock: ObservableObject {
    static let shared = CanvasAnimationClock()
    @Published var animTick: Int = 0
    @Published var animProgress: Double = 0.0
    private var timer: Timer?

    init() {
        let fps: Double = 60.0
        let cycleDuration: Double = 2.4 // 2.4s per full smooth gesture cycle
        let step = (1.0 / fps) / cycleDuration

        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / fps, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            var next = self.animProgress + step
            if next >= 1.0 { next -= 1.0 }
            self.animProgress = next
            self.animTick = Int(next * 30.0) % 30
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func setProgress(_ progress: Double) {
        self.animProgress = progress
        self.animTick = Int(progress * 30.0) % 30
    }

    deinit {
        timer?.invalidate()
    }
}

struct MagicMouseCanvasView: View {
    @ObservedObject var deviceInfo: MouseDeviceInfo
    var currentDemo: AppleGestureDemo
    var rightClickThreshold: Float
    var edgeZoneWidth: Float
    var minTapY: Float
    var l10n: L10n
    var gestureConfiguration: GestureConfiguration = GestureConfiguration()

    @ObservedObject var animClock = CanvasAnimationClock.shared
    private var animTick: Int { animClock.animTick }
    private var animProgress: Double { animClock.animProgress }

    private let mouseWidth: CGFloat = 88
    private let mouseHeight: CGFloat = 168
    private let cornerRadius: CGFloat = 36

    // Smooth 60 FPS continuous 0.0 -> 1.0 -> 0.0 sine wave
    private var smoothSine: CGFloat {
        CGFloat((sin(animProgress * 2.0 * .pi - .pi / 2.0) + 1.0) / 2.0)
    }

    var body: some View {
        HStack(spacing: 16) {
            // CARD 1: Magic Mouse with Contextual Animated Gestures
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(NSColor.controlBackgroundColor).opacity(0.85))

                ZStack {
                    // Outer mouse chassis & surface
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            deviceInfo.color == .black ? Color.white.opacity(0.35) : Color.black.opacity(0.15),
                            lineWidth: 1.5
                        )
                        .frame(width: mouseWidth, height: mouseHeight)
                        .background(
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .fill(deviceInfo.color == .black ? Color(white: 0.12) : Color(white: 0.96))
                        )
                        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)

                    // Apple Logo
                    Image(systemName: "apple.logo")
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(deviceInfo.color == .black ? Color.white.opacity(0.28) : Color.black.opacity(0.22))
                        .offset(y: mouseHeight * 0.28)

                    // Active Gesture Touch Dots
                    mouseGestureOverlay
                }
                // For Move-to-Zoom: physical mouse body moves forward and backward!
                .offset(y: currentDemo == .moveZoom ? (smoothSine - 0.5) * 22 : 0)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 190)
            .clipped()

            // CARD 2: Realistic Desktop Action Demonstration
            ZStack {
                // Midnight Blue Desktop Background
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.14, green: 0.22, blue: 0.40),
                                Color(red: 0.08, green: 0.13, blue: 0.25)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Mini macOS Dock at bottom
                VStack {
                    Spacer()
                    HStack(spacing: 4) {
                        ForEach([Color.red, Color.yellow, Color.green, Color.orange, Color.blue, Color.purple], id: \.self) { color in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(color.opacity(0.85))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(.bottom, 6)
                }

                // Dynamic Action Demonstration
                desktopDemonstrationContent
            }
            .frame(maxWidth: .infinity)
            .frame(height: 190)
            .clipped()
        }
    }

    // MARK: - Card 1: Contextual Gesture Dots & Overlays

    @ViewBuilder
    private var mouseGestureOverlay: some View {
        switch currentDemo {
        case .tapToClick, .tapSensitivity:
            // Single tap pulse
            let isTapping = (animTick >= 3 && animTick <= 6) || (animTick >= 17 && animTick <= 20)
            Circle()
                .fill(Color.accentColor)
                .frame(width: 14, height: 14)
                .scaleEffect(isTapping ? 0.75 : 1.05)
                .shadow(color: Color.accentColor.opacity(0.6), radius: isTapping ? 6 : 2)
                .offset(y: -mouseHeight * 0.22)

        case .secondaryClick:
            // High-contrast, clearly visible dividing line
            ZStack {
                let splitOffset = (CGFloat(rightClickThreshold) - 0.5) * mouseWidth

                // High-visibility accent colored dividing line
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: 2.0, height: mouseHeight * 0.42)
                    .shadow(color: Color.accentColor.opacity(0.5), radius: 3)
                    .offset(x: splitOffset, y: -mouseHeight * 0.27)

                // Right click tap dot: safely positioned in right zone
                let dotX = min(max(splitOffset + 14, 10), mouseWidth * 0.36)
                let isRightTapping = animTick >= 4 && animTick <= 7

                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 14, height: 14)
                    .scaleEffect(isRightTapping ? 0.75 : 1.05)
                    .shadow(color: Color.accentColor.opacity(0.6), radius: 4)
                    .offset(x: dotX, y: -mouseHeight * 0.22)
            }

        case .palmRejection:
            // Palm rejection: Bottom shaded area + tap on top
            ZStack {
                let palmCutoffY = (1.0 - CGFloat(minTapY)) * mouseHeight
                VStack(spacing: 0) {
                    Spacer().frame(height: palmCutoffY)
                    Rectangle()
                        .fill(Color.purple.opacity(0.25))
                        .overlay(
                            Text("Palm Rest")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.purple)
                                .padding(.top, 8)
                            , alignment: .top
                        )
                }
                .frame(width: mouseWidth, height: mouseHeight)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 14, height: 14)
                    .offset(y: -mouseHeight * 0.26)
            }

        case .leftEdgeSlider:
            let isOff = gestureConfiguration.leftEdge == .none
            let color = gestureConfiguration.leftEdge.edgeIconColor
            ZStack {
                HStack {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color.opacity(isOff ? 0.2 : 0.5))
                        .frame(width: max(8, mouseWidth * CGFloat(edgeZoneWidth)), height: mouseHeight * 0.65)
                    Spacer()
                }
                .padding(.leading, 4)

                if !isOff {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 12, height: 12)
                        .shadow(color: Color.accentColor.opacity(0.6), radius: 4)
                        .offset(x: -mouseWidth * 0.38, y: 20 - 45 * smoothSine)
                }
            }

        case .rightEdgeSlider:
            let isOff = gestureConfiguration.rightEdge == .none
            let color = gestureConfiguration.rightEdge.edgeIconColor
            ZStack {
                HStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color.opacity(isOff ? 0.2 : 0.5))
                        .frame(width: max(8, mouseWidth * CGFloat(edgeZoneWidth)), height: mouseHeight * 0.65)
                }
                .padding(.trailing, 4)

                if !isOff {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 12, height: 12)
                        .shadow(color: Color.accentColor.opacity(0.6), radius: 4)
                        .offset(x: mouseWidth * 0.38, y: 20 - 45 * smoothSine)
                }
            }

        case .edgeWidth:
            ZStack {
                HStack {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.orange.opacity(0.5))
                        .frame(width: max(8, mouseWidth * CGFloat(edgeZoneWidth)), height: mouseHeight * 0.65)
                    Spacer()
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.blue.opacity(0.5))
                        .frame(width: max(8, mouseWidth * CGFloat(edgeZoneWidth)), height: mouseHeight * 0.65)
                }
                .padding(.horizontal, 4)
            }

        case .moveZoom:
            // 2 fingers resting stationary on surface while mouse moves
            HStack(spacing: 12) {
                Circle().fill(Color.accentColor).frame(width: 13, height: 13)
                Circle().fill(Color.accentColor).frame(width: 13, height: 13)
            }
            .shadow(color: Color.accentColor.opacity(0.5), radius: 4)
            .offset(y: -mouseHeight * 0.20)

        case .pinchZoom:
            // 2 fingers spreading apart and pinching back together
            HStack(spacing: 10 + 16 * smoothSine) {
                Circle().fill(Color.accentColor).frame(width: 13, height: 13)
                Circle().fill(Color.accentColor).frame(width: 13, height: 13)
            }
            .shadow(color: Color.accentColor.opacity(0.5), radius: 4)
            .offset(y: -mouseHeight * 0.20)

        case .smartZoom:
            // Double-tap pulse at tick 2, 4 and tick 16, 18
            let isTapDown = (animTick == 2 || animTick == 4 || animTick == 16 || animTick == 18)
            ZStack {
                Circle()
                    .stroke(Color.accentColor.opacity(isTapDown ? 0.6 : 0.0), lineWidth: 2)
                    .frame(width: 22, height: 22)

                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 14, height: 14)
                    .scaleEffect(isTapDown ? 0.70 : 1.05)
                    .shadow(color: Color.accentColor.opacity(0.6), radius: 4)
            }
            .offset(y: -mouseHeight * 0.22)

        case .threeFingerTap:
            // 3 fingers tapping simultaneously
            let isTapping = animTick >= 3 && animTick <= 6
            HStack(spacing: 8) {
                Circle().fill(Color.accentColor).frame(width: 12, height: 12)
                Circle().fill(Color.accentColor).frame(width: 12, height: 12)
                Circle().fill(Color.accentColor).frame(width: 12, height: 12)
            }
            .scaleEffect(isTapping ? 0.78 : 1.05)
            .shadow(color: Color.accentColor.opacity(0.5), radius: 4)
            .offset(y: -mouseHeight * 0.22)

        case .threeFingerSwipe:
            // 3 fingers smoothly gliding horizontally across the surface
            let swipeProgress = CGFloat(animProgress)
            let swipeX = -24.0 + 48.0 * swipeProgress
            HStack(spacing: 8) {
                Circle().fill(Color.accentColor).frame(width: 12, height: 12)
                Circle().fill(Color.accentColor).frame(width: 12, height: 12)
                Circle().fill(Color.accentColor).frame(width: 12, height: 12)
            }
            .shadow(color: Color.accentColor.opacity(0.5), radius: 4)
            .offset(x: swipeX, y: -mouseHeight * 0.20)

        case .twoFingerTap:
            let isTapping = (animTick >= 4 && animTick <= 7) || (animTick >= 18 && animTick <= 21)
            HStack(spacing: 12) {
                Circle().fill(Color.accentColor).frame(width: 13, height: 13)
                Circle().fill(Color.accentColor).frame(width: 13, height: 13)
            }
            .scaleEffect(isTapping ? 0.78 : 1.05)
            .shadow(color: Color.accentColor.opacity(0.5), radius: 4)
            .offset(y: -mouseHeight * 0.22)

        case .twoFingerSwipe:
            // 2 fingers gliding vertically up and down (Mission Control / Dismissal)
            let swipeY = -mouseHeight * 0.12 - 34.0 * smoothSine
            HStack(spacing: 14) {
                Circle().fill(Color.accentColor).frame(width: 13, height: 13)
                Circle().fill(Color.accentColor).frame(width: 13, height: 13)
            }
            .shadow(color: Color.accentColor.opacity(0.6), radius: 5)
            .offset(y: swipeY)

        case .twoFingerClick:
            // 2 fingers resting on surface, followed by mechanical click depression
            let isClickDown = (animTick >= 4 && animTick <= 8) || (animTick >= 18 && animTick <= 22)
            ZStack {
                if isClickDown {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.accentColor.opacity(0.6), lineWidth: 1.5)
                        .frame(width: 48, height: 26)
                        .scaleEffect(1.2)
                }
                HStack(spacing: 14) {
                    Circle().fill(Color.accentColor).frame(width: 13, height: 13)
                    Circle().fill(Color.accentColor).frame(width: 13, height: 13)
                }
                .scaleEffect(isClickDown ? 0.78 : 1.05)
                .shadow(color: Color.accentColor.opacity(0.6), radius: isClickDown ? 6 : 2)
            }
            .offset(y: -mouseHeight * 0.22)

        case .virtualTrackpad:
            let dragX = -12.0 + 24.0 * sin(animProgress * 2.0 * .pi)
            let dragY = -mouseHeight * 0.22 + 12.0 * cos(animProgress * 2.0 * .pi)
            Circle()
                .fill(Color.accentColor)
                .frame(width: 14, height: 14)
                .shadow(color: Color.accentColor.opacity(0.6), radius: 5)
                .offset(x: CGFloat(dragX), y: CGFloat(dragY))
        }
    }

    // MARK: - Card 2: Realistic Desktop Action Demonstration

    @ViewBuilder
    private var desktopDemonstrationContent: some View {
        switch currentDemo {
        case .tapToClick, .tapSensitivity:
            // Button Click with depression
            let isClicked = (animTick >= 3 && animTick <= 6) || (animTick >= 17 && animTick <= 20)
            VStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 220, height: 110)
                    .overlay(
                        VStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Circle().fill(Color.red.opacity(0.6)).frame(width: 6, height: 6)
                                Circle().fill(Color.yellow.opacity(0.6)).frame(width: 6, height: 6)
                                Circle().fill(Color.green.opacity(0.6)).frame(width: 6, height: 6)
                                Spacer()
                            }
                            .padding(.horizontal, 8)
                            .padding(.top, 6)

                            Spacer()

                            HStack(spacing: 6) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(isClicked ? Color.accentColor.opacity(0.8) : Color.accentColor)
                                    .frame(width: 80, height: 26)
                                    .overlay(
                                        Text(l10n.submitBtn)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(.white)
                                    )
                                    .scaleEffect(isClicked ? 0.92 : 1.0)

                                Image(systemName: "hand.point.up.left.fill")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white)
                                    .offset(y: isClicked ? -1 : 2)
                            }

                            Spacer()
                        }
                    )
            }

        case .secondaryClick:
            // Context menu pops up at tick 5 and stays open until tick 25!
            let isMenuOpen = animTick >= 5 && animTick < 25
            VStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Image(systemName: "scissors").frame(width: 14)
                        Text(l10n.cut).font(.system(size: 11))
                    }
                    HStack {
                        Image(systemName: "doc.on.doc").frame(width: 14)
                        Text(l10n.copy).font(.system(size: 11, weight: .semibold))
                    }
                    HStack {
                        Image(systemName: "doc.on.clipboard").frame(width: 14)
                        Text(l10n.paste).font(.system(size: 11))
                    }
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(NSColor.windowBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .shadow(color: Color.black.opacity(0.3), radius: 10, y: 5)
                .scaleEffect(isMenuOpen ? 1.0 : 0.85)
                .opacity(isMenuOpen ? 1.0 : 0.2)
            }

        case .palmRejection:
            VStack(spacing: 8) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.purple)

                Text(l10n.palmRejectionTitle)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)

                Text(l10n.palmRejectionDesc)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
            }

        case .leftEdgeSlider:
            continuousActionDemoView(for: gestureConfiguration.leftEdge)

        case .rightEdgeSlider:
            continuousActionDemoView(for: gestureConfiguration.rightEdge)

        case .edgeWidth:
            edgeWidthDemoView

        case .moveZoom:
            continuousActionDemoView(for: gestureConfiguration.twoFingerMove)

        case .pinchZoom:
            continuousActionDemoView(for: gestureConfiguration.pinch)

        case .smartZoom:
            actionDemoView(for: gestureConfiguration.doubleTap)

        case .threeFingerTap:
            actionDemoView(for: gestureConfiguration.threeFingerTap)

        case .threeFingerSwipe:
            actionDemoView(for: gestureConfiguration.threeFingerSwipe)

        case .twoFingerTap:
            actionDemoView(for: gestureConfiguration.twoFingerTap)

        case .twoFingerSwipe:
            actionDemoView(for: gestureConfiguration.twoFingerSwipeUp)

        case .twoFingerClick:
            actionDemoView(for: gestureConfiguration.twoFingerClick)

        case .virtualTrackpad:
            trackpadModeDemoView
        }
    }

    // MARK: - Action Demo Dispatchers

    @ViewBuilder
    private func actionDemoView(for action: GestureAction) -> some View {
        switch action {
        case .middleClick:         middleClickDemoView
        case .missionControl:      missionControlDemoView
        case .showDesktop:         showDesktopDemoView
        case .smartZoom:           smartZoomDemoView
        case .dragLock:            dragLockDemoView(isLocked: animTick >= 5 && animTick < 22)
        case .nextTab:             nextTabDemoView
        case .switchTabs:          tabSwitchDemoView
        case .switchSpaces:        spacesDemoView
        case .navigateHistory:     historyDemoView
        case .toggleTrackpadMode:  trackpadModeDemoView
        case .none:                disabledGestureView
        default:                   disabledGestureView
        }
    }

    @ViewBuilder
    private func continuousActionDemoView(for action: GestureAction) -> some View {
        switch action {
        case .volume:      volumeDemoView(pct: Int(35 + 55 * smoothSine))
        case .brightness:  brightnessDemoView(pct: Int(30 + 55 * smoothSine))
        case .zoom:        zoomDemoView(pct: Int(100 + 55 * smoothSine))
        default:           disabledGestureView
        }
    }

    private func zoomDemoView(pct: Int) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass")
                Text("\(pct)% Zoom")
            }
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .foregroundColor(.white)

            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.12))
                .frame(width: 190, height: 95)
                .overlay(
                    Image(systemName: "photo.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.accentColor)
                        .scaleEffect(1.0 + 0.55 * smoothSine)
                )
                .clipped()
        }
    }

    // MARK: - Action Demo Helper Views

    private func volumeDemoView(pct: Int) -> some View {
        VStack(spacing: 10) {
            Text(l10n.soundVolume)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.blue)

            HStack(spacing: 10) {
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.2))
                        Capsule()
                            .fill(Color.blue)
                            .frame(width: geo.size.width * CGFloat(pct) / 100.0)
                    }
                }
                .frame(height: 6)

                Text("\(pct)%")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.55))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .frame(width: 220)
        }
    }

    private func brightnessDemoView(pct: Int) -> some View {
        VStack(spacing: 10) {
            Text(l10n.displayBrightness)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.orange)

            HStack(spacing: 10) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.orange)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.2))
                        Capsule()
                            .fill(Color.orange)
                            .frame(width: geo.size.width * CGFloat(pct) / 100.0)
                    }
                }
                .frame(height: 6)

                Text("\(pct)%")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.55))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .frame(width: 220)
        }
    }

    private var edgeWidthDemoView: some View {
        let pct = Int(edgeZoneWidth * 100)
        let centerPct = 100 - (pct * 2)
        return VStack(spacing: 8) {
            Text(l10n.edgeWidthTitle)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)

            HStack(spacing: 2) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.orange.opacity(0.7))
                    .frame(width: CGFloat(pct) * 0.9, height: 45)
                    .overlay(Text("\(pct)%").font(.system(size: 9, weight: .bold)).foregroundColor(.white))

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.15))
                    .frame(width: CGFloat(centerPct) * 0.9, height: 45)
                    .overlay(Text("Scroll (\(centerPct)%)").font(.system(size: 9)).foregroundColor(.white))

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.blue.opacity(0.7))
                    .frame(width: CGFloat(pct) * 0.9, height: 45)
                    .overlay(Text("\(pct)%").font(.system(size: 9, weight: .bold)).foregroundColor(.white))
            }

            Text("Left: \(gestureConfiguration.leftEdge.title(l10n: l10n)) • Right: \(gestureConfiguration.rightEdge.title(l10n: l10n))")
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.7))
        }
    }

    private var disabledGestureView: some View {
        VStack(spacing: 8) {
            Image(systemName: "slash.circle")
                .font(.system(size: 28))
                .foregroundColor(.secondary)

            Text(l10n.actionNone)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)

            Text(l10n.gestureDisabledDesc)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
    }

    private var smartZoomDemoView: some View {
        let isZoomedIn = animTick >= 5 && animTick < 17
        return VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "text.magnifyingglass")
                Text(isZoomedIn ? "160% Smart Zoom" : "100% Fit")
            }
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .foregroundColor(.white)

            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.12))
                .frame(width: 190, height: 95)
                .overlay(
                    VStack(spacing: 4) {
                        Text("Apple Magic Mouse")
                            .font(.system(size: 12, weight: .bold))
                        Text("Double-tap to smart zoom")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .scaleEffect(isZoomedIn ? 1.6 : 1.0)
                )
                .clipped()
        }
    }

    private var middleClickDemoView: some View {
        let isNewTabOpen = animTick >= 5 && animTick < 25
        return VStack(spacing: 10) {
            Text(l10n.middleClickTitle)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)

            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 70, height: 24)
                    .overlay(Text("Article").font(.system(size: 9)).foregroundColor(.white))

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.accentColor)
                    .frame(width: 95, height: 24)
                    .overlay(
                        HStack(spacing: 2) {
                            Image(systemName: "plus.circle.fill").font(.system(size: 8))
                            Text("New Tab").font(.system(size: 9, weight: .semibold))
                        }
                        .foregroundColor(.white)
                    )
                    .scaleEffect(isNewTabOpen ? 1.0 : 0.8)
                    .opacity(isNewTabOpen ? 1.0 : 0.2)
            }
        }
    }

    private var missionControlDemoView: some View {
        let isOpen = smoothSine > 0.35
        return VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "macwindow.on.rectangle")
                Text(isOpen ? l10n.actionMissionControl : (l10n.lang == .vi ? "Màn hình chính" : "Desktop"))
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.white)

            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.blue.opacity(0.6))
                    .frame(width: 58, height: 42)
                    .scaleEffect(isOpen ? 1.0 : 0.6)
                    .offset(x: isOpen ? 0 : -20, y: isOpen ? 0 : 20)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.purple.opacity(0.6))
                    .frame(width: 64, height: 46)
                    .scaleEffect(isOpen ? 1.0 : 0.7)
                    .offset(y: isOpen ? 0 : 20)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.orange.opacity(0.6))
                    .frame(width: 58, height: 42)
                    .scaleEffect(isOpen ? 1.0 : 0.6)
                    .offset(x: isOpen ? 0 : 20, y: isOpen ? 0 : 20)
            }
            .animation(.easeInOut(duration: 0.3), value: isOpen)
        }
    }

    private var showDesktopDemoView: some View {
        let isDesktopShown = animTick >= 5 && animTick < 25
        return VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "menubar.dock.rectangle")
                Text(l10n.actionShowDesktop)
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.white)

            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 200, height: 75)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.accentColor.opacity(0.7))
                    .frame(width: 80, height: 50)
                    .offset(x: isDesktopShown ? -90 : 0, y: isDesktopShown ? -30 : 0)
                    .opacity(isDesktopShown ? 0.3 : 1.0)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.orange.opacity(0.7))
                    .frame(width: 75, height: 45)
                    .offset(x: isDesktopShown ? 90 : 20, y: isDesktopShown ? 30 : 10)
                    .opacity(isDesktopShown ? 0.3 : 1.0)
            }
        }
    }

    private func dragLockDemoView(isLocked: Bool) -> some View {
        VStack(spacing: 8) {
            Image(systemName: isLocked ? "lock.fill" : "lock.open.fill")
                .font(.system(size: 32))
                .foregroundColor(isLocked ? .accentColor : .secondary)
            Text(isLocked ? l10n.actionDragLock : l10n.twoFingerTapTitle)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
        }
    }

    private var nextTabDemoView: some View {
        let activeTab = (animTick / 10) % 2
        return VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.right.to.line")
                Text(l10n.actionSwitchNextTab)
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.white)

            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(activeTab == 0 ? Color.accentColor : Color.white.opacity(0.15))
                    .frame(width: 80, height: 24)
                    .overlay(Text("Tab 1").font(.system(size: 9)).foregroundColor(.white))

                RoundedRectangle(cornerRadius: 4)
                    .fill(activeTab == 1 ? Color.accentColor : Color.white.opacity(0.15))
                    .frame(width: 80, height: 24)
                    .overlay(Text("Tab 2").font(.system(size: 9, weight: .semibold)).foregroundColor(.white))
            }
        }
    }

    private var tabSwitchDemoView: some View {
        let activeTab = animTick < 10 ? 0 : (animTick < 20 ? 1 : 2)
        let tabNames = ["Tab 1: Apple", "Tab 2: News", "Tab 3: Music"]
        let pageIcons = ["apple.logo", "newspaper.fill", "music.note"]

        return VStack(spacing: 6) {
            HStack(spacing: 4) {
                ForEach(0..<3) { idx in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(idx == activeTab ? Color.accentColor : Color.white.opacity(0.15))
                        .frame(height: 22)
                        .overlay(
                            Text(tabNames[idx])
                                .font(.system(size: 9, weight: idx == activeTab ? .bold : .regular))
                                .foregroundColor(idx == activeTab ? .white : .white.opacity(0.6))
                                .lineLimit(1)
                        )
                }
            }
            .padding(.horizontal, 16)

            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.10))
                .frame(width: 210, height: 75)
                .overlay(
                    VStack(spacing: 4) {
                        Image(systemName: pageIcons[activeTab])
                            .font(.system(size: 24))
                            .foregroundColor(.accentColor)
                        Text(tabNames[activeTab])
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                    }
                )
        }
    }

    private var spacesDemoView: some View {
        let spaceIndex = (animTick / 10) % 2
        return VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "square.split.2x1")
                Text(l10n.actionSwitchSpaces)
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.white)

            HStack(spacing: 12) {
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(spaceIndex == 0 ? Color.accentColor : Color.white.opacity(0.2))
                        .frame(width: 85, height: 48)
                        .overlay(Text("Desktop 1").font(.system(size: 9, weight: .semibold)).foregroundColor(.white))
                }

                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(spaceIndex == 1 ? Color.accentColor : Color.white.opacity(0.2))
                        .frame(width: 85, height: 48)
                        .overlay(Text("Desktop 2").font(.system(size: 9, weight: .semibold)).foregroundColor(.white))
                }
            }
        }
    }

    private var historyDemoView: some View {
        let isGoingBack = (animTick / 15) == 0
        return VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: isGoingBack ? "arrow.left" : "arrow.right")
                Text(l10n.actionNavigateHistory)
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.white)

            HStack(spacing: 16) {
                Image(systemName: "arrow.left.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(isGoingBack ? .accentColor : .white.opacity(0.3))
                    .scaleEffect(isGoingBack ? 1.15 : 0.95)

                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(!isGoingBack ? .accentColor : .white.opacity(0.3))
                    .scaleEffect(!isGoingBack ? 1.15 : 0.95)
            }
        }
    }

    private var trackpadModeDemoView: some View {
        VStack(spacing: 8) {
            Image(systemName: "hand.draw")
                .font(.system(size: 26))
                .foregroundColor(.accentColor)
            Text(l10n.virtualTrackpadModeTitle)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
            Text(l10n.virtualTrackpadModeDesc)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
    }
}
