import UIKit
import UserNotifications
import WidgetKit

/// Runs for every Together notice before iOS shows it, even when the app is
/// not running. A friend's widget edit carries the id of the new widget
/// picture (`cardId`, a `widget_cards` document in Firestore). It is saved in
/// the App Group and the widgets redraw at once, so the home screen changes
/// without opening the notice.
class NotificationService: UNNotificationServiceExtension {
  private static let appGroupId = "group.com.dearly.quoteswidget"
  // Public Firebase config (same values as lib/firebase_options.dart, iOS).
  private static let projectId = "dearly-cf730"
  private static let apiKey = "AIzaSyAuUK41NsVEe6cMHZe4EWxauzgmtBmQftw"
  private static let appBundleId = "com.dearly.quoteswidget"

  private var contentHandler: ((UNNotificationContent) -> Void)?
  private var content: UNMutableNotificationContent?

  override func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
  ) {
    let content =
      (request.content.mutableCopy() as? UNMutableNotificationContent)
      ?? UNMutableNotificationContent()
    self.contentHandler = contentHandler
    self.content = content

    let info = request.content.userInfo
    guard let roomId = info["roomId"] as? String, !roomId.isEmpty,
      let cardId = info["cardId"] as? String, !cardId.isEmpty,
      let url = Self.cardURL(cardId)
    else {
      finish()
      return
    }
    // This phone's clock, like the time the app saves with its own card
    // (togetherSpecAt): the server time could be ahead or behind it.
    let cardAt = Int(Date().timeIntervalSince1970 * 1000)

    var fetch = URLRequest(url: url)
    fetch.cachePolicy = .reloadIgnoringLocalCacheData
    fetch.timeoutInterval = 20
    // The iOS API key may be limited to the app's bundle id.
    fetch.setValue(Self.appBundleId, forHTTPHeaderField: "X-Ios-Bundle-Identifier")
    URLSession.shared.dataTask(with: fetch) { [weak self] data, response, _ in
      if let data,
        (response as? HTTPURLResponse)?.statusCode == 200,
        let png = Self.cardBytes(from: data),
        UIImage(data: png) != nil
      {
        Self.save(card: png, roomId: roomId, at: cardAt)
        WidgetCenter.shared.reloadAllTimelines()
      } else {
        NSLog("DEARLY_NSE card fetch failed: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
      }
      self?.finish()
    }.resume()
  }

  override func serviceExtensionTimeWillExpire() {
    finish()
  }

  private func finish() {
    guard let handler = contentHandler, let content else { return }
    contentHandler = nil
    handler(content)
  }

  /// Firestore REST: one document, only its `card` field.
  private static func cardURL(_ cardId: String) -> URL? {
    guard cardId.allSatisfy({ $0.isHexDigit }) else { return nil }
    var parts = URLComponents()
    parts.scheme = "https"
    parts.host = "firestore.googleapis.com"
    parts.path =
      "/v1/projects/\(projectId)/databases/(default)/documents/widget_cards/\(cardId)"
    parts.queryItems = [
      URLQueryItem(name: "key", value: apiKey),
      URLQueryItem(name: "mask.fieldPaths", value: "card"),
    ]
    return parts.url
  }

  /// `{"fields": {"card": {"bytesValue": "<base64>"}}}` → PNG bytes.
  private static func cardBytes(from json: Data) -> Data? {
    guard let doc = try? JSONSerialization.jsonObject(with: json) as? [String: Any],
      let fields = doc["fields"] as? [String: Any],
      let card = fields["card"] as? [String: Any],
      let base64 = card["bytesValue"] as? String
    else { return nil }
    return Data(base64Encoded: base64)
  }

  /// Same room key as the app (base64url of the room id, no padding).
  private static func roomKey(_ roomId: String) -> String {
    Data(roomId.utf8).base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }

  /// `togetherRemoteCard_{key}`: file path; `togetherRemoteCardAt_{key}`:
  /// when this phone received it (ms, device clock). TogetherWidget uses the picture while it is newer than
  /// the card the app drew itself.
  private static func save(card: Data, roomId: String, at: Int) {
    guard
      let dir = FileManager.default
        .containerURL(forSecurityApplicationGroupIdentifier: appGroupId)?
        .appendingPathComponent("remote_cards", isDirectory: true)
    else { return }
    let key = roomKey(roomId)
    do {
      try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
      let file = dir.appendingPathComponent("\(key).png")
      try card.write(to: file, options: .atomic)
      let defaults = UserDefaults(suiteName: appGroupId)
      defaults?.set(file.path, forKey: "togetherRemoteCard_\(key)")
      defaults?.set(at, forKey: "togetherRemoteCardAt_\(key)")
    } catch {
      NSLog("DEARLY_NSE save failed: \(error)")
    }
  }
}
