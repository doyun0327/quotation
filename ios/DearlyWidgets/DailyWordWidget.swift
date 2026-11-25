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
      quote: WidgetText.pick("오늘도 한 걸음.", "One more step today.", "今日も一歩。"),
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
    // A new line every half hour (:00 / :30) for the next 12 hours.
    let now = Date()
    let slot = DearlyWidgetStore.quoteSlot(at: now)
    var entries = [entry(for: now, preview: false)]
    for step in 1...24 {
      let date = DearlyWidgetStore.quoteSlotStart(slot + Int64(step))
      entries.append(entry(for: date, preview: false))
    }
    let refresh = DearlyWidgetStore.quoteSlotStart(slot + 24)
    completion(Timeline(entries: entries, policy: .after(refresh)))
  }

  private func entry(for date: Date, preview: Bool) -> DailyWordEntry {
    let line = DearlyWidgetStore.quoteLine(at: date)
    let quote = line?.text ?? "Dearly"
    let fallbackQuote = preview ? WidgetText.pick("오늘도 한 걸음.", "One more step today.", "今日も一歩。") : quote
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
      quoteId: line?.id ?? "",
      categoryId: line?.categoryId ?? "",
      subCategoryId: line?.subCategoryId ?? ""
    )
  }
}

/// Same card as the Galaxy "오늘의 말" widget (DailyWordWidgetProvider
/// .buildHomeCard with bubble = true): the character with a name tag on the
/// left, a dashed speech bubble whose tail points at the character, the date
/// on top of the bubble and the quote under it, shrinking to fit.
/// Keep the numbers in step with the Kotlin card.
struct DailyWordWidgetView: View {
  var entry: DailyWordEntry

  private let stroke: CGFloat = 1.4
  /// The system rounds off the widget's corners, which cuts a border drawn
  /// along the edge: the box stays this far inside.
  private let margin: CGFloat = 8
  private let tagHeight: CGFloat = 22
  private let tagGap: CGFloat = 2
  private let tailWidth: CGFloat = 10
  private let tailHalf: CGFloat = 7
  private let quoteColor = Color(red: 0x3C / 255, green: 0x4C / 255, blue: 0x60 / 255)
  private let dateColor = Color(red: 0x8E / 255, green: 0xA0 / 255, blue: 0xB5 / 255)

  var body: some View {
    GeometryReader { geo in
      let w = max(geo.size.width, 1)
      let h = max(geo.size.height, 1)
      let boxTop = margin
      let boxBottom = h - margin
      // Character + name tag take three quarters of the box height.
      let groupHeight = (boxBottom - boxTop) * 0.75
      let bodyHeight = max(groupHeight - tagGap - tagHeight, 24)
      let art = entry.character.flatMap { croppedCharacter($0) ?? $0 }
      let artSize = art?.size ?? CGSize(width: 1, height: 1)
      let bodyWidth = art == nil ? 0 : artSize.width * (bodyHeight / max(artSize.height, 1))
      // The column is at least as wide as a short name tag; the bubble starts
      // past the character and the tail.
      let groupWidth = max(bodyWidth, 56)
      let bodyLeft = 2 + (groupWidth - bodyWidth) / 2
      let boxLeft = min(max(2 + groupWidth + 4 + tailWidth, w * 0.2), w * 0.34)
      let bodyTop = boxTop + (boxBottom - boxTop - groupHeight) * 0.6
      let box = CGRect(x: boxLeft, y: boxTop, width: w - margin - boxLeft, height: boxBottom - boxTop)
      let radius: CGFloat = isPixel ? 18 : 22
      let bubble = QuoteBubbleShape(
        box: box, radius: radius, tailWidth: tailWidth,
        tailY: bodyTop + bodyHeight * 0.4, tailHalf: tailHalf, stroke: stroke)

      let textLeft = box.minX + 14
      let textRight = box.maxX - 10
      let dateTop = box.minY + 8
      let quoteTop = dateTop + 22 + 6
      let quoteBottom = box.maxY - 10
      let large = h >= 140

      ZStack(alignment: .topLeading) {
        bubble.fill(Color.white)
        // Same as the app home bubble (_HomeBubblePainter): white, dashed
        // 5 / 3.5 in the accent faded 42% toward white, square dash ends.
        bubble.stroke(
          frameColor,
          style: StrokeStyle(lineWidth: stroke, lineCap: .square, dash: [5, 3.5]))

        if let art {
          Image(uiImage: art)
            .resizable()
            .interpolation(.none)
            .frame(width: bodyWidth, height: bodyHeight)
            .position(x: bodyLeft + bodyWidth / 2, y: bodyTop + bodyHeight / 2)
        }

        if !entry.nickname.isEmpty {
          let center = bodyLeft + bodyWidth / 2
          // Never past the tail, so the tag cannot reach the quote.
          let tagEdge = boxLeft - tailWidth - 2
          let maxTag = max((tagEdge - center) * 2, 48)
          let tagWidth = min(textWidth(entry.nickname, size: 12) + 16, maxTag)
          Text(entry.nickname)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundColor(quoteColor)
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(width: tagWidth - 16, height: tagHeight)
            .padding(.horizontal, 8)
            .background(
              RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.white)
            )
            .overlay(
              RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(entry.accent.opacity(0x8C / 255), lineWidth: stroke)
            )
            .position(x: center, y: bodyTop + bodyHeight + tagGap + tagHeight / 2)
        }

        Text(DearlyWidgetStore.homeDateLabel(entry.date))
          .font(.system(size: large ? 13 : 11, weight: .bold, design: .rounded))
          .foregroundColor(dateColor)
          .lineLimit(1)
          .frame(width: max(textRight - textLeft, 24), height: 22, alignment: .leading)
          .position(x: textLeft + max(textRight - textLeft, 24) / 2, y: dateTop + 11)

        // Quote: start at the card size and shrink until every line fits.
        let quoteW = max(textRight - textLeft, 24)
        let quoteH = max(quoteBottom - quoteTop, 12)
        Text(entry.quote)
          .font(.system(size: large ? 15 : 13, weight: .semibold, design: .rounded))
          .foregroundColor(quoteColor)
          .lineSpacing((large ? 15 : 13) * 0.35)
          .multilineTextAlignment(.leading)
          .minimumScaleFactor(7.0 / 15.0)
          .frame(width: quoteW, height: quoteH, alignment: .topLeading)
          .position(x: textLeft + quoteW / 2, y: quoteTop + quoteH / 2)
      }
      .frame(width: w, height: h, alignment: .topLeading)
    }
    .widgetURL(launchURL)
  }

  private var isPixel: Bool {
    DearlyWidgetStore.string("visualStyle") != "clean"
  }

  /// Same mix as the Galaxy dashed frame: accent faded 42% toward white.
  private var frameColor: Color {
    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0
    guard UIColor(entry.accent).getRed(&r, green: &g, blue: &b, alpha: &a) else {
      return entry.accent
    }
    let t: CGFloat = 0.42
    return Color(red: r + (1 - r) * t, green: g + (1 - g) * t, blue: b + (1 - b) * t)
  }

  private func textWidth(_ text: String, size: CGFloat) -> CGFloat {
    var font = UIFont.systemFont(ofSize: size, weight: .bold)
    if let rounded = font.fontDescriptor.withDesign(.rounded) {
      font = UIFont(descriptor: rounded, size: size)
    }
    return ceil((text as NSString).size(withAttributes: [.font: font]).width)
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
    // home_widget only reports taps on URLs carrying a `homeWidget` query item.
    var items = [URLQueryItem(name: "homeWidget", value: nil)]
    if !entry.quoteId.isEmpty { items.append(URLQueryItem(name: "id", value: entry.quoteId)) }
    if !entry.categoryId.isEmpty {
      items.append(URLQueryItem(name: "category", value: entry.categoryId))
    }
    if !entry.subCategoryId.isEmpty {
      items.append(URLQueryItem(name: "sub", value: entry.subCategoryId))
    }
    components?.queryItems = items
    return components?.url
  }
}

