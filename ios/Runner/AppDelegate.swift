import Flutter
import UIKit
import WidgetKit

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
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "reloadAll":
        Self.forgetRemovedSlotWidgets {
          WidgetCenter.shared.reloadAllTimelines()
          result(true)
        }
      case "appVersion":
        result(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
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
