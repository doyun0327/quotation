import SwiftUI
import UIKit
import WidgetKit

enum DearlyWidgetStore {
  static let appGroupId = "group.com.dearly.quoteswidget"

  static var defaults: UserDefaults {
    UserDefaults(suiteName: appGroupId) ?? .standard
  }

  static func string(_ key: String, fallback: String = "") -> String {
    let raw = defaults.string(forKey: key)?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let raw, !raw.isEmpty { return raw }
    let flutter = defaults.string(forKey: "flutter.\(key)")?
      .trimmingCharacters(in: .whitespacesAndNewlines)
    return flutter ?? fallback
  }

  static func color(_ key: String, fallback: UIColor) -> Color {
    Color(uiColor: uiColor(key, fallback: fallback))
  }

  static func color(hex raw: String, fallback: UIColor) -> Color {
    Color(uiColor: parseHex(raw, fallback: fallback))
  }

  static func uiColor(_ key: String, fallback: UIColor) -> UIColor {
    parseHex(string(key), fallback: fallback)
  }

  static func parseHex(_ raw: String, fallback: UIColor) -> UIColor {
    var hex = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    if hex.hasPrefix("#") { hex.removeFirst() }
    guard !hex.isEmpty, let value = UInt64(hex, radix: 16) else { return fallback }
    let hasAlpha = hex.count > 6
    let a = hasAlpha ? CGFloat((value >> 24) & 0xFF) / 255 : 1
    let r = CGFloat((value >> 16) & 0xFF) / 255
    let g = CGFloat((value >> 8) & 0xFF) / 255
    let b = CGFloat(value & 0xFF) / 255
    return UIColor(red: r, green: g, blue: b, alpha: a)
  }

  static func int(_ key: String, fallback: Int = 0) -> Int {
    if let number = defaults.object(forKey: key) as? NSNumber {
      return number.intValue
    }
    if let number = defaults.object(forKey: "flutter.\(key)") as? NSNumber {
      return number.intValue
    }
    if let raw = defaults.string(forKey: key), let value = Int(raw) {
      return value
    }
    if let raw = defaults.string(forKey: "flutter.\(key)"), let value = Int(raw) {
      return value
    }
    return fallback
  }

  static func image(forKey key: String) -> UIImage? {
    let path = string(key)
    guard !path.isEmpty, FileManager.default.fileExists(atPath: path) else {
      return nil
    }
    return UIImage(contentsOfFile: path)
  }

  static func quotePool() -> [String] {
    let raw = string("quotePool")
    guard let data = raw.data(using: .utf8),
      let decoded = try? JSONSerialization.jsonObject(with: data) as? [Any]
    else {
      let single = string("quoteText")
      return single.isEmpty ? [] : [single]
    }
    let texts = decoded.compactMap { ($0 as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
    if texts.isEmpty {
      let single = string("quoteText")
      return single.isEmpty ? [] : [single]
    }
    return texts
  }

  static func quote(at date: Date) -> String {
    let pool = quotePool()
    guard !pool.isEmpty else {
      return "Dearly"
    }
    let hour = Calendar.current.component(.hour, from: date)
    let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
    return pool[(day * 24 + hour) % pool.count]
  }

  static func homeDateLabel(_ date: Date = Date()) -> String {
    let cal = Calendar.current
    let y = cal.component(.year, from: date)
    let m = cal.component(.month, from: date)
    let d = cal.component(.day, from: date)
    return "\(y). \(m). \(d)"
  }

  static func togetherChars() -> [[String: Any]] {
    let roomId = string("ddayRoomId")
    if !roomId.isEmpty,
      let roomsData = string("ddayRoomsJson").data(using: .utf8),
      let rooms = try? JSONSerialization.jsonObject(with: roomsData) as? [String: Any],
      let room = rooms[roomId] as? [String: Any],
      let chars = room["chars"] as? [[String: Any]]
    {
      return chars
    }
    return []
  }

  static func togetherLabel() -> String {
    let roomId = string("ddayRoomId")
    if !roomId.isEmpty,
      let roomsData = string("ddayRoomsJson").data(using: .utf8),
      let rooms = try? JSONSerialization.jsonObject(with: roomsData) as? [String: Any],
      let room = rooms[roomId] as? [String: Any],
      let label = room["label"] as? String,
      !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    {
      return label
    }
    return string("ddayLabel")
  }

  static func togetherTextColor() -> Color {
    let fallback = UIColor(red: 0.95, green: 0.42, blue: 0.54, alpha: 1)
    let roomId = string("ddayRoomId")
    if !roomId.isEmpty,
      let roomsData = string("ddayRoomsJson").data(using: .utf8),
      let rooms = try? JSONSerialization.jsonObject(with: roomsData) as? [String: Any],
      let room = rooms[roomId] as? [String: Any],
      let hex = room["textColor"] as? String,
      !hex.isEmpty
    {
      return color(hex: hex, fallback: fallback)
    }
    return color("ddayTextColor", fallback: fallback)
  }

  static func characterImage(id: String) -> UIImage? {
    if let image = image(forKey: "char_\(id)") { return image }
    if id == string("characterId") { return image(forKey: "characterImage") }
    return image(forKey: "characterImage")
  }
}

extension View {
  /// Clear system widget chrome so wallpaper shows in leftover margins.
  @ViewBuilder
  func dearlyWidgetBackground() -> some View {
    if #available(iOS 17.0, *) {
      containerBackground(for: .widget) {
        Color.clear
      }
    } else {
      background(Color.clear)
    }
  }
}