/// Rounded box with a tail on its left edge at [tailY], one outline (so the
/// dashes run around the tail too). Mirrors Kotlin bubblePath.
struct QuoteBubbleShape: Shape {
  let box: CGRect
  let radius: CGFloat
  let tailWidth: CGFloat
  let tailY: CGFloat
  let tailHalf: CGFloat
  let stroke: CGFloat

  func path(in _: CGRect) -> Path {
    let inset = stroke / 2
    let body = box.insetBy(dx: inset, dy: inset)
    let r = min(radius, body.width / 2, body.height / 2)
    let low = body.minY + r + tailHalf
    let high = body.maxY - r - tailHalf
    // Keep the tail on the straight part of the left edge.
    let y = low <= high ? min(max(tailY, low), high) : body.midY
    let tip = CGPoint(x: box.minX - tailWidth + inset, y: y + tailHalf * 3 / 7)

    var p = Path()
    p.move(to: CGPoint(x: body.minX + r, y: body.minY))
    p.addLine(to: CGPoint(x: body.maxX - r, y: body.minY))
    p.addArc(
      center: CGPoint(x: body.maxX - r, y: body.minY + r), radius: r,
      startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
    p.addLine(to: CGPoint(x: body.maxX, y: body.maxY - r))
    p.addArc(
      center: CGPoint(x: body.maxX - r, y: body.maxY - r), radius: r,
      startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
    p.addLine(to: CGPoint(x: body.minX + r, y: body.maxY))
    p.addArc(
      center: CGPoint(x: body.minX + r, y: body.maxY - r), radius: r,
      startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
    // Left edge up, out along the tail and back in.
    p.addLine(to: CGPoint(x: body.minX, y: y + tailHalf))
    p.addLine(to: tip)
    p.addLine(to: CGPoint(x: body.minX, y: y - tailHalf))
    p.addLine(to: CGPoint(x: body.minX, y: body.minY + r))
    p.addArc(
      center: CGPoint(x: body.minX + r, y: body.minY + r), radius: r,
      startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
    p.closeSubpath()
    return p
  }
}

struct DailyWordWidget: Widget {
  let kind: String = "DailyWordWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: DailyWordProvider()) { entry in
      DailyWordWidgetView(entry: entry)
        .dearlyWidgetBackground()
    }
    .configurationDisplayName(WidgetText.pick("오늘의 말", "Word of the day", "今日のことば"))
    .description(WidgetText.pick(
      "캐릭터·날짜·응원 문구를 함께 보여 줍니다.",
      "Shows your character, the date and a cheer.",
      "キャラクター・日付・応援メッセージを表示します。"))
    .supportedFamilies([.systemMedium])
    .contentMarginsDisabled()
  }
}
