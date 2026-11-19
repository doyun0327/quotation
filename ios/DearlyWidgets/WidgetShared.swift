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

  struct QuoteLine {
    let id: String
    let text: String
    let categoryId: String
    let subCategoryId: String
  }

  /// Quotes change every half hour (:00 / :30).
  static let quoteSlotSeconds: TimeInterval = 30 * 60

  /// Same numbering as SelectionController.slotAt (epoch ms ~/ 30 min).
  static func quoteSlot(at date: Date) -> Int64 {
    Int64((date.timeIntervalSince1970 / quoteSlotSeconds).rounded(.down))
  }

  static func quoteSlotStart(_ slot: Int64) -> Date {
    Date(timeIntervalSince1970: TimeInterval(slot) * quoteSlotSeconds)
  }

  /// The app writes one line per half-hour slot (random across every open
  /// category) from `quoteScheduleStart`; walk it by the clock. Mirrors
  /// Kotlin QuoteSchedule.current.
  static func quoteLine(at date: Date) -> QuoteLine? {
    let lines = quoteSchedule()
    if !lines.isEmpty {
      let slot = quoteSlot(at: date)
      let offset = Int64(string("quoteScheduleStart")).map { slot - $0 } ?? -1
      // Past the end (app not opened for days): keep shuffling the same lines.
      let index = offset >= 0 && offset < Int64(lines.count)
        ? Int(offset)
        : Int(mix(slot) % UInt64(lines.count))
      return lines[index]
    }
    let single = string("quoteText")
    if !single.isEmpty {
      return QuoteLine(
        id: string("quoteId"), text: single,
        categoryId: string("categoryId"), subCategoryId: string("subCategoryId"))
    }
    let pool = quotePool()
    guard !pool.isEmpty else { return nil }
    let slot = quoteSlot(at: date)
    return QuoteLine(
      id: "", text: pool[Int(mix(slot) % UInt64(pool.count))],
      categoryId: "", subCategoryId: "")
  }

  static func quote(at date: Date) -> String {
    quoteLine(at: date)?.text ?? "Dearly"
  }

  private static func quoteSchedule() -> [QuoteLine] {
    let raw = string("quoteSchedule")
    guard let data = raw.data(using: .utf8),
      let decoded = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
    else {
      return []
    }
    return decoded.compactMap { item in
      let text = ((item["t"] as? String) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      guard !text.isEmpty else { return nil }
      return QuoteLine(
        id: (item["i"] as? String) ?? "", text: text,
        categoryId: (item["c"] as? String) ?? "",
        subCategoryId: (item["s"] as? String) ?? "")
    }
  }

  /// Same 32-bit mix as SelectionController._mix.
  private static func mix(_ value: Int64) -> UInt64 {
    var h = (UInt64(bitPattern: value) &* 0x9E37_79B1) & 0xFFFF_FFFF
    h ^= h >> 16
    h = (h &* 0x45D_9F3B) & 0xFFFF_FFFF
    h ^= h >> 16
    h = (h &* 0x45D_9F3B) & 0xFFFF_FFFF
    h ^= h >> 16
    return h
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
  /// Widget chrome. [glass] is for the “투명” theme: clear card pixels sit on
  /// ultraThinMaterial. Other themes use a clear container (opaque PNG fills).
  @ViewBuilder
  func dearlyWidgetBackground(glass: Bool = false) -> some View {
    if #available(iOS 17.0, *) {
      containerBackground(for: .widget) {
        if glass {
          Color.clear.background(.ultraThinMaterial)
        } else {
          Color.clear
        }
      }
    } else {
      background(Color.clear)
    }
  }
}

/// Widget labels in the app's language (saved by the app as "appLanguage"),
/// falling back to the phone's language.
enum WidgetText {
  static var language: String {
    let saved = DearlyWidgetStore.string("appLanguage")
    if ["ko", "en", "ja"].contains(saved) { return saved }
    let phone = Locale.preferredLanguages.first?.prefix(2) ?? "ko"
    return ["ko", "en", "ja"].contains(String(phone)) ? String(phone) : "en"
  }

  static func pick(_ ko: String, _ en: String, _ ja: String) -> String {
    switch language {
    case "en": return en
    case "ja": return ja
    default: return ko
    }
  }
}
