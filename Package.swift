// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "MagicGlide",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "MagicGlideLib",
            targets: ["MagicGlideLib"]
        )
    ],
    targets: [
        .target(
            name: "MagicGlideLib",
            dependencies: [],
            path: "Sources",
            exclude: [
                "App",
                "System",
                "Core/MultitouchBridge.h",
                "Core/MultitouchManager.swift",
                "Actions/ActionContext.swift",
                "Actions/ActionExecutor.swift",
                "Actions/GestureAction+Presentation.swift",
                "UI/MagicMouseCanvasView.swift",
                "UI/MouseDeviceInfo.swift",
                "UI/SettingsPreferencesView.swift",
                "UI/SettingsViewModel.swift",
                "UI/SettingsWindowController.swift"
            ],
            sources: [
                "Actions/GestureSlot.swift",
                "Actions/GestureAction.swift",
                "Actions/GestureAction+Compatibility.swift",
                "Actions/GestureConfiguration.swift",
                "Core/SurfaceTouch.swift",
                "Gestures/TapDetector.swift",
                "Gestures/TwoFingerTapDetector.swift",
                "Gestures/ThreeFingerGestureDetector.swift",
                "Gestures/PinchZoomDetector.swift",
                "Gestures/TwoFingerMoveZoomDetector.swift",
                "Gestures/TwoFingerSwipeDetector.swift",
                "Settings/Preferences.swift",
                "UI/Localization.swift"
            ]
        ),
        .testTarget(
            name: "MagicGlideTests",
            dependencies: ["MagicGlideLib"],
            path: "Tests"
        )
    ]
)
