import SwiftUI
import WidgetKit

struct DailyWordEntry: TimelineEntry {
  let date: Date
  let quote: String
  let nickname: String
  let accent: Color
  let character: UIImage?
  let paw: UIImage?
  let quoteId: String
  let categoryId: String
  let subCategoryId: String
}

struct DailyWordProvider: TimelineProvider {
  func placeholder(in context: Context) -> DailyWordEntry {
    DailyWordEntry(
      date: Date(),
      quote: "오늘도 한 걸음.",
      nickname: "Dearly",
      accent: Color(red: 0.55, green: 0.70, blue: 0.88),
      character: nil,
      paw: nil,
      quoteId: "",
      categoryId: "",
      subCategoryId: ""
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (DailyWordEntry) -> Void) {
    completion(entry(for: Date(), preview: context.isPreview))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<DailyWordEntry>) -> Void) {
    let now = Date()
    let cal = Calendar.current
    var entries: [DailyWordEntry] = []
    for hour in 0..<12 {
      guard let date = cal.date(byAdding: .hour, value: hour, to: now) else { continue }
      entries.append(entry(for: date, preview: false))
    }
    let refresh = cal.date(byAdding: .hour, value: 12, to: now) ?? now.addingTimeInterval(3600)
    completion(Timeline(entries: entries, policy: .after(refresh)))
  }

  private func entry(for date: Date, preview: Bool) -> DailyWordEntry {
    let quote = DearlyWidgetStore.quote(at: date)
    let fallbackQuote = preview ? "오늘도 한 걸음." : quote
    return DailyWordEntry(
      date: date,
      quote: fallbackQuote.isEmpty ? "Dearly" : fallbackQuote,
      nickname: DearlyWidgetStore.string("nickname"),
      accent: DearlyWidgetStore.color(
        "themeAccent",
        fallback: UIColor(red: 0.55, green: 0.70, blue: 0.88, alpha: 1)
      ),
      character: DearlyWidgetStore.image(forKey: "characterImage"),
      paw: DearlyWidgetStore.image(forKey: "pawImage"),
      quoteId: DearlyWidgetStore.string("quoteId"),
      categoryId: DearlyWidgetStore.string("categoryId"),
      subCategoryId: DearlyWidgetStore.string("subCategoryId")
    )
  }
}

/// Widget-only layout from the design mock:
/// left character panel + right date / quote panels, transparent chrome.
struct DailyWordWidgetView: View {
  var entry: DailyWordEntry

  private let gap: CGFloat = 8
  private let corner: CGFloat = 12
  private let stroke: CGFloat = 1.5
  private let textColor = Color(red: 0.24, green: 0.30, blue: 0.38)
  private let dateColor = Color(red: 0.45, green: 0.55, blue: 0.68)

