import Flutter
import UIKit
import Security
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Lets iOS wake the app now and then to bring the widgets up to date
    // (performFetch below), besides the pushes.
    application.setMinimumBackgroundFetchInterval(
      UIApplication.backgroundFetchIntervalMinimum)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Native side of `com.dearly.quoteswidget/widget_reload`; also used to ask
  /// Dart for a background sync.
  private var widgetChannel: FlutterMethodChannel?

  /// iOS woke the app in the background (background fetch; the Simulator
  /// also delivers content-available pushes this way). Pull friends' room
  /// edits and redraw the widgets, then tell iOS we are done (≤ 25 s).
  override func application(
    _ application: UIApplication,
    performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    NSLog("DEARLY_NATIVE performFetch")
    guard let channel = widgetChannel else {
      completionHandler(.noData)
      return
    }
    var finished = false
    let finish = {
      if finished { return }
      finished = true
      completionHandler(.newData)
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 25, execute: finish)
    channel.invokeMethod("backgroundSync", arguments: nil) { _ in
      DispatchQueue.main.async(execute: finish)
    }
  }

  /// Logs that a push reached the app; Firebase Messaging handles it.
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    NSLog("DEARLY_NATIVE push state=\(application.applicationState.rawValue) type=\(userInfo["type"] ?? "-")")
    super.application(
      application,
      didReceiveRemoteNotification: userInfo,
      fetchCompletionHandler: completionHandler
    )
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerWidgetReload(engineBridge.pluginRegistry)
  }

  /// Kinds of the Together room-slot widgets ("방 1"…"방 5"), in slot order.
  private static let togetherSlotKinds = [
    "TogetherWidget", "TogetherRoom2", "TogetherRoom3", "TogetherRoom4", "TogetherRoom5",
  ]

  /// `reloadAll`: home_widget only reloads one widget kind at a time, which
  /// leaves the widget gallery (long-press → add widget) on its cached
  /// previews: a favorited or left room kept its old place there. Reloading
  /// every kind also refreshes those gallery previews.
  ///
  /// `appVersion`: CFBundleShortVersionString, for the App Store update check.
  private func registerWidgetReload(_ registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "DearlyWidgetReload") else { return }
    let channel = FlutterMethodChannel(
      name: "com.dearly.quoteswidget/widget_reload",
      binaryMessenger: registrar.messenger()
    )
    widgetChannel = channel
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "reloadAll":
        Self.forgetRemovedSlotWidgets {
          WidgetCenter.shared.reloadAllTimelines()
          result(true)
        }
      case "deviceId":
        result(Self.keychainDeviceId())
      case "appVersion":
        result(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// Stable id of this iPhone for the push token map (fcmDevices). Kept in
  /// the Keychain, which survives deleting and reinstalling the app, so a
  /// reinstall replaces this phone's token instead of adding a second one.
  private static func keychainDeviceId() -> String? {
    let base: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: "com.dearly.quoteswidget.device",
      kSecAttrAccount as String: "deviceId",
    ]
    var query = base
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    var item: CFTypeRef?
    // ThisDeviceOnly: a backup restored onto another iPhone must not bring
    // this id along, or both phones would share one token slot.
    let accessible = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    if SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
      let data = item as? Data, let id = String(data: data, encoding: .utf8), !id.isEmpty
    {
      // Items saved by 1.0.19/1.0.20 used AfterFirstUnlock (backed up).
      SecItemUpdate(
        base as CFDictionary,
        [kSecAttrAccessible as String: accessible] as CFDictionary)
      return id
    }
    let id = UUID().uuidString
    var add = base
    add[kSecValueData as String] = Data(id.utf8)
    add[kSecAttrAccessible as String] = accessible
    return SecItemAdd(add as CFDictionary, nil) == errSecSuccess ? id : nil
  }

  /// A room-slot widget remembers the room it showed so it can say "you left
  /// this room" (TogetherWidget.swift). Once no widget of that slot is on the
  /// home screen, forget it, so a new one starts on the slot's current room.
  private static func forgetRemovedSlotWidgets(then done: @escaping () -> Void) {
    WidgetCenter.shared.getCurrentConfigurations { outcome in
      if case .success(let widgets) = outcome {
        let placed = Set(widgets.map(\.kind))
        let defaults = UserDefaults(suiteName: "group.com.dearly.quoteswidget")
        for (slot, kind) in togetherSlotKinds.enumerated() where !placed.contains(kind) {
          defaults?.removeObject(forKey: "togetherSlotShown_\(slot)")
        }
      }
      DispatchQueue.main.async(execute: done)
    }
  }
}
