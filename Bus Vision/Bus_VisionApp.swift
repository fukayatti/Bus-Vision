//
//  Bus_VisionApp.swift
//  Bus Vision
//
//  Created by 深谷悠喜 on 2025/06/06.
//

import SwiftUI
import ServiceManagement

@main
struct Bus_VisionApp: App {
    @StateObject private var busDataModel = BusDataModel()
    @AppStorage("launchAtLogin") private var launchAtLogin = true
    
    var body: some Scene {
        MenuBarExtra("Bus-Vision", systemImage: "bus.fill") {
            MenuBarView()
                .environmentObject(busDataModel)
        }
        .menuBarExtraStyle(.window)
    }
    
    init() {
        // ログイン時自動起動を設定
        setupLaunchAtLogin()
    }
    
    private func setupLaunchAtLogin() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            }
        } catch {
            print("ログイン時自動起動の設定に失敗しました: \(error)")
        }
    }
}