  var body: some View {
    GeometryReader { geo in
      let w = max(geo.size.width, 1)
      let h = max(geo.size.height, 1)
      let frame = frameColor
      let leftW = min(w * 0.30, 110)
      let rightW = max(w - leftW - gap * 3, 80)
      let dateH: CGFloat = 36
      let quoteH = max(h - dateH - gap * 3, 40)

      HStack(alignment: .top, spacing: gap) {
        // Left: character + nickname (slightly smaller, centered)
        dashedPanel(frame: frame, corner: corner) {
          VStack(spacing: 6) {
            Spacer(minLength: 0)
            if let character = entry.character {
              let maxCharW = (leftW - 20) * 0.82
              let maxCharH = (h - gap * 2 - 36) * 0.72
              Image(uiImage: croppedCharacter(character) ?? character)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(maxWidth: maxCharW, maxHeight: maxCharH)
                .frame(maxWidth: .infinity)
            }
            if !entry.nickname.isEmpty {
              Text(entry.nickname)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(textColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
            }
            Spacer(minLength: 0)
          }
          .padding(.horizontal, 8)
          .padding(.vertical, 8)
          .frame(width: leftW, height: h - gap * 2)
        }

        VStack(alignment: .leading, spacing: gap) {
          // Top-right: date
          dashedPanel(frame: frame, corner: corner) {
            HStack {
              Spacer(minLength: 0)
              Text(DearlyWidgetStore.homeDateLabel(entry.date))
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(dateColor)
                .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(width: rightW, height: dateH, alignment: .trailing)
          }

          // Bottom-right: quote + paw
          dashedPanel(frame: frame, corner: corner) {
            ZStack(alignment: .bottomTrailing) {
              Text(entry.quote)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(textColor)
                .multilineTextAlignment(.leading)
                .lineLimit(6)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.horizontal, 10)
                .padding(.top, 8)
                .padding(.bottom, 22)

              if let paw = entry.paw {
                Image(uiImage: paw)
                  .resizable()
                  .interpolation(.none)
                  .scaledToFit()
                  .frame(width: 18, height: 18)
                  .padding(8)
              } else {
                Image(systemName: "pawprint.fill")
                  .font(.system(size: 12))
                  .foregroundColor(frame)
                  .padding(8)
              }
            }
            .frame(width: rightW, height: quoteH)
          }
        }
      }
      .padding(gap)
      .frame(width: w, height: h, alignment: .topLeading)
    }
    .widgetURL(launchURL)
  }

  private var frameColor: Color {
    // Soft border like the mock (accent faded toward white).
    entry.accent.opacity(0.75)
  }

  private func dashedPanel<Content: View>(
    frame: Color,
    corner: CGFloat,
    @ViewBuilder content: () -> Content
  ) -> some View {
    content()
      .background(
        RoundedRectangle(cornerRadius: corner, style: .continuous)
          .fill(Color.white.opacity(0.92))
      )
      .overlay(
        RoundedRectangle(cornerRadius: corner, style: .continuous)
          .strokeBorder(
            style: StrokeStyle(lineWidth: stroke, dash: [5, 3.5])
          )
          .foregroundColor(frame)
      )
  }

  private func croppedCharacter(_ image: UIImage) -> UIImage? {
    guard let cgImage = image.cgImage else { return image }
    let w = cgImage.width
    let h = cgImage.height
    guard w > 0, h > 0, let data = cgImage.dataProvider?.data,
      let ptr = CFDataGetBytePtr(data)
    else {
      return image
    }
    let bpp = max(cgImage.bitsPerPixel / 8, 1)
    let bytesPerRow = cgImage.bytesPerRow
    var minX = w
    var minY = h
    var maxX = -1
    var maxY = -1
    let alphaInfo = cgImage.alphaInfo
    let alphaIndex: Int?
    switch alphaInfo {
    case .premultipliedLast, .last:
      alphaIndex = bpp - 1
    case .premultipliedFirst, .first:
      alphaIndex = 0
    default:
      alphaIndex = nil
    }
    for y in 0..<h {
      let row = ptr.advanced(by: y * bytesPerRow)
      for x in 0..<w {
        let alpha: UInt8 = {
          if let alphaIndex { return row[x * bpp + alphaIndex] }
          return 255
        }()
        if alpha > 10 {
          if x < minX { minX = x }
          if x > maxX { maxX = x }
          if y < minY { minY = y }
          if y > maxY { maxY = y }
        }
      }
    }
    guard maxX >= minX, maxY >= minY,
      let cropped = cgImage.cropping(
        to: CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
      )
    else {
      return image
    }
    return UIImage(cgImage: cropped, scale: image.scale, orientation: image.imageOrientation)
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

struct DailyWordWidget: Widget {
  let kind: String = "DailyWordWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: DailyWordProvider()) { entry in
      DailyWordWidgetView(entry: entry)
        .dearlyWidgetBackground()
    }
    .configurationDisplayName("오늘의 말")
    .description("캐릭터·날짜·응원 문구를 함께 보여 줍니다.")
    .supportedFamilies([.systemMedium, .systemLarge])
    .contentMarginsDisabled()
  }
}
