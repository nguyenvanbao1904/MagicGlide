import Foundation

struct L10n {
    let lang: Preferences.AppLanguage

    var pointAndClick: String { lang == .vi ? "Trỏ & Bấm" : "Point & Click" }
    var edgeSliders: String { lang == .vi ? "Vuốt Viền" : "Edge Sliders" }
    var moreGestures: String { lang == .vi ? "Cử chỉ khác" : "More Gestures" }

    var tapToClickTitle: String { lang == .vi ? "Chạm để bấm (Tap to Click)" : "Tap to Click" }
    var tapToClickDesc: String { lang == .vi ? "Chạm nhẹ một ngón tay lên bề mặt để click chuột" : "Tap surface lightly with one finger to click" }

    var secondaryClickTitle: String { lang == .vi ? "Bấm chuột phụ (Chuột phải)" : "Secondary Click (Right Click)" }
    var secondaryClickDesc: String { lang == .vi ? "Kéo để thay đổi vị trí ranh giới nhận diện chuột phải" : "Adjust dividing boundary between left and right click" }
    var leftPct: String { lang == .vi ? "Trái" : "Left" }
    var rightPct: String { lang == .vi ? "Phải" : "Right" }

    var tapSensitivityTitle: String { lang == .vi ? "Độ nhạy khi chạm" : "Tap Sensitivity" }
    var palmRejectionTitle: String { lang == .vi ? "Vùng lọc lòng bàn tay (Palm Rejection)" : "Palm Rejection" }
    var palmRejectionDesc: String { lang == .vi ? "Bỏ qua các va chạm ở phần đuôi chuột khi tỳ tay" : "Filters touches on lower mouse body while resting hand" }

    var edgeSlidersTitle: String { lang == .vi ? "Vuốt mép viền (Edge Sliders)" : "Edge Sliders (Volume & Brightness)" }
    var edgeSlidersDesc: String { lang == .vi ? "Trượt ngón tay dọc theo mép ngoài để điều chỉnh Âm lượng hoặc Độ sáng" : "Slide along outer edges to adjust Volume (right) or Brightness (left)" }
    var leftEdgeBrightness: String { lang == .vi ? "Viền trái: Độ sáng" : "Left Edge: Brightness" }
    var rightEdgeVolume: String { lang == .vi ? "Viền phải: Âm lượng" : "Right Edge: Volume" }
    var slideUpDown: String { lang == .vi ? "Vuốt lên/xuống" : "Slide up / down" }
    var edgeWidthTitle: String { lang == .vi ? "Độ rộng vùng nhận diện mép" : "Edge Detection Width" }

    var moveZoomTitle: String { lang == .vi ? "Đẩy chuột để thu phóng (Move to Zoom)" : "2-Finger Move to Zoom (Push/Pull)" }
    var moveZoomDesc: String { lang == .vi ? "Đặt 2 ngón tay lên chuột và đẩy/kéo chuột tới lui để zoom mượt mà" : "Rest 2 fingers on mouse and push/pull physical mouse to zoom" }

    var pinchZoomTitle: String { lang == .vi ? "Thu phóng bằng cách chụm ngón tay (Pinch to Zoom)" : "2-Finger Pinch to Zoom" }
    var pinchZoomDesc: String { lang == .vi ? "Chụm hoặc xòe hai ngón tay trên mặt chuột để phóng to/thu nhỏ" : "Pinch or spread two fingers apart on surface to zoom" }

    var smartZoomTitle: String { lang == .vi ? "Thu phóng thông minh (Smart Zoom Support)" : "Smart Zoom Support (130ms Buffer)" }
    var smartZoomDesc: String { lang == .vi ? "Chạm hai lần nhanh bằng một ngón tay để phóng to văn bản hoặc trang web" : "Quickly double-tap with one finger to zoom content" }

    var threeFingerTapTitle: String { lang == .vi ? "Chạm hoặc bấm 3 ngón tay" : "3-Finger Tap or Click" }
    var threeFingerTapDesc: String { lang == .vi ? "Chạm nhẹ hoặc bấm vật lý bằng 3 ngón tay để kích hoạt tác vụ" : "Tap lightly or physically click with 3 fingers to trigger action" }

