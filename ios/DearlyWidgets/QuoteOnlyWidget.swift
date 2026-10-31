import SwiftUI
import WidgetKit

/// Second gallery option: dashed box with the quote only.
struct QuoteOnlyWidgetView: View {
  var entry: DailyWordEntry

  private let corner: CGFloat = 14
  private let stroke: CGFloat = 1.5
  private let textColor = Color(red: 0.24, green: 0.30, blue: 0.38)

  var body: some View {
    GeometryReader { geo in
      let frame = entry.accent.opacity(0.75)
      // Keep the dashed stroke inside the system rounded clip.
      let inset: CGFloat = max(8, stroke + 4)
      ZStack {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
          .fill(Color.white.opacity(0.92))
        RoundedRectangle(cornerRadius: corner, style: .continuous)
          .strokeBorder(
            style: StrokeStyle(lineWidth: stroke, dash: [5, 3.5])
          )
          .foregroundColor(frame)

        Text(entry.quote)
          .font(.system(size: geo.size.width < 160 ? 13 : 15, weight: .semibold, design: .rounded))
          .foregroundColor(textColor)
          .multilineTextAlignment(.leading)
          .lineLimit(8)
          .minimumScaleFactor(0.65)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
          .padding(12)
      }
      .padding(inset)
      .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
    }
    .widgetURL(launchURL)
  }

  private var launchURL: URL? {
    var components = URLComponents(string: "dearly://quote")
    var items: [URLQueryItem] = []
    if !entry.quoteId.isEmpty { items.append(URLQueryItem(name: "id", value: entry.quoteId)) }
    if !entry.categoryId.isEmpty {
      items.append(URLQueryItem(name: "category", value: entry.categoryId))
    }
    if !entry.subCategoryId.isEmpty {
      items.append(URLQueryItem(name: "sub", value: entry.subCategoryId))
    }
    components?.queryItems = items.isEmpty ? nil : items
    return components?.url
  }
}

struct QuoteOnlyWidget: Widget {
  let kind: String = "QuoteOnlyWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: DailyWordProvider()) { entry in
      QuoteOnlyWidgetView(entry: entry)
        .dearlyWidgetBackground()
    }
    .configurationDisplayName("오늘의 문구")
    .description("점선 네모 안에 응원 문구만 보여 줍니다.")
    .supportedFamilies([.systemSmall, .systemMedium])
    .contentMarginsDisabled()
  }
}
