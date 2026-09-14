import Flutter
import Security
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "com.homeplace.mobile/identity",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "publicKey" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let arguments = call.arguments as? [String: Any],
        let serverId = arguments["serverId"] as? String,
        serverId.range(of: "^[0-9a-fA-F-]{36}$", options: .regularExpression) != nil
      else {
        result(FlutterError(code: "invalid_server_id", message: "A valid HomePlace server ID is required.", details: nil))
        return
      }
      do {
        result(try self.publicKey(serverId: serverId))
      } catch {
        result(FlutterError(code: "keychain_unavailable", message: "iOS Keychain is unavailable.", details: nil))
      }
    }
  }

  private func publicKey(serverId: String) throws -> String {
    let tag = Data("com.homeplace.mobile.identity.\(serverId)".utf8)
    let query: [String: Any] = [
      kSecClass as String: kSecClassKey,
      kSecAttrApplicationTag as String: tag,
      kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
      kSecReturnRef as String: true,
    ]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    let privateKey: SecKey
    if status == errSecSuccess, let existing = item as! SecKey? {
      privateKey = existing
    } else if status == errSecItemNotFound {
      let attributes: [String: Any] = [
        kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
        kSecAttrKeySizeInBits as String: 256,
        kSecPrivateKeyAttrs as String: [
          kSecAttrIsPermanent as String: true,
          kSecAttrApplicationTag as String: tag,
          kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ],
      ]
      var error: Unmanaged<CFError>?
      guard let generated = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
        throw error!.takeRetainedValue() as Error
      }
      privateKey = generated
    } else {
      throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
    }
    guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
      throw NSError(domain: NSOSStatusErrorDomain, code: Int(errSecDecode))
    }
    var error: Unmanaged<CFError>?
    guard let data = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
      throw error!.takeRetainedValue() as Error
    }
    return data.base64EncodedString()
  }
}
