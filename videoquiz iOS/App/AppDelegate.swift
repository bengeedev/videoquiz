//
//  AppDelegate.swift
//  VideoQuiz iOS
//
//  Created by Benjamin Gievis
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        // Instantiate MenuViewController as the root view controller
        let menuVC = MenuViewController()
        window?.rootViewController = UINavigationController(rootViewController: menuVC)
        window?.makeKeyAndVisible()
        return true
    }
}
