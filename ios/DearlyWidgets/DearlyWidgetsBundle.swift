import SwiftUI
import WidgetKit

@main
struct DearlyWidgetsBundle: WidgetBundle {
  var body: some Widget {
    // Gallery order: character card first, quote-only second, then Together.
    DailyWordWidget()
    QuoteOnlyWidget()
    TogetherWidget()
  }
}
