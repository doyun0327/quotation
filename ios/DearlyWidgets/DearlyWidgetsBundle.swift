import SwiftUI
import WidgetKit

@main
struct DearlyWidgetsBundle: WidgetBundle {
  var body: some Widget {
    // Gallery order: the user's rooms first (방 1…5; 방 1 is the original
    // "TogetherWidget" kind), then character card, then quote-only.
    TogetherRoom1Widget()
    TogetherRoom2Widget()
    TogetherRoom3Widget()
    TogetherRoom4Widget()
    TogetherRoom5Widget()
    DailyWordWidget()
    QuoteOnlyWidget()
  }
}
