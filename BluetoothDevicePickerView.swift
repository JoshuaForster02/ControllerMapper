import SwiftUI

/// Lets the user manually pick which paired Bluetooth device corresponds to
/// their controller, for the cases where GCController doesn't expose battery
/// at all but macOS already knows the device's battery level via Bluetooth.
struct BluetoothDevicePickerView: View {
    @ObservedObject private var controller = ControllerManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var devices: [BluetoothPairedDevice] = []

    var body: some View {
        VStack(alignment: .leading, spacing: DS.spacingL) {
            SheetHeader(
                title: "Bluetooth-Akku-Quelle",
                systemImage: "battery.100.bolt",
                subtitle: "Dein Controller meldet seinen Akkustand nicht direkt an Apps. Falls er per Bluetooth gekoppelt ist, kennt macOS seinen Akkustand oft trotzdem — wähle hier das passende Gerät aus."
            )

            if devices.isEmpty {
                VStack(spacing: DS.spacingS) {
                    Image(systemName: "antenna.radiowaves.left.and.right.slash")
                        .font(.system(size: 28))
                        .foregroundStyle(.tertiary)
                    Text("Keine gekoppelten Bluetooth-Geräte gefunden")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 36)
                .cardSurface(radius: DS.radiusMedium)
            } else {
                List(devices) { device in
                    deviceRow(device)
                }
                .listStyle(.inset)
                .frame(height: 280)
                .clipShape(RoundedRectangle(cornerRadius: DS.radiusMedium))
            }

            HStack {
                Button {
                    refresh()
                } label: {
                    Label("Aktualisieren", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)

                Spacer()

                if controller.bluetoothDeviceAddress != nil {
                    Button("Zurücksetzen", role: .destructive) {
                        controller.bluetoothDeviceAddress = nil
                    }
                    .buttonStyle(.bordered)
                }

                Button("Fertig") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .sheetContainer(width: DS.sheetWidthRegular)
        .onAppear { refresh() }
    }

    private func deviceRow(_ device: BluetoothPairedDevice) -> some View {
        Button {
            controller.bluetoothDeviceAddress = device.id
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 6))
                    .foregroundStyle(device.batteryPercent != nil ? .green : .secondary)

                VStack(alignment: .leading, spacing: 1) {
                    Text(device.name)
                        .font(.subheadline)
                    Text(device.id)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                if let percent = device.batteryPercent {
                    Text("\(percent)%")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                } else {
                    Text("kein Akku-Wert")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                if controller.bluetoothDeviceAddress == device.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func refresh() {
        devices = BluetoothBatteryReader.pairedDevices()
    }
}
