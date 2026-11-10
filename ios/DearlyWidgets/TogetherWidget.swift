import AppIntents
import SwiftUI
import WidgetKit

/// One row of the `ddayRoomIndex` list written by HomeWidgetSync.
struct TogetherRoom {
  let id: String
  let title: String
  let imageKey: String

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
      return TogetherRoom(id: id, title: row["title"] as? String ?? "", imageKey: imageKey)
    }
  }
}

struct TogetherRoomEntity: AppEntity {
  static var typeDisplayRepresentation: TypeDisplayRepresentation = "함께 방"
  static var defaultQuery = TogetherRoomQuery()

  let id: String
  let title: String

  init(_ room: TogetherRoom) {
    id = room.id
    title = room.title.isEmpty ? "함께" : room.title
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
}

struct TogetherProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> TogetherEntry {
    TogetherEntry(date: Date(), card: nil, roomId: "")
  }

  func snapshot(for configuration: SelectTogetherRoomIntent, in context: Context) async -> TogetherEntry {
    makeEntry(for: configuration)
  }

  func timeline(for configuration: SelectTogetherRoomIntent, in context: Context) async -> Timeline<TogetherEntry> {
    let entry = makeEntry(for: configuration)
    let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
    return Timeline(entries: [entry], policy: .after(next))
  }

  /// A widget with no room picked, or whose room was deleted, shows the
  /// app's default room; the card and the tap target always stay paired.
  private func makeEntry(for configuration: SelectTogetherRoomIntent) -> TogetherEntry {
    if let selectedId = configuration.room?.id,
      let room = TogetherRoom.all().first(where: { $0.id == selectedId }),
      let card = DearlyWidgetStore.image(forKey: room.imageKey)
    {
      return TogetherEntry(date: Date(), card: card, roomId: room.id)
    }
    return TogetherEntry(
      date: Date(),
      card: DearlyWidgetStore.image(forKey: "togetherCardImage"),
      roomId: DearlyWidgetStore.string("ddayRoomId")
    )
  }
}

/// Card is rendered at the systemMedium ratio (2.14:1, shared with Galaxy),
/// so it fills the widget; fill trims the ~1% per-device ratio difference.
struct TogetherWidgetView: View {
  var entry: TogetherEntry

  var body: some View {
    GeometryReader { geo in
      Group {
        if let card = entry.card {
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
    .containerBackground(for: .widget) {
      Color.clear
    }
    .widgetURL(launchURL)
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

struct TogetherWidget: Widget {
  let kind: String = "TogetherWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind,
      intent: SelectTogetherRoomIntent.self,
      provider: TogetherProvider()
    ) { entry in
      TogetherWidgetView(entry: entry)
    }
    .configurationDisplayName("함께")
    .description("친구와 공유하는 캐릭터와 응원 문구를 보여 줍니다. 위젯을 길게 눌러 방을 선택하세요.")
    .supportedFamilies([.systemMedium])
    .contentMarginsDisabled()
  }
}
