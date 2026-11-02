package com.quotation.quotation

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.os.Bundle
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/** iOS "오늘의 문구": dashed box, quote only. Small is 2×2, medium is 4×2. */
open class QuoteOnlyWidgetProvider : HomeWidgetProvider() {
  override fun onEnabled(context: Context) {
    super.onEnabled(context)
    DailyWordWidgetProvider.scheduleHourlyRefresh(context)
  }

  override fun onDisabled(context: Context) {
    if (!DailyWordWidgetProvider.hasQuoteFamilyWidgets(context)) {
      DailyWordWidgetProvider.cancelHourlyRefresh(context)
    }
    super.onDisabled(context)
  }

  override fun onAppWidgetOptionsChanged(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetId: Int,
      newOptions: Bundle,
  ) {
    onUpdate(context, appWidgetManager, intArrayOf(appWidgetId))
  }

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    appWidgetIds.forEach { widgetId ->
      try {
        val options = appWidgetManager.getAppWidgetOptions(widgetId)
        val (widthDp, heightDp) = widgetSizeDp(context, options)
        val views =
            RemoteViews(context.packageName, R.layout.daily_word_widget).apply {
              val quoteId = pref(widgetData, "quoteId")
              val categoryId = pref(widgetData, "categoryId")
              val subId = pref(widgetData, "subCategoryId")
              val launchUri =
                  Uri.parse("dearly://quote").buildUpon().apply {
                    if (quoteId.isNotBlank()) appendQueryParameter("id", quoteId)
                    if (categoryId.isNotBlank()) {
                      appendQueryParameter("category", categoryId)
                    }
                    if (subId.isNotBlank()) appendQueryParameter("sub", subId)
                  }.build()
              val pendingIntent =
                  HomeWidgetLaunchIntent.getActivity(
                      context,
                      MainActivity::class.java,
                      launchUri,
                  )
              setOnClickPendingIntent(R.id.widget_root, pendingIntent)
              setOnClickPendingIntent(R.id.widget_card, pendingIntent)
              setImageViewBitmap(
                  R.id.widget_card,
                  DailyWordWidgetProvider.buildQuoteOnlyCard(
                      context = context,
                      widgetData = widgetData,
                      widthDp = widthDp,
                      heightDp = heightDp,
                  ),
              )
            }
        appWidgetManager.updateAppWidget(widgetId, views)
      } catch (e: Exception) {
        android.util.Log.e("QuoteOnlyWidget", "update failed id=$widgetId", e)
      }
    }
  }

  private fun widgetSizeDp(context: Context, options: Bundle): Pair<Int, Int> {
    val minW = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
    val maxW = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, 0)
    val minH = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
    val maxH = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0)
    val portrait =
        context.resources.configuration.orientation !=
            android.content.res.Configuration.ORIENTATION_LANDSCAPE
    val width =
        (if (portrait) minW else maxW).takeIf { it > 40 }
            ?: maxOf(minW, maxW).takeIf { it > 40 }
            ?: 110
    val height =
        (if (portrait) maxH else minH).takeIf { it > 40 }
            ?: maxOf(minH, maxH).takeIf { it > 40 }
            ?: 110
    return width.coerceIn(80, 640) to height.coerceIn(80, 640)
  }

  private fun pref(prefs: SharedPreferences, key: String): String {
    return prefs.getString(key, null)?.trim().orEmpty().ifEmpty {
      prefs.getString("flutter.$key", null)?.trim().orEmpty()
    }
  }
}

/** iOS systemMedium for 오늘의 문구. */
class QuoteOnlyWidgetProviderMedium : QuoteOnlyWidgetProvider()
