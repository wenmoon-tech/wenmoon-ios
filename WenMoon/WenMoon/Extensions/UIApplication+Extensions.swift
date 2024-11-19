//
//  UIApplication+Extensions.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 19.11.24.
//

import UIKit

extension UIApplication {
    static var rootViewController: UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return nil
        }
        return windowScene.windows.first?.rootViewController
    }
}
