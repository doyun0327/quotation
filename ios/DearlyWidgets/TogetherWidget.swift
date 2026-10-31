import SwiftUI
import WidgetKit

struct TogetherEntry: TimelineEntry {
  let date: Date
  let card: UIImage?
  let roomId: String
}

struct TogetherProvider: TimelineProvider {
  func placeholder(in context: Context) -> TogetherEntry {
    TogetherEntry(date: Date(), card: nil, roomId: "")
  }

  func getSnapshot(in context: Context, completion: @escaping (TogetherEntry) -> Void) {
    completion(makeEntry())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<TogetherEntry>) -> Void) {
    let entry = makeEntry()
    let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
    completion(Timeline(entries: [entry], policy: .after(next)))
  }

  private func makeEntry() -> TogetherEntry {
    TogetherEntry(
      date: Date(),
      card: DearlyWidgetStore.image(forKey: "togetherCardImage"),
      roomId: DearlyWidgetStore.string("ddayRoomId")
    )
  }
}

/// Galaxy decorate PNG as-is (no squash, no crop). Centered in systemMedium.
struct TogetherWidgetView: View {
  var entry: TogetherEntry

  var body: some View {
    GeometryReader { geo in
      Group {
        if let card = entry.card {
          Image(uiImage: card)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
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
    if !entry.roomId.isEmpty {
      components?.queryItems = [URLQueryItem(name: "room", value: entry.roomId)]
    }
    return components?.url
  }
}

struct TogetherWidget: Widget {
  let kind: String = "TogetherWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: TogetherProvider()) { entry in
      TogetherWidgetView(entry: entry)
    }
    .configurationDisplayName("함께")
    .description("친구와 공유하는 캐릭터와 응원 문구를 보여 줍니다.")
    .supportedFamilies([.systemMedium])
    .contentMarginsDisabled()
  }
}
