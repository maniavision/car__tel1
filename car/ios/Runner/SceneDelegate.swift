import Flutter
import UIKit
import StripePayments

class SceneDelegate: FlutterSceneDelegate {
  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    for context in URLContexts {
      StripeAPI.handleURLCallback(with: context.url)
    }
    super.scene(scene, openURLContexts: URLContexts)
  }
}
