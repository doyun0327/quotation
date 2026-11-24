import AppIntents
import CoreText
import ImageIO
import SwiftUI
import UIKit
import WidgetKit

/// One row of the `ddayRoomIndex` list written by HomeWidgetSync.
struct TogetherRoom {
  let id: String
  let title: String
  let imageKey: String
  /// Native draw commands (TogetherCardRenderer); preferred over the PNG.
  let specKey: String
  /// “투명” theme: card PNG is clear; chrome uses ultraThinMaterial.
  let useGlass: Bool
  /// Pastel themes: base color (hex) shown when no home screenshot is registered.
  var tint: String = ""

  static func all() -> [TogetherRoom] {
    guard let data = DearlyWidgetStore.string("ddayRoomIndex").data(using: .utf8),
      let decoded = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
    else {
      return []
    }
    return decoded.compactMap { row in
      guard let id = row["id"] as? String, !id.isEmpty,
        let imageKey = row["imageKey"] as? String, !imageKey.isEmpty
      else {
        return nil
      }
      let glass = (row["glass"] as? String) == "1" || (row["glass"] as? Bool) == true
      return TogetherRoom(
        id: id,
        title: row["title"] as? String ?? "",
        imageKey: imageKey,
        specKey: row["specKey"] as? String ?? "",
        useGlass: glass,
        tint: row["tint"] as? String ?? ""
      )
    }
  }

  /// Rooms I left on this phone (written by the app as "ddayLeftRoomIds").
  static func leftIds() -> Set<String> {
    guard let data = DearlyWidgetStore.string("ddayLeftRoomIds").data(using: .utf8),
      let ids = try? JSONSerialization.jsonObject(with: data) as? [String]
    else {
      return []
    }
    return Set(ids)
  }

  /// The card to show: drawn natively from the latest spec, else the PNG
  /// the app drew last time it was open.
  func card() -> UIImage? {
    // A friend's edit delivered with its picture (notification service
    // extension) wins while it is newer than the card this phone drew.
    let key = imageKey.replacingOccurrences(of: "togetherCard_", with: "")
    let remoteAt = DearlyWidgetStore.int("togetherRemoteCardAt_\(key)")
    if remoteAt > DearlyWidgetStore.int("togetherSpecAt_\(key)"),
      let remote = DearlyWidgetStore.image(forKey: "togetherRemoteCard_\(key)")
    {
      return remote
    }
    if !specKey.isEmpty {
      let spec = DearlyWidgetStore.string(specKey)
      if !spec.isEmpty, let image = TogetherCardRenderer.render(json: spec) {
        return image
      }
    }
    return DearlyWidgetStore.image(forKey: imageKey)
  }
}

struct TogetherRoomEntity: AppEntity {
  static var typeDisplayRepresentation: TypeDisplayRepresentation = "함께 방"
  static var defaultQuery = TogetherRoomQuery()

  let id: String
  let title: String

  init(_ room: TogetherRoom) {
    id = room.id
    title = room.title.isEmpty ? WidgetText.pick("함께", "Together", "一緒") : room.title
  }

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(title)")
  }
}

struct TogetherRoomQuery: EntityQuery {
  func entities(for identifiers: [TogetherRoomEntity.ID]) async throws -> [TogetherRoomEntity] {
    TogetherRoom.all().filter { identifiers.contains($0.id) }.map(TogetherRoomEntity.init)
  }

  func suggestedEntities() async throws -> [TogetherRoomEntity] {
    TogetherRoom.all().map(TogetherRoomEntity.init)
  }
}

struct SelectTogetherRoomIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource = "방 선택"
  static var description = IntentDescription("이 위젯에 보여 줄 방을 선택합니다.")

  @Parameter(title: "방")
  var room: TogetherRoomEntity?
}

struct TogetherEntry: TimelineEntry {
  let date: Date
  let card: UIImage?
  let roomId: String
  let useGlass: Bool
  var tint: String = ""
  /// Room-slot widget whose slot has no room yet: show a short hint.
  var emptySlot: Int? = nil
  /// This widget's room was left: ask the user to remove the widget.
  var leftRoom = false
}

/// The "같이" gallery pages (one widget kind per page) and which room each
/// one shows. Every room shows on exactly one page, in the app's room order;
/// a widget already on the home screen keeps the room it showed, so leaving
/// or reordering rooms never fills one page with a room another page has.
enum TogetherSlots {
  static let count = 5

