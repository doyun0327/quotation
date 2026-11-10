import SwiftUI
import WidgetKit

@main
struct DearlyWidgetsBundle: WidgetBundle {
  var body: some Widget {
    // Gallery order: Together first, then character card, then quote-only.
    TogetherWidget()
    DailyWordWidget()
    QuoteOnlyWidget()
  }
}
