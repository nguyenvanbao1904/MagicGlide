import Foundation
import IOKit
import IOBluetooth

enum MouseSkinColor: String, CaseIterable, Identifiable {
    case white = "White"
    case black = "Space Gray"

    var id: String { rawValue }
}

final class MouseDeviceInfo: ObservableObject {
    static let shared = MouseDeviceInfo()

    @Published var name: String = "Magic Mouse"
    @Published var batteryLevel: Int = 100
    @Published var color: MouseSkinColor = .white
    @Published var isConnected: Bool = true
    @Published var isBluetoothOn: Bool = true
    @Published var address: String = ""

    private var refreshTimer: Timer?

    struct DeviceSnapshot {
        var name: String = "Magic Mouse"
        var batteryLevel: Int = -1
        var color: MouseSkinColor = .white
        var isConnected: Bool = false
        var isBluetoothOn: Bool = true
        var address: String = ""
    }

    init() {
        let initial = MouseDeviceInfo.detectSnapshot()
        self.name = initial.name
        self.batteryLevel = initial.batteryLevel >= 0 ? initial.batteryLevel : 100
        self.color = initial.color
        self.isConnected = initial.isConnected
        self.isBluetoothOn = initial.isBluetoothOn
        self.address = initial.address

        startTimer()
    }

    func startTimer() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    static func detectSnapshot() -> DeviceSnapshot {
        var snapshot = DeviceSnapshot()

        // 1. Bluetooth host controller power state
        if let controller = IOBluetoothHostController.default() {
            snapshot.isBluetoothOn = (controller.powerState.rawValue == 1)
        } else {
            snapshot.isBluetoothOn = true
        }

        // If Bluetooth is off, Magic Mouse cannot be connected wirelessly
        guard snapshot.isBluetoothOn else {
            snapshot.isConnected = false
            return snapshot
        }

        // 2. Query IOKit for AppleDeviceManagementHIDEventService
        let matchingDict = IOServiceMatching("AppleDeviceManagementHIDEventService")
        var iterator: io_iterator_t = 0
        let masterPort = mach_port_t(MACH_PORT_NULL)

        if IOServiceGetMatchingServices(masterPort, matchingDict, &iterator) == KERN_SUCCESS {
            defer { IOObjectRelease(iterator) }
            var service = IOIteratorNext(iterator)
            while service != 0 {
                defer {
                    IOObjectRelease(service)
                    service = IOIteratorNext(iterator)
                }

                var props: Unmanaged<CFMutableDictionary>?
                if IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
                   let dict = props?.takeRetainedValue() as? [String: Any] {
                    let cat = dict["Accessory Category"] as? String
                    let pid = dict["ProductID"] as? Int ?? (dict["ProductIDArray"] as? [Int])?.first
                    let isBuiltIn = dict["Built-In"] as? Bool ?? false

                    if (cat == "Mouse" || pid == 803) && !isBuiltIn {
                        if let bat = dict["BatteryPercent"] as? Int {
                            snapshot.batteryLevel = bat
                        }
                        if let cid = dict["ColorID"] as? Int {
                            snapshot.color = (cid == 34) ? .black : .white
                        }
                        snapshot.address = dict["DeviceAddress"] as? String ?? dict["SerialNumber"] as? String ?? ""
                        snapshot.isConnected = true
                    }
                }
            }
        }

        // 3. Query IOBluetooth for user-configured custom name and connection status
        if let paired = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] {
            let normalizedTarget = snapshot.address.lowercased().replacingOccurrences(of: "-", with: ":")

            for device in paired {
                let devAddr = device.addressString?.lowercased().replacingOccurrences(of: "-", with: ":") ?? ""
                if !normalizedTarget.isEmpty && devAddr == normalizedTarget {
                    if let devName = device.nameOrAddress, !devName.isEmpty {
                        snapshot.name = devName
                    }
                    if device.isConnected() {
                        snapshot.isConnected = true
                    }
                    break
                } else if device.nameOrAddress?.localizedCaseInsensitiveContains("mouse") == true {
                    if device.isConnected() {
                        snapshot.name = device.nameOrAddress ?? snapshot.name
                        snapshot.isConnected = true
                    }
                }
            }
        }

        // 4. MultitouchSource fallback
        if let source = MultitouchSource.current, source.hasConnectedDevice {
            snapshot.isConnected = true
        }

        return snapshot
    }

    func refresh() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let snapshot = MouseDeviceInfo.detectSnapshot()
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if self.name != snapshot.name { self.name = snapshot.name }
                if snapshot.batteryLevel >= 0 && self.batteryLevel != snapshot.batteryLevel {
                    self.batteryLevel = snapshot.batteryLevel
                }
                if self.color != snapshot.color { self.color = snapshot.color }
                if self.isConnected != snapshot.isConnected { self.isConnected = snapshot.isConnected }
                if self.isBluetoothOn != snapshot.isBluetoothOn { self.isBluetoothOn = snapshot.isBluetoothOn }
                if self.address != snapshot.address { self.address = snapshot.address }
            }
        }
    }

    deinit {
        refreshTimer?.invalidate()
    }
}