  static func kind(_ slot: Int) -> String {
    slot == 0 ? "TogetherWidget" : "TogetherRoom" + String(slot + 1)
  }

  static func memoryKey(_ slot: Int) -> String { "togetherSlotShown_\(slot)" }

  /// Kinds with a widget on the home screen (nil: could not be read).
  static func placedKinds() async -> Set<String>? {
    let infos: [WidgetInfo]? = await withCheckedContinuation { done in
      WidgetCenter.shared.getCurrentConfigurations { result in
        done.resume(returning: try? result.get())
      }
    }
    guard let infos else { return nil }
    return Set(infos.map(\.kind))
  }

  /// A page with no widget on the home screen has nothing to remember, so a
  /// deleted widget does not keep a room claimed. [own]: the page of the
  /// widget being drawn (it is placed even if the system list lags).
  static func forgetUnplaced(keeping own: Int?) async {
    guard let placed = await placedKinds() else { return }
    for slot in 0..<count where slot != own && !placed.contains(kind(slot)) {
      DearlyWidgetStore.defaults.removeObject(forKey: memoryKey(slot))
    }
  }

  /// The room [slot] shows. Pages whose widget remembers a live room keep
  /// it; the other pages take the remaining rooms in order, one each, and
  /// stay empty when rooms run out. The gallery preview and a widget just
  /// added use this same rule, so they always match.
  static func room(for slot: Int, in rooms: [TogetherRoom]) -> TogetherRoom? {
    let ids = Set(rooms.map(\.id))
    var remembered: [Int: String] = [:]
    for k in 0..<count {
      let id = DearlyWidgetStore.defaults.string(forKey: memoryKey(k)) ?? ""
      if !id.isEmpty, ids.contains(id) { remembered[k] = id }
    }
    if let id = remembered[slot] { return rooms.first { $0.id == id } }
    let claimed = Set(remembered.values)
    let free = rooms.filter { !claimed.contains($0.id) }
    let needing = (0..<count).filter { remembered[$0] == nil }
    guard let rank = needing.firstIndex(of: slot), rank < free.count else {
      return nil
    }
    return free[rank]
  }
}

struct TogetherProvider: AppIntentTimelineProvider {
  /// Room-slot widgets (gallery pages) show TogetherSlots.room(for:). Nil is
  /// the original widget (app's default room).
  var slot: Int? = nil

  func placeholder(in context: Context) -> TogetherEntry {
    TogetherEntry(date: Date(), card: nil, roomId: "", useGlass: false)
  }

  func snapshot(for configuration: SelectTogetherRoomIntent, in context: Context) async -> TogetherEntry {
    await TogetherSlots.forgetUnplaced(keeping: context.isPreview ? nil : slot)
    return makeEntry(for: configuration, preview: context.isPreview)
  }

  func timeline(for configuration: SelectTogetherRoomIntent, in context: Context) async -> Timeline<TogetherEntry> {
    await TogetherSlots.forgetUnplaced(keeping: context.isPreview ? nil : slot)
    let entry = makeEntry(for: configuration, preview: context.isPreview)
    let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
    return Timeline(entries: [entry], policy: .after(next))
  }

  /// A widget with no room picked, or whose room was deleted, shows the
  /// app's default room; the card and the tap target always stay paired.
  ///
  /// A widget whose room I left says so instead of switching to another
  /// room. The gallery preview ([preview]) always shows the slot's room now.
  private func makeEntry(for configuration: SelectTogetherRoomIntent, preview: Bool = false) -> TogetherEntry {
    let left = TogetherRoom.leftIds()
    if let selectedId = configuration.room?.id, left.contains(selectedId) {
      return Self.leftEntry
    }
    // Room-slot widget on the home screen: it keeps the room it first
    // showed, and says so when that room was left.
    if !preview, configuration.room == nil, let slot {
      let shown = DearlyWidgetStore.defaults.string(forKey: TogetherSlots.memoryKey(slot)) ?? ""
      if !shown.isEmpty, left.contains(shown) { return Self.leftEntry }
    }
    let entry = makeRoomEntry(for: configuration)
    if !preview, configuration.room == nil, let slot, !entry.roomId.isEmpty {
      DearlyWidgetStore.defaults.set(entry.roomId, forKey: TogetherSlots.memoryKey(slot))
    }
    return entry
  }

