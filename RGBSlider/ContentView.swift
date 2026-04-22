//
//  ContentView.swift
//  RGBSlider
//
//  Created by Antonio Damjanović on 21.04.2026..
//

import SwiftUI

struct ContentView: View {

    @StateObject var bt = BluetoothManager()
    
    @State var red: Double = 0
    @State var green: Double = 0
    @State var blue: Double = 0
    
    var body: some View {
        VStack(spacing: 20) {
            Button("Connect to HC-06 device") {
                bt.connect()
            }
            
            Slider(value: $red, in: 0...255) { Text("R") }
            Slider(value: $green, in: 0...255) { Text("G") }
            Slider(value: $blue, in: 0...255) { Text("B") }
            
            Color(
                red: red / 255.0,
                green: green / 255.0,
                blue: blue / 255.0
            )
            .frame(width: 100, height: 100)
            .cornerRadius(90)
            
            Button("Send color") {
                bt.sendRGB(red: UInt8(red), green: UInt8(green), blue: UInt8(blue))
            }
            
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
