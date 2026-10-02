# 🪄 MagicGlide

<p align="center">
  <strong>Supercharge your Apple Magic Mouse into a gesture-packed, high-precision Trackpad powerhouse.</strong>
</p>

<p align="center">
  <a href="#-english"><strong>🇬🇧 English</strong></a> • 
  <a href="#-tiếng-việt"><strong>🇻🇳 Tiếng Việt</strong></a>
</p>

<p align="center">
  <em>👉 <strong>Bạn đọc Việt Nam:</strong> Kéo xuống dưới hoặc <a href="#-tiếng-việt"><strong>bấm vào đây để xem bản Tiếng Việt</strong></a>.</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2011.0+-000000?style=flat-square&logo=apple" alt="macOS">
  <img src="https://img.shields.io/badge/Architecture-Universal%20(Apple%20Silicon%20%2B%20Intel)-brightgreen?style=flat-square" alt="Universal Binary">
  <img src="https://img.shields.io/badge/Tests-51%20Passed-success?style=flat-square" alt="Tests">
  <img src="https://img.shields.io/badge/License-MIT-blue?style=flat-square" alt="License">
</p>

---

## 🗺️ Magic Mouse Surface Gesture Map / Bản đồ cử chỉ

```text
 ┌─────────────────────────────────────────────────────────────┐
 │                         [ FRONT ]                           │
 │                                                             │
 │   ┌──────────────────────┬───────┬──────────────────────┐   │
 │   │      LEFT CLICK      │   │   │     RIGHT CLICK      │   │
 │   │     (Tap 1-Finger)   │   │   │    (Tap 1-Finger)    │   │
 │   │                      │   │   │                      │   │
 │   │                      │   │   │                      │   │
 │ ◄─┼──────────────────────┤   │   ├──────────────────────┼─► │
 │ L │   BRIGHTNESS SLIDER  │   ▼   │    VOLUME SLIDER     │ R │
 │ E │  (Slide along left)  │       │ (Slide along right)  │ I │
 │ F │                      │ 2/3   │                      │ G │
 │ T │                      │FINGER │                      │ H │
 │   │                      │GESTURE│                      │ T │
 │ E │                      │ ZONE  │                      │   │
 │ D │                      │       │                      │ E │
 │ G │                      │       │                      │ D │
 │ E │                      │       │                      │ G │
 │   └──────────────────────┴───────┴──────────────────────┘   │
 │                                                             │
 │   ───────────────────────────────────────────────────────   │
 │                  PALM REJECTION ZONE (Deadzone)             │
 │                                                             │
 │                         [ REAR ]                            │
 └─────────────────────────────────────────────────────────────┘
```

---

<a name="-english"></a>
# 🇬🇧 English