    var threeFingerSwipeTitle: String { lang == .vi ? "Vuốt 3 ngón tay" : "3-Finger Swipe" }
    var threeFingerSwipeDesc: String { lang == .vi ? "Lướt 3 ngón tay sang trái hoặc phải để thực hiện tác vụ" : "Glide 3 fingers horizontally to trigger action" }
    var swipeDirection: String { lang == .vi ? "Hướng vuốt" : "Swipe Direction" }
    var naturalSwipe: String { lang == .vi ? "Tự nhiên (Vuốt sang trái: Tab tiếp theo)" : "Natural (Swipe Left: Next Tab)" }
    var directSwipe: String { lang == .vi ? "Trực tiếp (Vuốt sang phải: Tab tiếp theo)" : "Direct (Swipe Right: Next Tab)" }

    var accessibilityBtn: String { lang == .vi ? "Quyền Trợ năng…" : "Accessibility Settings…" }
    var bluetoothBtn: String { lang == .vi ? "Cài đặt Bluetooth…" : "Bluetooth Settings…" }
    var submitBtn: String { lang == .vi ? "Xác nhận" : "Submit" }
    var cut: String { lang == .vi ? "Cắt" : "Cut" }
    var copy: String { lang == .vi ? "Sao chép" : "Copy" }
    var paste: String { lang == .vi ? "Dán" : "Paste" }
    var displayBrightness: String { lang == .vi ? "Độ sáng Màn hình" : "Display Brightness" }
    var soundVolume: String { lang == .vi ? "Âm lượng Âm thanh" : "Sound Volume" }
    var middleClickTitle: String { lang == .vi ? "Bấm chuột giữa: Mở liên kết" : "Middle Click: Open Link" }
    var switchSpacesTitle: String { lang == .vi ? "Chuyển giữa các Tab & Ứng dụng" : "Switch Between Tabs & Spaces" }

    // Action Dropdown Options
    var actionMiddleClick: String { lang == .vi ? "Chuột giữa (Middle Click)" : "Middle Click" }
    var actionMissionControl: String { lang == .vi ? "Mission Control" : "Mission Control" }
    var actionAppExpose: String { lang == .vi ? "App Exposé (Cửa sổ ứng dụng hiện tại)" : "App Exposé (Current App Windows)" }
    var actionShowDesktop: String { lang == .vi ? "Xem bàn làm việc (Desktop)" : "Show Desktop" }
    var actionLaunchpad: String { lang == .vi ? "Launchpad" : "Launchpad" }
    var actionDragLock: String { lang == .vi ? "Khóa kéo chuột (Drag Lock)" : "Drag Lock" }
    var actionSwitchNextTab: String { lang == .vi ? "Tab tiếp theo (Next Tab)" : "Next Tab" }
    var actionSwitchTabs: String { lang == .vi ? "Chuyển Tab duyệt web liên tục" : "Continuous Tab Scrubbing" }
    var actionSwitchSpaces: String { lang == .vi ? "Chuyển màn hình / Spaces" : "Switch Spaces / Fullscreen" }
    var actionNavigateHistory: String { lang == .vi ? "Quay lại / Tiến tới (Back / Forward)" : "History Back / Forward" }
    var actionVolume: String { lang == .vi ? "Âm lượng hệ thống" : "System Volume" }
    var actionBrightness: String { lang == .vi ? "Độ sáng màn hình" : "Display Brightness" }
    var actionSmartZoom: String { lang == .vi ? "Thu phóng thông minh" : "Smart Zoom" }
    var actionZoom: String { lang == .vi ? "Thu phóng mượt mà (Zoom)" : "Smooth Zoom" }
    var actionClickRight: String { lang == .vi ? "Bấm bên phải" : "Click Right Side" }
    var actionClickLeft: String { lang == .vi ? "Bấm bên trái" : "Click Left Side" }
    var actionNone: String { lang == .vi ? "Tắt (Không làm gì)" : "Off (Disabled)" }
    var gestureDisabledDesc: String { lang == .vi ? "Tác vụ này đang được tắt trong phần cài đặt" : "This gesture is currently disabled in settings" }

    var twoFingerMoveTitle: String { lang == .vi ? "Đẩy chuột 2 ngón (Move)" : "2-Finger Push/Pull (Move)" }
    var twoFingerMoveDesc: String { lang == .vi ? "Đặt 2 ngón tay lên lưng chuột và đẩy/kéo chuột tới lui" : "Rest 2 fingers on mouse and push/pull physical mouse" }
    var pinchTitle: String { lang == .vi ? "Chụm 2 ngón tay (Pinch)" : "2-Finger Pinch" }
    var pinchDesc: String { lang == .vi ? "Chụm hoặc xòe hai ngón tay trên mặt chuột" : "Pinch or spread two fingers apart on surface" }

