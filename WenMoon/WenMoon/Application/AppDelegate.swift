//
//  AppDelegate.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 23.05.23.
//

import UIKit
import FirebaseCore
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {
    // MARK: - Properties
    private var userDefaultsManager: UserDefaultsManager?
    
    // MARK: - Methods
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        userDefaultsManager = UserDefaultsManagerImpl()
        registerForPushNotifications()
        FirebaseApp.configure()
        return true
    }
    
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }
    
    func resetBadgeNumber() {
        UNUserNotificationCenter.current().setBadgeCount(.zero)
    }
    
    // MARK: - Private
    private func registerForPushNotifications() {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.delegate = self
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    private func sendTargetPriceNotification(for coinID: String) {
        let userInfo: [String: Any] = ["coinID": coinID]
        NotificationCenter.default.post(name: .targetPriceReached, object: nil, userInfo: userInfo)
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
        guard (try? userDefaultsManager?.getObject(forKey: "deviceToken", objectType: String.self)) == nil else { return }
        try? userDefaultsManager?.setObject(token, forKey: "deviceToken")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications with error: \(error.localizedDescription)")
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions
        ) -> Void) {
        let userInfo = notification.request.content.userInfo
        if let coinID = userInfo["coinID"] as? String {
            sendTargetPriceNotification(for: coinID)
            resetBadgeNumber()
        }
        completionHandler([.banner, .badge, .sound])
    }
}
