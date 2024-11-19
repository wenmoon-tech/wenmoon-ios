//
//  WenMoonApp.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 22.04.23.
//

import SwiftUI
import UserNotifications

@main
struct WenMoonApp: App {
    // MARK: - Properties
    @Environment(\.scenePhase) var scenePhase
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                NotificationCenter.default.post(name: .appDidBecomeActive, object: nil, userInfo: nil)
                appDelegate.resetBadgeNumber()
            }
        }
    }
}
