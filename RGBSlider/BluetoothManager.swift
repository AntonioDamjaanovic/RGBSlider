//
//  BluetoothManager.swift
//  RGBSlider
//
//  Created by Antonio Damjanović on 21.04.2026..
//

import Foundation
import IOBluetooth
import Combine

class BluetoothManager: NSObject, ObservableObject, IOBluetoothRFCOMMChannelDelegate {

    private var rfcommChannel: IOBluetoothRFCOMMChannel?
    
    @Published var isConnected = false

    func connect() {
        guard rfcommChannel == nil else {
            print("Already connected or connecting")
            return
        }

        guard let device = findHC06() else {
            print("HC-06 not found. Pair it in System Settings first.")
            return
        }

        var channel: IOBluetoothRFCOMMChannel?
        let result = device.openRFCOMMChannelAsync(
            &channel,
            withChannelID: 1,
            delegate: self
        )

        if result == kIOReturnSuccess {
            rfcommChannel = channel
            print("Opening RFCOMM channel to \(device.name ?? "HC-06")…")
        } else {
            print("Failed to start channel open: \(result)")
            rfcommChannel = nil
        }
    }

    func disconnect() {
        rfcommChannel?.close()
        rfcommChannel = nil
        isConnected = false
    }

    func sendRGB(red: UInt8, green: UInt8, blue: UInt8) {
        guard let channel = rfcommChannel, isConnected else {
            print("Not connected")
            return
        }

        let message = "R\(red)G\(green)B\(blue)\n"
        print("Sending: \(message.trimmingCharacters(in: .newlines))")

        DispatchQueue.global(qos: .userInitiated).async {
            var bytes = Array(message.utf8)
            let result = channel.writeSync(&bytes, length: UInt16(bytes.count))

            DispatchQueue.main.async {
                if result == kIOReturnSuccess {
                    print("Sent OK")
                } else {
                    print("Send failed: \(result)")
                }
            }
        }
    }

    private func findHC06() -> IOBluetoothDevice? {
        guard let devices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else {
            return nil
        }
        return devices.first { $0.name?.contains("BT04") == true }
    }

    // MARK: - Delegate

    func rfcommChannelOpenComplete(
        _ rfcommChannel: IOBluetoothRFCOMMChannel!,
        status error: IOReturn
    ) {
        DispatchQueue.main.async {
            if error == kIOReturnSuccess {
                self.isConnected = true
                print("Connected to HC-06 ✓")
            } else {
                print("Connection failed: \(error)")
                self.rfcommChannel = nil
                self.isConnected = false
            }
        }
    }

    func rfcommChannelData(
        _ rfcommChannel: IOBluetoothRFCOMMChannel!,
        data dataPointer: UnsafeMutableRawPointer!,
        length dataLength: Int
    ) {
        let data = Data(bytes: dataPointer, count: dataLength)
        let message = String(data: data, encoding: .utf8) ?? "<non-utf8>"
        print("Received: \(message)")
    }

    func rfcommChannelClosed(_ rfcommChannel: IOBluetoothRFCOMMChannel!) {
        DispatchQueue.main.async {
            print("RFCOMM channel closed")
            self.rfcommChannel = nil
            self.isConnected = false
        }
    }
}
