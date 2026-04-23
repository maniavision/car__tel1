import Flutter
import UIKit
import StripePayments

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  // Expose the active scene's window so stripe_ios can find the root view controller.
  // With scene-based lifecycle the AppDelegate has no window by default, causing
  // UIApplication.shared.delegate?.window to return nil in the stripe_ios plugin.
  override var window: UIWindow? {
    get {
      return UIApplication.shared.connectedScenes
        .filter { $0.activationState == .foregroundActive }
        .compactMap { $0 as? UIWindowScene }
        .compactMap { $0.windows.first(where: { $0.isKeyWindow }) }
        .first
    }
    set {}
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    StripeAPI.handleURLCallback(with: url)
    return super.application(app, open: url, options: options)
  }
}