  private static var leftEntry: TogetherEntry {
    TogetherEntry(date: Date(), card: nil, roomId: "", useGlass: false, leftRoom: true)
  }

  private func makeRoomEntry(for configuration: SelectTogetherRoomIntent) -> TogetherEntry {
    if let selectedId = configuration.room?.id,
      let room = TogetherRoom.all().first(where: { $0.id == selectedId }),
      let card = room.card()
    {
      return TogetherEntry(
        date: Date(),
        card: card,
        roomId: room.id,
        useGlass: room.useGlass,
        tint: room.tint
      )
    }
    // Room-slot widget: its page's room (see TogetherSlots), until one is
    // picked in Edit Widget.
    if let slot {
      let rooms = TogetherRoom.all()
      if let room = TogetherSlots.room(for: slot, in: rooms),
        let card = room.card()
      {
        return TogetherEntry(
          date: Date(),
          card: card,
          roomId: room.id,
          useGlass: room.useGlass,
          tint: room.tint
        )
      }
      return TogetherEntry(
        date: Date(), card: nil, roomId: "", useGlass: false, emptySlot: slot)
    }
    let theme = DearlyWidgetStore.string("ddayBgTheme")
    let glass = theme.isEmpty || theme == "none"
    return TogetherEntry(
      date: Date(),
      card: DearlyWidgetStore.image(forKey: "togetherCardImage"),
      roomId: DearlyWidgetStore.string("ddayRoomId"),
      useGlass: glass,
      tint: DearlyWidgetStore.string("ddayBgTint")
    )
  }
}

/// Card is rendered at the systemMedium ratio (2.14:1, shared with Galaxy),
/// so it fills the widget; fill trims the ~1% per-device ratio difference.
struct TogetherWidgetView: View {
  var entry: TogetherEntry

  var body: some View {
    // The registered home photo is the base layer under every theme: the
    // pastel themes are mostly see-through decorations drawn on top of it.
    // "투명" (useGlass) is just this layer with no theme picture.
    let wallpaper = Self.fakeWallpaper(roomId: entry.roomId)
    GeometryReader { geo in
      ZStack {
        // Widgy-style: cropped home screenshot + blur under a clear card.
        if let wallpaper {
          Image(uiImage: wallpaper)
            .resizable()
            .scaledToFill()
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
            .blur(radius: 12)
          Color.white.opacity(0.16)
        } else if let tint = Self.tintColor(entry.tint) {
          // No home screenshot: a soft base in the theme's own color, not
          // the white glass plate.
          tint
        }
        if entry.leftRoom {
          VStack(spacing: 6) {
            Text(WidgetText.pick("나간 방입니다.", "You left this room.", "退出したルームです。"))
              .font(.system(size: 15, weight: .bold))
            Text(WidgetText.pick(
              "위젯을 삭제해 주세요!",
              "Please remove this widget!",
              "ウィジェットを削除してください！"))
              .font(.system(size: 12))
              .foregroundStyle(.secondary)
          }
          .multilineTextAlignment(.center)
          .padding()
        } else if let slot = entry.emptySlot {
          VStack(spacing: 6) {
            Text(WidgetText.pick("방 ", "Room ", "ルーム") + String(slot + 1))
              .font(.system(size: 15, weight: .bold))
            Text(WidgetText.pick(
              "Dearly에서 방을 만들면 여기에 보여요",
              "Make a room in Dearly to show it here",
              "Dearlyでルームを作るとここに表示されます"))
              .font(.system(size: 12))
              .foregroundStyle(.secondary)
          }
          .multilineTextAlignment(.center)
          .padding()
        } else if let card = entry.card {
          Image(uiImage: card)
            .resizable()
            .interpolation(.high)
            .scaledToFill()
            .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
            .clipped()
        }
      }
      .frame(width: geo.size.width, height: geo.size.height)
    }
    // Screenshot blur already fills the cell. Without a registered photo,
    // every theme gets system glass: a clear container would show iOS's
    // white plate through the see-through parts of the theme.
    .dearlyWidgetBackground(glass: wallpaper == nil && Self.tintColor(entry.tint) == nil)
    .widgetURL(launchURL)
  }

