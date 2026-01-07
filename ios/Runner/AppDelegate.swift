import UIKit
import Flutter
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // 1. Google Maps Setup
    GMSServices.provideAPIKey("AIzaSyCBtpQ4Vn3Ey6vRbZRpWKC0oRH3Ac7T2h4")
    
    // 2. Register Flutter Plugins
    GeneratedPluginRegistrant.register(with: self)

    // 🟢 3. THE NOTIFICATION FIX
    // This explicitly tells iOS: "Let the Flutter App handle the notifications, even in the foreground."
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
