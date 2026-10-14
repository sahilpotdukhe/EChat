import AudioToolbox
import UIKit
import Flutter
import awesome_notifications
import firebase_messaging

// Uses the UIScene lifecycle (required from iOS 27): Flutter starts its engine
// and plugins after launch, in didInitializeImplicitFlutterEngine, and the
// window belongs to the scene (FlutterSceneDelegate in Info.plist).
@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var ringTimer: Timer?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Notification buttons (Accept / Reject / Reply) are handled in a
    // separate background engine, which needs the plugin registered too.
    SwiftAwesomeNotificationsPlugin.setPluginRegistrantCallback { registry in
      SwiftAwesomeNotificationsPlugin.register(
        with: registry.registrar(forPlugin: "io.flutter.plugins.awesomenotifications.AwesomeNotificationsPlugin")!)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    setUpRinger(messenger: engineBridge.applicationRegistrar.messenger())

    // awesome_notifications takes over notification taps when it hears "app
    // finished launching". With UIScene plugins are registered only after
    // that announcement, so it would never hear it: no Reply / Mark as read,
    // and the app's launch check for a tapped notification would wait
    // forever. Replay it now that it is listening (firebase_messaging also
    // listens and safely ignores a repeat).
    NotificationCenter.default.post(name: UIApplication.didFinishLaunchingNotification, object: UIApplication.shared)
    // awesome_notifications just made itself the notification handler. Put
    // Firebase back in front; it passes everything that isn't a push on to
    // awesome_notifications, the same arrangement as before UIScene.
    FLTFirebaseMessagingPlugin.configureNotificationCenterDelegate()
  }

  // "echat/ringer": rings (or just vibrates, with the silent switch on)
  // while the incoming call screen is open. See lib/resources/call_ringer.dart.
  private func setUpRinger(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "echat/ringer", binaryMessenger: messenger)
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