  private static func tintColor(_ hex: String) -> Color? {
    guard hex.count == 6, let value = UInt32(hex, radix: 16) else { return nil }
    return Color(
      red: Double((value >> 16) & 0xFF) / 255,
      green: Double((value >> 8) & 0xFF) / 255,
      blue: Double(value & 0xFF) / 255)
  }

  /// App-registered home screenshot crop (App Group), top or middle slot.
  /// Each room has its own photo (IosFakeWallpaper.keyForRoom); a room
  /// without one uses the shared photo registered before that.
  private static func fakeWallpaper(roomId: String) -> UIImage? {
    if !roomId.isEmpty {
      let key = roomKey(roomId)
      if let own = wallpaper(
        slotKey: "togetherFakeWallpaperSlot_\(key)",
        top: "togetherFakeWallpaperTop_\(key)",
        mid: "togetherFakeWallpaperMid_\(key)")
      {
        return own
      }
    }
    return wallpaper(
      slotKey: "togetherFakeWallpaperSlot",
      top: "togetherFakeWallpaperTop",
      mid: "togetherFakeWallpaperMid")
  }

  private static func wallpaper(slotKey: String, top: String, mid: String) -> UIImage? {
    let order = DearlyWidgetStore.string(slotKey) == "mid" ? [mid, top] : [top, mid]
    for key in order {
      if let image = DearlyWidgetStore.image(forKey: key) { return image }
    }
    return nil
  }

  /// base64url of the room id without padding, as Dart's
  /// base64Url.encode(utf8.encode(id)).replaceAll('=', '').
  private static func roomKey(_ roomId: String) -> String {
    Data(roomId.utf8).base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }

  private var launchURL: URL? {
    var components = URLComponents(string: "dearly://together")
    // home_widget only reports taps on URLs carrying a `homeWidget` query item.
    var items = [URLQueryItem(name: "homeWidget", value: nil)]
    if !entry.roomId.isEmpty {
      items.append(URLQueryItem(name: "room", value: entry.roomId))
    }
    components?.queryItems = items
    return components?.url
  }
}

/// Gallery pages "방 1"…"방 5": each opens on that room of the list, so the
/// iPhone widget gallery starts with the user's shared rooms. Long-press →
/// Edit Widget still lets any page switch to any room.
func togetherRoomSlotConfiguration(_ slot: Int) -> some WidgetConfiguration {
  // Plain Strings: an interpolated literal becomes formatted text, which
  // WidgetKit rejects for the name/description and crashes the extension.
  let number = String(slot + 1)
  let name: String = WidgetText.pick(
    "같이", "Together", "一緒")
  let about: String = WidgetText.pick(
    "함께하는 방을 보여 줍니다. 길게 눌러 다른 방으로 바꿀 수 있어요.",
    "Shows a room you share. Long-press to switch to another room.",
    "一緒のルームを表示します。長押しで別のルームに変更できます。")
  // Slot 0 keeps the original "TogetherWidget" kind so widgets already on
  // home screens keep working (and the gallery has no duplicate page).
  return AppIntentConfiguration(
    kind: slot == 0 ? "TogetherWidget" : "TogetherRoom" + number,
    intent: SelectTogetherRoomIntent.self,
    provider: TogetherProvider(slot: slot)
  ) { entry in
    TogetherWidgetView(entry: entry)
  }
  .configurationDisplayName(name)
  .description(about)
  .supportedFamilies([.systemMedium])
  .contentMarginsDisabled()
}

// WidgetKit needs a no-argument init per widget, hence one type per slot.
struct TogetherRoom1Widget: Widget {
  var body: some WidgetConfiguration { togetherRoomSlotConfiguration(0) }
}
struct TogetherRoom2Widget: Widget {
  var body: some WidgetConfiguration { togetherRoomSlotConfiguration(1) }
}
struct TogetherRoom3Widget: Widget {
  var body: some WidgetConfiguration { togetherRoomSlotConfiguration(2) }
}
struct TogetherRoom4Widget: Widget {
  var body: some WidgetConfiguration { togetherRoomSlotConfiguration(3) }
}
struct TogetherRoom5Widget: Widget {
  var body: some WidgetConfiguration { togetherRoomSlotConfiguration(4) }
}

// MARK: - Native card drawing