> 💡 **Dành cho bạn đọc Việt Nam:** Phần tài liệu và hướng dẫn đầy đủ bằng **Tiếng Việt** nằm ở nửa dưới của trang. Bạn có thể [bấm vào đây để nhảy xuống phần Tiếng Việt ngay ➔](#-tiếng-việt)

## 🌟 Why MagicGlide?

The Apple Magic Mouse has iconic hardware and a capacitive multi-touch surface, yet out-of-the-box macOS treats it like a basic mouse with stiff scrolling. **MagicGlide** unlocks the true potential of your Magic Mouse:

- **No more stiff clicking:** Enjoy silky tap-to-click just like on a MacBook trackpad.
- **Edge Volume & Brightness:** Slide your finger along the left or right rail for instant system volume and display brightness adjustments with native Apple OSD bezels.
- **Virtual Trackpad Mode:** Transform your mouse into a stationary desk trackpad. Steer the cursor with 1 finger on the surface, click by tapping, and scroll smoothly with 2 fingers.
- **Effortless Window Control:** Swipe up for Mission Control, and swipe down to smoothly dismiss back to desktop.
- **4-Layer False-Positive Defense:** Advanced palm rest rejection, grip filter, and momentum veto ensure your gestures trigger only when you want them to.

---

## ✨ Features Overview

| Feature | Gesture | Action / Details |
| :--- | :--- | :--- |
| **Tap to Click** | ☝️ 1-Finger Tap | Left-click on left side, Right-click on right side (customizable split zone). |
| **Physical 2-Finger Click** | ✌️ Press down with 2 fingers | Mechanical switch press transforms to Middle-Click or customizable action. |
| **Virtual Trackpad Mode** | 3-Finger Tap / Hotkey | Mouse stays stationary; 1-finger moves cursor, 2-finger scrolls with native macOS inertia, tap clicks. |
| **Volume Control** | 🎛️ Slide Right Edge | Adjust system volume up/down with native Apple floating bezel. |
| **Brightness Control** | 💡 Slide Left Edge | Smoothly control Mac display brightness natively. |
| **Mission Control** | ⬆️ 2-Finger Swipe Up | Opens Mission Control overview. |
| **Contextual Dismissal** | ⬇️ 2-Finger Swipe Down | Closes Mission Control and returns to normal desktop. |
| **Tab Scrubbing** | 🖐️ 3-Finger Horizontal Slide | Fluidly cycle through Safari, Chrome, or VS Code tabs like a jog wheel. |
| **Pinch-to-Zoom** | 🤏 2-Finger Pinch | Real-time native magnification zoom. |
| **Move-to-Zoom** | ↕️ Hold 2 fingers & push mouse | Cursor freezes in place while physical mouse displacement zooms in/out. |
| **Drag Lock** | ✌️ 2-Finger Tap | Locks mouse down for easy window dragging; tap again to release. |

---

## 🎬 Visual Feature Showcase

### 1. 🖱️ Tap-to-Click & Right-Click Zone
Tap gently anywhere on the mouse glass surface without pressing down the mechanical switch.
<p align="center">
  <img src="assets/demo_tap_click.gif" width="520" alt="Tap to Click Demo">
</p>

### 2. 🎛️ Dual Edge Sliders (Volume & Brightness)
Slide your finger along the right rail for system volume and left rail for display brightness with native Apple OSD bezels.
<p align="center">
  <img src="assets/demo_edge_volume.gif" width="48%" alt="Volume Slider Demo">
  <img src="assets/demo_edge_brightness.gif" width="48%" alt="Brightness Slider Demo">
</p>

### 3. 💻 Virtual Trackpad Mode
Converts your mouse into a stationary desk trackpad. Steer pointer with 1 finger, scroll smoothly with 2 fingers, and tap to click.
<p align="center">
  <img src="assets/demo_virtual_trackpad.gif" width="520" alt="Virtual Trackpad Demo">
</p>

### 4. 🪟 Mission Control & Contextual Return
Swipe up to reveal Mission Control overview, swipe down to pull windows back down to normal desktop.
<p align="center">
  <img src="assets/demo_mission_control.gif" width="520" alt="Mission Control Demo">
</p>

### 5. 📑 Continuous 3-Finger Tab Scrubbing
Fluidly cycle through browser or editor tabs like a jog wheel.
<p align="center">
  <img src="assets/demo_tab_switch.gif" width="520" alt="Tab Scrubbing Demo">
</p>

### 6. 🔍 Dual Zoom Engines (Pinch-to-Zoom & Move-to-Zoom)
Pinch with 2 fingers or push/pull mouse forward/backward while freezing the cursor in place.
<p align="center">
  <img src="assets/demo_pinch_zoom.gif" width="520" alt="Pinch to Zoom Demo">
</p>

### 7. ✌️ 2-Finger Physical Click (Middle Click)
Physically press down the mouse switch with 2 fingers touching to open links in background tabs.
<p align="center">
  <img src="assets/demo_middle_click.gif" width="520" alt="Middle Click Demo">
</p>

---

## 🛡️ 4-Layer False-Trigger Defense System

To prevent accidental clicks and unintended gesture activations while resting your hand or scrolling:

1. **Palm & Grip Rejection:** Automatically rejects palm contacts at the rear base (Y < 0.18) and thumb/pinky grips along the outer edges.
2. **Symmetry & Direction Validation:** Multi-finger swipes require all fingers to travel in parallel with consistent displacement ratios.
3. **Momentum & Scroll Veto:** Tap and click synthesizers are temporarily guarded during active scrolling and inertia deceleration.
4. **Context-Aware Dismissal:** Downward swipes inside Mission Control intelligently close Mission Control rather than misfiring secondary actions.

---

## 🚀 Installation & Quick Start

### Option 1: Download DMG Installer (Recommended)

1. Download `MagicGlide.dmg` from the [Releases](https://github.com/nguyenvanbao1904/MagicGlide/releases) page.
2. Double-click the downloaded `.dmg` file.
3. Simply drag **MagicGlide.app** into the **Applications** folder shortcut.
4. Open **MagicGlide** from Applications.
5. When prompted, grant **Accessibility** permissions:
   - Go to **System Settings → Privacy & Security → Accessibility**.
   - Toggle **MagicGlide** to **ON** ✓.

### Option 2: Build From Source

Requirements: macOS 11.0+ and Xcode command line tools.

```bash
# Clone the repository
git clone https://github.com/nguyenvanbao1904/MagicGlide.git
cd MagicGlide

# Run the automated test suite (51 unit tests)
./Scripts/run_tests.sh

# Build Universal Binary (Apple Silicon + Intel) with ad-hoc signing
./build.sh

# Optional: Package into MagicGlide.dmg installer
./create_dmg.sh

# Launch the app
open build/MagicGlide.app
```

---

## ⚙️ Configuration & Settings

Click the **MagicGlide** icon in your macOS menu bar to:
- Open the **Apple-style Preferences Window** with interactive visual canvas and live touch tracking.
- Toggle individual gestures on or off.
- Rebind gestures (Middle Click, Mission Control, App Exposé, Show Desktop, Smart Zoom, Trackpad Mode).
- Adjust tap sensitivity and the Right-Click zone boundary.
- Switch app interface language between **English** and **Tiếng Việt**.

---

## ❓ Troubleshooting

- **Taps aren't registering:** Check **System Settings → Privacy & Security → Accessibility**. Remove and re-add `MagicGlide.app` if you recently rebuilt the binary.
- **Mouse isn't detected:** Ensure your Magic Mouse is paired and connected via Bluetooth. MagicGlide monitors external Magic Mice and ignores built-in trackpads.
- **Scroll interference:** Virtual Trackpad Mode features native 2-finger scroll passthrough while eliminating 1-finger scroll jitter.

---

<a name="-tiếng-việt"></a>
# 🇻🇳 Tiếng Việt

## 🌟 Tại sao bạn nên dùng MagicGlide?

Apple Magic Mouse sở hữu bề mặt cảm ứng đa điểm tuyệt đẹp, nhưng macOS mặc định lại thiếu đi rất nhiều cử chỉ tiện lợi. **MagicGlide** biến chiếc Magic Mouse của bạn thành một chiếc Trackpad thực thụ:

- **Chạm nhẹ là Click (Tap-to-Click):** Không cần bấm lún chuột cứng nhắc, chỉ cần chạm nhẹ ngón tay lên mặt kính để click chuột trái / chuột phải.
- **Vuốt mép chỉnh Âm lượng & Độ sáng:** Miết dọc theo cạnh viền trái hoặc phải của chuột để tăng/giảm âm lượng và độ sáng màn hình với giao diện OSD Apple chính chủ.
- **Chế độ Trackpad ảo (Virtual Trackpad Mode):** Biến chuột thành một bàn rê cố định trên bàn làm việc — miết 1 ngón di chuyển con trỏ, chạm 1 ngón để click, vuốt 2 ngón cuộn trang mượt mà có trượt quán tính.
- **Quản lý cửa sổ thông minh:** Vuốt lên mở Mission Control, vuốt xuống lập tức đóng Mission Control về lại màn hình bình thường.
- **Chống chạm nhầm 4 lớp:** Thuật toán lọc lòng bàn tay, mép ngón tay cái và ngón út giúp bạn yên tâm cầm chuột tự nhiên mà không lo nhảy cử chỉ bậy bạ.

---

## ✨ Bảng tóm tắt các tính năng

| Tính năng | Cử chỉ | Tác dụng |
| :--- | :--- | :--- |
| **Chạm để Click** | ☝️ Chạm 1 ngón | Chạm bên trái là chuột trái, chạm bên phải là chuột phải (tự chỉnh được tỷ lệ vùng). |
| **Bấm cơ 2 ngón** | ✌️ Bấm lún chuột khi đặt 2 ngón | Tự động chuyển thành nút chuột giữa (Middle Click) hoặc hành động tùy chọn. |
| **Trackpad ảo** | Chạm 3 ngón / Phím tắt | Chuột đứng yên; 1 ngón lái chuột, 2 ngón cuộn mượt mà chuẩn macOS, chạm nhẹ là click. |
| **Chỉnh Âm lượng** | 🎛️ Miết mép phải | Tăng / giảm âm lượng máy tính kèm thanh hiển thị nổi của macOS. |
| **Chỉnh Độ sáng** | 💡 Miết mép trái | Tăng / giảm độ sáng màn hình trực tiếp. |
| **Mở Mission Control** | ⬆️ Vuốt 2 ngón lên | Hiện tổng quan tất cả cửa sổ đang mở. |
| **Đóng về bình thường** | ⬇️ Vuốt 2 ngón xuống | Đóng Mission Control và quay về màn hình làm việc (giống Trackpad Apple). |
| **Chuyển Tab liên tục** | 🖐️ Trượt ngang 3 ngón | Lướt qua lại giữa các tab trình duyệt (Safari, Chrome) hoặc file code cực nhanh. |
| **Thu phóng Pinch** | 🤏 Chụm / bung 2 ngón | Thu phóng nội dung (Pinch to Zoom) trực tiếp. |
| **Move to Zoom** | ↕️ Giữ 2 ngón & đẩy chuột | Khóa con trỏ đứng yên, đẩy tới/kéo lui chuột để phóng to thu nhỏ. |
| **Khóa kéo (Drag Lock)**| ✌️ Chạm 2 ngón | Giữ chuột trái để kéo thả tài liệu không mỏi tay; chạm lại 2 ngón để nhả. |

---

## 🎬 Trình diễn tính năng trực quan (Demo GIFs)

### 1. 🖱️ Chạm để Click (Tap-to-Click) & Phân vùng Chuột phải
Chạm nhẹ lên mặt chuột là nhận click, không cần dùng lực bấm phím cơ.
<p align="center">
  <img src="assets/demo_tap_click.gif" width="520" alt="Demo Chạm để click">
</p>

### 2. 🎛️ Vuốt mép chỉnh Âm lượng & Độ sáng (Dual Edge Sliders)
Miết ngón tay dọc viền mép phải để chỉnh âm lượng và mép trái để chỉnh độ sáng màn hình cực kỳ tiện lợi kèm OSD chính chủ Apple.
<p align="center">
  <img src="assets/demo_edge_volume.gif" width="48%" alt="Demo Vuốt mép phải chỉnh Âm lượng">
  <img src="assets/demo_edge_brightness.gif" width="48%" alt="Demo Vuốt mép trái chỉnh Độ sáng">
</p>

### 3. 💻 Chế độ Trackpad ảo (Virtual Trackpad Mode)
Biến chuột thành bàn rê cố định: 1 ngón rê chuột, 2 ngón cuộn trượt quán tính, chạm nhẹ là click.
<p align="center">
  <img src="assets/demo_virtual_trackpad.gif" width="520" alt="Demo Trackpad ảo">
</p>

### 4. 🪟 Mở & Đóng Mission Control ngữ cảnh
Vuốt 2 ngón lên mở Mission Control; khi đang ở Mission Control, vuốt 2 ngón xuống sẽ tự động thu cửa sổ về màn hình làm việc.
<p align="center">
  <img src="assets/demo_mission_control.gif" width="520" alt="Demo Mission Control">
</p>

### 5. 📑 Lướt chuyển Tab 3 ngón liên tục (Tab Scrubbing)
Trượt 3 ngón tay qua lại để chuyển đổi nhanh giữa các tab trình duyệt hoặc editor.
<p align="center">
  <img src="assets/demo_tab_switch.gif" width="520" alt="Demo Chuyển Tab">
</p>

### 6. 🔍 Thu phóng 2 ngón (Pinch Zoom & Move to Zoom)
Chụm bung 2 ngón hoặc giữ 2 ngón đẩy chuột để phóng to/thu nhỏ tài liệu.
<p align="center">
  <img src="assets/demo_pinch_zoom.gif" width="520" alt="Demo Thu phóng">
</p>

### 7. ✌️ Bấm cơ 2 ngón (Physical Click -> Middle Click)
Bấm lún phím chuột khi đặt 2 ngón để mở link tab mới (chuột giữa) hoặc action tùy chọn.
<p align="center">
  <img src="assets/demo_middle_click.gif" width="520" alt="Demo Chuột giữa 2 ngón">
</p>

---

## 🛡️ Hệ thống chống chạm nhầm 4 lớp

1. **Lọc lòng bàn tay & gờ cầm:** Bỏ qua các điểm chạm ở phần đuôi chuột (nơi tựa lòng bàn tay) và hai mép hông nơi ngón cái/ngón út tì vào để cầm chuột.
2. **Kiểm tra tính đồng hướng & đối xứng:** Cử chỉ vuốt đa ngón đòi hỏi các ngón tay phải di chuyển cùng hướng với biên độ tương đương.
3. **Scroll & Momentum Veto:** Tạm ngưng nhận diện click nhầm khi trang web đang cuộn nhanh hoặc đang trượt quán tính.
4. **Nhận biết ngữ cảnh:** Khi đang ở trong Mission Control, thao tác vuốt xuống sẽ luôn được ưu tiên để đóng Mission Control thay vì kích hoạt hành động khác.

---

## 🚀 Cài đặt & Hướng dẫn sử dụng

### Cách 1: Tải file DMG cài đặt (Khuyên dùng)

1. Tải file `MagicGlide.dmg` từ mục [Releases](https://github.com/nguyenvanbao1904/MagicGlide/releases).
2. Nhấp đúp mở file `.dmg` vừa tải về.
3. Kéo biểu tượng **MagicGlide.app** vào lối tắt thư mục **Applications** (Ứng dụng).
4. Mở **MagicGlide** từ Applications.
5. Cấp quyền **Trợ năng (Accessibility)** theo hướng dẫn trên màn hình:
   - Vào **Cài đặt hệ thống → Quyền riêng tư & Bảo mật → Trợ năng**.
   - Bật công tắc cho **MagicGlide** ✓.

### Cách 2: Tự biên dịch từ mã nguồn

Yêu cầu máy có cài Xcode Command Line Tools:

```bash
# Clone repo về máy
git clone https://github.com/nguyenvanbao1904/MagicGlide.git
cd MagicGlide

# Chạy kiểm thử tự động (51 bài test unit test)
./Scripts/run_tests.sh

# Build Universal Binary (chạy được cả Apple Silicon và Intel)
./build.sh

# (Tùy chọn) Đóng gói file cài đặt MagicGlide.dmg
./create_dmg.sh

# Chạy ứng dụng
open build/MagicGlide.app
```

---

## ⚙️ Cài đặt & Tùy biến

Nhấp vào biểu tượng chuột trên thanh Menu Bar để:
- Mở **Giao diện Cài đặt chuẩn macOS** với mô hình chuột trực quan, nhận diện ngón tay theo thời gian thực.
- Bật/tắt hoặc đổi cử chỉ cho từng thao tác (Chuột giữa, Mission Control, App Exposé, Hiện Desktop, Thu phóng thông minh, Trackpad ảo).
- Điều chỉnh độ nhạy chạm và độ rộng vùng chuột phải.
- Chuyển đổi ngôn ngữ hiển thị giữa **Tiếng Việt** và **English**.

---

## ❓ Câu hỏi thường gặp & Khắc phục lỗi

* **Không nhận cử chỉ chạm:** Vào **Cài đặt hệ thống → Quyền riêng tư & Bảo mật → Trợ năng**, xóa và thêm lại `MagicGlide.app`.
* **Không nhận diện chuột:** Đảm bảo Magic Mouse đang kết nối qua Bluetooth. Ứng dụng chỉ xử lý Magic Mouse ngoài và tự động bỏ qua Trackpad tích hợp của MacBook.
* **Cuộn trang trong Trackpad ảo:** Khi bật Trackpad ảo, việc miết 1 ngón chỉ điều khiển con trỏ chuột, còn vuốt 2 ngón sẽ cuộn trang tự nhiên với gia tốc mượt mà của macOS.

---

## 📄 License & Credits

- Distributed under the **MIT License**.
- Originally inspired by [mousetoucher](https://github.com/slopcore/mousetoucher) by Roger Hughes.
- Extensively re-architected, upgraded, and maintained with modern Swift, full gesture suite, and Virtual Trackpad mode.
