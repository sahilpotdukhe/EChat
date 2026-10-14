import AudioToolbox
import UIKit
import Flutter
import awesome_notifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var ringTimer: Timer?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // Notification buttons (Accept / Reject / Reply) are handled in a
    // separate background engine, which needs the plugin registered too.
    SwiftAwesomeNotificationsPlugin.setPluginRegistrantCallback { registry in
      SwiftAwesomeNotificationsPlugin.register(
        with: registry.registrar(forPlugin: "io.flutter.plugins.awesomenotifications.AwesomeNotificationsPlugin")!)
    }
    setUpRinger()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // "echat/ringer": rings (or just vibrates, with the silent switch on)
  // while the incoming call screen is open. See lib/resources/call_ringer.dart.
  private func setUpRinger() {
    guard let registrar = self.registrar(forPlugin: "EChatRinger") else { return }
    let channel = FlutterMethodChannel(name: "echat/ringer", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "start":
        self?.ringTimer?.invalidate()
        let ring = { AudioServicesPlayAlertSound(SystemSoundID(1151)) }
        ring()
        self?.ringTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in ring() }
        result(nil)
      case "stop":
        self?.ringTimer?.invalidate()
        self?.ringTimer = nil
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
