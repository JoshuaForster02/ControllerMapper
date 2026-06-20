import Foundation
import IOBluetooth

struct BluetoothPairedDevice: Identifiable, Hashable {
    let id: String          // address string, used as unique id
    let name: String
    let batteryPercent: Int?
}

/// Reads battery percentage from paired Bluetooth devices via IOBluetooth.
///
/// Many third-party "Xbox-compatible" controllers (e.g. ShanWan clones) don't
/// implement the HID battery feature report that `GCController.battery` reads.
/// But if the controller is paired over real Bluetooth, macOS itself often
/// already knows its battery level (the same value shown in the Bluetooth
/// menu / System Settings). `batteryPercent` isn't part of the public Swift
/// header for `IOBluetoothDevice`, so it's read dynamically via KVC — this is
/// the same approach several shipping battery-menu apps use.
enum BluetoothBatteryReader {

    static func pairedDevices() -> [BluetoothPairedDevice] {
        guard let raw = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else { return [] }
        return raw.compactMap { device in
            guard let address = device.addressString else { return nil }
            return BluetoothPairedDevice(
                id: address,
                name: device.name ?? "Unknown Device",
                batteryPercent: batteryPercent(for: device)
            )
        }
    }

    static func batteryPercent(forAddress address: String) -> Int? {
        guard let device = IOBluetoothDevice(addressString: address) else { return nil }
        return batteryPercent(for: device)
    }

    private static func batteryPercent(for device: IOBluetoothDevice) -> Int? {
        guard device.responds(to: NSSelectorFromString("batteryPercent")) else { return nil }
        guard let value = device.value(forKey: "batteryPercent") as? NSNumber else { return nil }
        let percent = value.intValue
        guard percent >= 0, percent <= 100 else { return nil }
        return percent
    }
}