/// Draws a Together card from the draw commands Flutter writes
/// (lib/data/together_ios_card_spec.dart). Flutter cannot draw while the app
/// is in the background (iOS turns the GPU off), so drawing here lets a
/// friend's edit, delivered by a background push, reach the widget right
/// away. CPU only: Core Graphics + Core Text.
enum TogetherCardRenderer {
  static func render(json: String) -> UIImage? {
    guard let data = json.data(using: .utf8),
      let spec = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
      let width = num(spec["w"]), let height = num(spec["h"]), width > 1, height > 1
    else { return nil }
    let size = CGSize(width: width, height: height)
    let scale: CGFloat = 3
    let format = UIGraphicsImageRendererFormat()
    format.scale = scale
    format.opaque = false
    let pixel = (spec["pixel"] as? Bool) ?? false

    return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
      let cg = ctx.cgContext
      cg.clip(to: CGRect(origin: .zero, size: size))

      // Background.
      if let bg = spec["bg"] as? [String: Any], let file = bg["file"] as? String,
        let image = loadImage(file, maxPixel: max(width, height) * scale)
      {
        let rect = CGRect(origin: .zero, size: size)
        if (bg["fit"] as? String) == "cover" {
          drawImage(image, in: rect, mode: .cover, sharp: false, cg: cg)
        } else {
          drawImage(image, in: rect, mode: .fill, sharp: pixel, cg: cg)
        }
      }

      // Cheer text.
      if let label = spec["label"] as? [String: Any] {
        drawLabel(label, cg: cg)
      }

      // Characters.
      for char in (spec["chars"] as? [[String: Any]]) ?? [] {
        guard let file = char["file"] as? String,
          let x = num(char["x"]), let y = num(char["y"]), let w = num(char["w"]), let h = num(char["h"]),
          let image = loadImage(file, maxPixel: max(w, h) * scale)
        else { continue }
        let rect = CGRect(x: x, y: y, width: w, height: h)
        withRotation(num(char["rot"]) ?? 0, around: CGPoint(x: rect.midX, y: rect.midY), cg: cg) {
          drawImage(image, in: rect, mode: .contain, sharp: (char["sharp"] as? Bool) ?? false, cg: cg)
        }
      }

      // Stickers: pictures kept in their own shape, turned around the center.
      for sticker in (spec["stickers"] as? [[String: Any]]) ?? [] {
        guard let file = sticker["file"] as? String,
          let x = num(sticker["x"]), let y = num(sticker["y"]),
          let w = num(sticker["w"]), let h = num(sticker["h"]),
          let image = loadImage(file, maxPixel: max(w, h) * scale)
        else { continue }
        let rect = CGRect(x: x, y: y, width: w, height: h)
        withRotation(num(sticker["rot"]) ?? 0, around: CGPoint(x: rect.midX, y: rect.midY), cg: cg) {
          drawImage(image, in: rect, mode: .fill, sharp: pixel, cg: cg)
        }
      }

      // Speech bubbles.
      if let bubbles = spec["bubbles"] as? [String: Any] {
        drawBubbles(bubbles, cg: cg)
      }
    }
  }

  // MARK: Text

  private static func drawLabel(_ label: [String: Any], cg: CGContext) {
    guard let text = label["text"] as? String, !text.trimmingCharacters(in: .whitespaces).isEmpty,
      let cx = num(label["cx"]), let cy = num(label["cy"]),
      let w = num(label["w"]), let h = num(label["h"]), let size = num(label["size"]), size > 0
    else { return }
    let weight = Int(num(label["weight"]) ?? 400)
    let font = font(file: label["font"] as? String, size: size, weight: weight)
    let lineHeight = (num(label["lineHeight"]) ?? 1.2) * size
    let attributed = attributedText(
      text, font: font, color: color(label["color"]), lineHeight: lineHeight,
      kern: num(label["kern"]) ?? 0, center: true,
      fakeBold: weight >= 700 && (label["font"] as? String) != nil)
    let rect = CGRect(x: cx - w / 2, y: cy - h / 2, width: w, height: h)
    withRotation(num(label["rot"]) ?? 0, around: CGPoint(x: cx, y: cy), cg: cg) {
      // A little wider than measured so Core Text never wraps a line Flutter kept.
      attributed.draw(in: rect.insetBy(dx: -w * 0.08 - 4, dy: -2))
    }
  }

  private static func attributedText(
    _ text: String, font: UIFont, color: UIColor, lineHeight: CGFloat, kern: CGFloat,
    center: Bool, fakeBold: Bool
  ) -> NSAttributedString {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = center ? .center : .left
    paragraph.minimumLineHeight = lineHeight
    paragraph.maximumLineHeight = lineHeight
    paragraph.lineBreakMode = .byClipping
    var attrs: [NSAttributedString.Key: Any] = [
      .font: font,
      .foregroundColor: color,
      .paragraphStyle: paragraph,
      // Flutter's half-leading: centre the glyphs inside the line height.
      .baselineOffset: (lineHeight - font.lineHeight) / 4,
    ]
    if kern != 0 { attrs[.kern] = kern }
    if fakeBold {
      // Flutter synthesises bold for one-weight fonts; a thin fill stroke
      // gives the same heavier look.
      attrs[.strokeColor] = color
      attrs[.strokeWidth] = -3.0
    }
    return NSAttributedString(string: text, attributes: attrs)
  }

  // MARK: Bubbles

  private static func drawBubbles(_ spec: [String: Any], cg: CGContext) {
    let size = num(spec["size"]) ?? 12
    let font = font(file: spec["font"] as? String, size: size, weight: 400)
    let lineHeight = (num(spec["lineHeight"]) ?? 1.2) * size
    let padX = num(spec["padX"]) ?? 8
    let padY = num(spec["padY"]) ?? 5
    let tailW = num(spec["tailW"]) ?? 8
    let tailH = num(spec["tailH"]) ?? 6
    let inset = num(spec["tailInset"]) ?? 10
    let border = num(spec["border"]) ?? 1.2
    let fill = color(spec["fill"])
    let ink = color(spec["ink"])

    for item in (spec["items"] as? [[String: Any]]) ?? [] {
      guard let x = num(item["x"]), let y = num(item["y"]),
        let w = num(item["w"]), let h = num(item["h"]),
        let nw = num(item["nw"]), let nh = num(item["nh"]), nw > 0, nh > 0
      else { continue }
      let target = CGRect(x: x, y: y, width: w, height: h)
      let left = (item["tail"] as? String) == "left"
      withRotation(num(item["rot"]) ?? 0, around: CGPoint(x: target.midX, y: target.midY), cg: cg) {
        cg.saveGState()
        cg.translateBy(x: target.minX, y: target.minY)
        cg.scaleBy(x: w / nw, y: h / nh)

        // Outline kept inside the box so the tail tip is not clipped.
        cg.saveGState()
        cg.translateBy(x: border / 2, y: border / 2)
        let iw = nw - border
        let bodyH = nh - border - tailH
        let path = bubbleOutline(width: iw, bodyHeight: bodyH, tipY: nh - border,
                                 base: left ? inset : iw - inset - tailW, tailW: tailW)
        cg.setFillColor(fill.cgColor)
        cg.addPath(path)
        cg.fillPath()
        cg.setStrokeColor(ink.cgColor)
        cg.setLineWidth(border)
        cg.setLineJoin(.round)
        cg.addPath(path)
        cg.strokePath()
        cg.restoreGState()

        let text = (item["text"] as? String) ?? " "
        let attributed = attributedText(
          text, font: font, color: color(item["color"], fallback: ink), lineHeight: lineHeight,
          kern: 0, center: false, fakeBold: false)
        attributed.draw(in: CGRect(x: padX, y: padY, width: nw - padX + 20, height: lineHeight + 2))
        cg.restoreGState()
      }
    }
  }

  /// Rounded body with the tail cut into its bottom edge: one outline, so
  /// the stroke has no line across the tail's base.
  private static func bubbleOutline(
    width w: CGFloat, bodyHeight h: CGFloat, tipY: CGFloat, base: CGFloat, tailW: CGFloat
  ) -> CGPath {
    let r = min(10, h / 2, w / 2)
    let p = CGMutablePath()
    p.move(to: CGPoint(x: r, y: 0))
    p.addLine(to: CGPoint(x: w - r, y: 0))
    p.addArc(tangent1End: CGPoint(x: w, y: 0), tangent2End: CGPoint(x: w, y: r), radius: r)
    p.addLine(to: CGPoint(x: w, y: h - r))
    p.addArc(tangent1End: CGPoint(x: w, y: h), tangent2End: CGPoint(x: w - r, y: h), radius: r)
    p.addLine(to: CGPoint(x: base + tailW, y: h))
    p.addLine(to: CGPoint(x: base + tailW / 2, y: tipY))
    p.addLine(to: CGPoint(x: base, y: h))
    p.addLine(to: CGPoint(x: r, y: h))
    p.addArc(tangent1End: CGPoint(x: 0, y: h), tangent2End: CGPoint(x: 0, y: h - r), radius: r)
    p.addLine(to: CGPoint(x: 0, y: r))
    p.addArc(tangent1End: CGPoint(x: 0, y: 0), tangent2End: CGPoint(x: r, y: 0), radius: r)
    p.closeSubpath()
    return p
  }

  // MARK: Helpers

  private enum Fit { case fill, cover, contain }

  private static func drawImage(_ image: CGImage, in rect: CGRect, mode: Fit, sharp: Bool, cg: CGContext) {
    let iw = CGFloat(image.width)
    let ih = CGFloat(image.height)
    guard iw > 0, ih > 0, rect.width > 0, rect.height > 0 else { return }
    var target = rect
    switch mode {
    case .fill:
      break
    case .contain, .cover:
      let s = mode == .contain
        ? min(rect.width / iw, rect.height / ih)
        : max(rect.width / iw, rect.height / ih)
      let w = iw * s
      let h = ih * s
      target = CGRect(x: rect.midX - w / 2, y: rect.midY - h / 2, width: w, height: h)
    }
    cg.saveGState()
    if mode == .cover { cg.clip(to: rect) }
    cg.interpolationQuality = sharp ? .none : .high
    // Core Graphics draws images bottom-up; flip around the target.
    cg.translateBy(x: target.minX, y: target.maxY)
    cg.scaleBy(x: 1, y: -1)
    cg.draw(image, in: CGRect(x: 0, y: 0, width: target.width, height: target.height))
    cg.restoreGState()
  }

  private static func withRotation(_ degrees: CGFloat, around center: CGPoint, cg: CGContext, _ draw: () -> Void) {
    if degrees == 0 { draw(); return }
    cg.saveGState()
    cg.translateBy(x: center.x, y: center.y)
    cg.rotate(by: degrees * .pi / 180)
    cg.translateBy(x: -center.x, y: -center.y)
    draw()
    cg.restoreGState()
  }

  /// Decodes [path] no larger than [maxPixel] on its long side (widget memory
  /// is tight; the character art is ~1250px).
  private static func loadImage(_ path: String, maxPixel: CGFloat) -> CGImage? {
    let url = URL(fileURLWithPath: path) as CFURL
    guard let source = CGImageSourceCreateWithURL(url, nil) else { return nil }
    let options: [CFString: Any] = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceShouldCacheImmediately: true,
      kCGImageSourceThumbnailMaxPixelSize: max(Int(maxPixel.rounded(.up)), 8),
    ]
    return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
  }

  private static var fontNames: [String: String] = [:]

  private static func font(file: String?, size: CGFloat, weight: Int) -> UIFont {
    if let file, let name = registeredFontName(file), let font = UIFont(name: name, size: size) {
      return font
    }
    let w: UIFont.Weight = weight >= 900 ? .black : weight >= 700 ? .bold : .regular
    return UIFont.systemFont(ofSize: size, weight: w)
  }

  /// Registers a font file copied into the App Group and returns its name.
  private static func registeredFontName(_ path: String) -> String? {
    if let cached = fontNames[path] { return cached }
    let url = URL(fileURLWithPath: path) as CFURL
    guard let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url) as? [CTFontDescriptor],
      let first = descriptors.first,
      let name = CTFontDescriptorCopyAttribute(first, kCTFontNameAttribute) as? String
    else { return nil }
    CTFontManagerRegisterFontsForURL(url, .process, nil)
    fontNames[path] = name
    return name
  }

  private static func num(_ value: Any?) -> CGFloat? {
    if let n = value as? NSNumber { return CGFloat(truncating: n) }
    if let d = value as? Double { return CGFloat(d) }
    return nil
  }

  private static func color(_ value: Any?, fallback: UIColor = .black) -> UIColor {
    guard let n = value as? NSNumber else { return fallback }
    let v = n.uint32Value
    return UIColor(
      red: CGFloat((v >> 16) & 0xFF) / 255,
      green: CGFloat((v >> 8) & 0xFF) / 255,
      blue: CGFloat(v & 0xFF) / 255,
      alpha: CGFloat((v >> 24) & 0xFF) / 255)
  }
}
