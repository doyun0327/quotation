package com.quotation.quotation

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class DdayWidgetProvider : HomeWidgetProvider() {
  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    appWidgetIds.forEach { widgetId ->
      val views =
          RemoteViews(context.packageName, R.layout.dday_widget).apply {
            val launchIntent =
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
            setOnClickPendingIntent(R.id.dday_solo_group, launchIntent)
            setOnClickPendingIntent(R.id.dday_duo_group, launchIntent)

            val title = widgetData.getString("ddayTitle", null).orEmpty()
            val label = widgetData.getString("ddayLabel", null).orEmpty()
            val date = widgetData.getString("ddayDate", null).orEmpty()
            val meId = widgetData.getString("ddayCharMe", "basic").orEmpty()
            val friendId = widgetData.getString("ddayCharFriend", null).orEmpty()
            val style = widgetData.getString("visualStyle", "pixel").orEmpty()
            val meOffsetX = readInt(widgetData, "ddayMeOffsetX", 0)
            val meOffsetY = readInt(widgetData, "ddayMeOffsetY", 0)
            val friendOffsetX = readInt(widgetData, "ddayFriendOffsetX", 0)
            val friendOffsetY = readInt(widgetData, "ddayFriendOffsetY", 0)

            val displayTitle =
                if (title.isBlank()) {
                  context.getString(R.string.dday_widget_empty_title)
                } else {
                  title
                }
            val displayLabel =
                if (title.isBlank()) {
                  context.getString(R.string.dday_widget_label)
                } else {
                  label.ifBlank { context.getString(R.string.dday_widget_label) }
                }
            val displayDate =
                if (title.isBlank()) {
                  context.getString(R.string.dday_widget_empty_date)
                } else {
                  date
                }

            setTextViewText(R.id.dday_solo_title, displayTitle)
            setTextViewText(R.id.dday_solo_label, displayLabel)
            setTextViewText(R.id.dday_solo_date, displayDate)
            setTextViewText(R.id.dday_duo_title, displayTitle)
            setTextViewText(R.id.dday_duo_label, displayLabel)
            setTextViewText(R.id.dday_duo_date, displayDate)

            applyCharacterMode(
                context = context,
                meId = meId.ifBlank { "basic" },
                friendId = if (title.isBlank()) "" else friendId,
                style = style.ifBlank { "pixel" },
                meOffsetX = meOffsetX,
                meOffsetY = meOffsetY,
                friendOffsetX = friendOffsetX,
                friendOffsetY = friendOffsetY,
            )
          }

      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }

  private fun RemoteViews.applyCharacterMode(
      context: Context,
      meId: String,
      friendId: String,
      style: String,
      meOffsetX: Int,
      meOffsetY: Int,
      friendOffsetX: Int,
      friendOffsetY: Int,
  ) {
    val meRes = DdayWidgetVisuals.drawableFor(meId)
    val hasFriend = friendId.isNotBlank()

    if (!hasFriend) {
      setViewVisibility(R.id.dday_solo_group, View.VISIBLE)
      setViewVisibility(R.id.dday_duo_group, View.GONE)
      setImageViewResource(R.id.dday_solo_me, meRes)
      return
    }

    val friendRes = DdayWidgetVisuals.drawableFor(friendId)
    setViewVisibility(R.id.dday_solo_group, View.GONE)
    setViewVisibility(R.id.dday_duo_group, View.VISIBLE)
    setImageViewResource(R.id.dday_duo_me, meRes)
    setImageViewResource(R.id.dday_duo_friend, friendRes)

    val heart =
        if (style == "clean") {
          DdayWidgetVisuals.buildCleanHeartBitmap(context)
        } else {
          DdayWidgetVisuals.buildPixelHeartBitmap(context)
        }
    setImageViewBitmap(R.id.dday_duo_heart, heart)

    val density = context.resources.displayMetrics.density
    // Positive Y from the app means "up" on the preview.
    setFloat(R.id.dday_duo_me, "setTranslationX", meOffsetX * density)
    setFloat(R.id.dday_duo_me, "setTranslationY", -meOffsetY * density)
    setFloat(R.id.dday_duo_friend, "setTranslationX", friendOffsetX * density)
    setFloat(R.id.dday_duo_friend, "setTranslationY", -friendOffsetY * density)
  }

  private fun readInt(prefs: SharedPreferences, key: String, default: Int): Int {
    return try {
      when (val raw = prefs.all[key]) {
        is Int -> raw
        is Long -> raw.toInt()
        is String -> raw.toIntOrNull() ?: default
        else -> default
      }
    } catch (_: Exception) {
      default
    }
  }
}