    var twoFingerTapTitle: String { lang == .vi ? "Chạm 2 ngón tay" : "2-Finger Tap" }
    var twoFingerTapDesc: String { lang == .vi ? "Chạm nhẹ hai ngón tay lên lưng chuột để kích hoạt tác vụ" : "Tap surface lightly with two fingers to trigger action" }
    var twoFingerSwipeUpTitle: String { lang == .vi ? "Vuốt lên 2 ngón (Swipe Up)" : "2-Finger Swipe Up" }
    var twoFingerSwipeUpDesc: String { lang == .vi ? "Lướt 2 ngón tay hướng lên trên để kích hoạt tác vụ" : "Glide 2 fingers upwards to trigger action" }
    var twoFingerSwipeDownTitle: String { lang == .vi ? "Vuốt xuống 2 ngón (Swipe Down)" : "2-Finger Swipe Down" }
    var twoFingerSwipeDownDesc: String { lang == .vi ? "Lướt 2 ngón tay hướng xuống dưới để kích hoạt tác vụ" : "Glide 2 fingers downwards to trigger action" }
    var leftEdgeTitle: String { lang == .vi ? "Mép viền bên trái (Left Edge)" : "Left Edge Slide" }
    var leftEdgeDesc: String { lang == .vi ? "Trượt ngón tay dọc theo cạnh mép trái" : "Slide finger along the left edge" }
    var rightEdgeTitle: String { lang == .vi ? "Mép viền bên phải (Right Edge)" : "Right Edge Slide" }
    var rightEdgeDesc: String { lang == .vi ? "Trượt ngón tay dọc theo cạnh mép phải" : "Slide finger along the right edge" }

    // Disconnected & Bluetooth guidance
    var mouseNotConnectedTitle: String { lang == .vi ? "Chưa kết nối Magic Mouse" : "Magic Mouse Not Connected" }
    var mouseNotConnectedDesc: String { lang == .vi ? "Bật công tắc nguồn ở mặt dưới Magic Mouse và kết nối trong Cài đặt Bluetooth để bắt đầu sử dụng." : "Turn on your Magic Mouse power switch and connect it in Bluetooth Settings to start using." }
    var bluetoothOffTitle: String { lang == .vi ? "Bluetooth đang tắt" : "Bluetooth is Turned Off" }
    var bluetoothOffDesc: String { lang == .vi ? "Vui lòng bật Bluetooth trên máy Mac để tìm và kết nối với Magic Mouse của bạn." : "Please turn on Bluetooth on your Mac to connect your Magic Mouse." }
    var openBluetoothSettingsBtn: String { lang == .vi ? "Mở Cài đặt Bluetooth…" : "Open Bluetooth Settings…" }
    var retryScanBtn: String { lang == .vi ? "Kiểm tra lại" : "Refresh Status" }
    var stepPowerOnTitle: String { lang == .vi ? "Bật nguồn chuột" : "Power On Mouse" }
    var stepPowerOnDesc: String { lang == .vi ? "Gạt công tắc ở mặt đáy chuột sang màu xanh lá." : "Flip the power switch on the bottom of the mouse to green." }
    var stepConnectTitle: String { lang == .vi ? "Kết nối Bluetooth" : "Connect Bluetooth" }
    var stepConnectDesc: String { lang == .vi ? "Vào Cài đặt Bluetooth trên máy Mac để tìm và kết nối với Magic Mouse." : "Open Bluetooth Settings on your Mac to pair or connect your Magic Mouse." }

    // Physical 2-Finger Click & Virtual Trackpad Mode
    var twoFingerClickTitle: String { lang == .vi ? "Bấm cơ 2 ngón (Physical 2-Finger Click)" : "2-Finger Physical Click" }
    var twoFingerClickDesc: String { lang == .vi ? "Ấn lún thân chuột khi 2 ngón tay đang đặt trên mặt lưng chuột" : "Physically press the mouse down while resting 2 fingers" }
    var actionToggleTrackpadMode: String { lang == .vi ? "Bật/Tắt Trackpad ảo (Virtual Trackpad)" : "Toggle Virtual Trackpad Mode" }
    var virtualTrackpadModeTitle: String { lang == .vi ? "Chế độ Trackpad ảo" : "Virtual Trackpad Mode" }
    var virtualTrackpadModeDesc: String { lang == .vi ? "Dùng 1 ngón tay miết trên mặt kính để di chuyển con trỏ, không cần rê chuột" : "Stroke finger on surface to move pointer without moving physical mouse" }
}
