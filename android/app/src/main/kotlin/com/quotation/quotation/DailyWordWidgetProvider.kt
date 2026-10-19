package com.quotation.quotation

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.util.TypedValue
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.abs

class DailyWordWidgetProvider : HomeWidgetProvider() {
  override fun onEnabled(context: Context) {
    super.onEnabled(context)
    scheduleHourlyRefresh(context)
  }

  override fun onDisabled(context: Context) {
    cancelHourlyRefresh(context)
    super.onDisabled(context)
  }

  override fun onReceive(context: Context, intent: Intent?) {
    if (intent?.action == ACTION_HOURLY_REFRESH ||
        intent?.action == Intent.ACTION_BOOT_COMPLETED ||
        intent?.action == Intent.ACTION_MY_PACKAGE_REPLACED
    ) {
      scheduleHourlyRefresh(context)
      val manager = AppWidgetManager.getInstance(context)
      val ids =
          manager.getAppWidgetIds(
              ComponentName(context, DailyWordWidgetProvider::class.java),
          )
      if (ids.isNotEmpty()) {
        onUpdate(context, manager, ids)
      }
      if (intent.action == ACTION_HOURLY_REFRESH) return
    }
    super.onReceive(context, intent)
  }

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    scheduleHourlyRefresh(context)

    appWidgetIds.forEach { widgetId ->
      val views =
          RemoteViews(context.packageName, R.layout.daily_word_widget).apply {
            val pendingIntent =
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
            setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            val quoteText = resolveHourlyQuote(context, widgetData)

            val accent = readColor(widgetData, "themeAccent", DEFAULT_ACCENT)
            val border = readColor(widgetData, "themeBorder", DEFAULT_BORDER)
            val windowBar = readColor(widgetData, "themeWindowBar", DEFAULT_WINDOW_BAR)

            setTextViewText(R.id.widget_quote, quoteText)
            val characterId = widgetData.getString("characterId", "basic")
            val characterRes =
                if (characterId == "bul") R.drawable.character_bul
                else R.drawable.character
            setImageViewResource(R.id.widget_character, characterRes)
            setInt(R.id.widget_window_bar, "setBackgroundColor", windowBar)
            setInt(R.id.widget_chrome_1, "setBackgroundColor", 0xFFFFFFFF.toInt())
            setInt(R.id.widget_chrome_2, "setBackgroundColor", 0xFFFFFFFF.toInt())
            setInt(R.id.widget_chrome_3, "setBackgroundColor", 0xFFFFFFFF.toInt())
            setTextColor(R.id.widget_chrome_1, accent)
            setTextColor(R.id.widget_chrome_2, accent)
            setTextColor(R.id.widget_chrome_3, accent)

            val options = appWidgetManager.getAppWidgetOptions(widgetId)
            val maxWidthDp =
                options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, 250)
            val bubbleWidthDp = (maxWidthDp - 98).coerceAtLeast(140)
            val bubbleHeightDp = 118
            val bubbleBmp =
                buildBubbleBitmap(
                    context = context,
                    widthDp = bubbleWidthDp,
                    heightDp = bubbleHeightDp,
                    fill = 0xFFFFFFFF.toInt(),
                    border = border,
                )
            setImageViewBitmap(R.id.widget_bubble_bg, bubbleBmp)
          }

      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }

  private fun resolveHourlyQuote(
      context: Context,
      widgetData: SharedPreferences,
  ): String {
    val pool = readQuotePool(widgetData)
    if (pool.isNotEmpty()) {
      val hourKey =
          SimpleDateFormat("yyyyMMddHH", Locale.US).format(Date())
      val index = abs(hourKey.hashCode()) % pool.size
      return pool[index]
    }
    return widgetData.getString("quoteText", null)
        ?: context.getString(R.string.widget_placeholder_quote)
  }

  private fun readQuotePool(widgetData: SharedPreferences): List<String> {
    val raw = widgetData.getString("quotePool", null) ?: return emptyList()
    return try {
      val array = JSONArray(raw)
      buildList {
        for (i in 0 until array.length()) {
          val text = array.optString(i).trim()
          if (text.isNotEmpty()) add(text)
        }
      }
    } catch (_: Exception) {
      emptyList()
    }
  }

  private fun buildBubbleBitmap(
      context: Context,
      widthDp: Int,
      heightDp: Int,
      fill: Int,
      border: Int,
  ): Bitmap {
    val density = context.resources.displayMetrics.density
    val width = TypedValue.applyDimension(
        TypedValue.COMPLEX_UNIT_DIP,
        widthDp.toFloat(),
        context.resources.displayMetrics,
    ).toInt().coerceAtLeast(1)
    val height = TypedValue.applyDimension(
        TypedValue.COMPLEX_UNIT_DIP,
        heightDp.toFloat(),
        context.resources.displayMetrics,
    ).toInt().coerceAtLeast(1)

    val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bitmap)

    val radius = 12f * density
    val tailHeight = 14f * density
    val bodyBottom = height - tailHeight
    val tailAnchor = 18f * density
    val tipX = 8f * density

    val path =
        Path().apply {
          moveTo(radius, 0f)
          lineTo(width - radius, 0f)
          quadTo(width.toFloat(), 0f, width.toFloat(), radius)
          lineTo(width.toFloat(), bodyBottom - radius)
          quadTo(width.toFloat(), bodyBottom, width - radius, bodyBottom)
          lineTo(tailAnchor + 22f * density, bodyBottom)
          cubicTo(
              tailAnchor + 14f * density,
              bodyBottom + 1f * density,
              tipX + 10f * density,
              bodyBottom + tailHeight * 0.55f,
              tipX,
              height - 1f * density,
          )
          cubicTo(
              tipX + 2f * density,
              bodyBottom + tailHeight * 0.45f,
              tailAnchor + 2f * density,
              bodyBottom + 1f * density,
              tipX,
              bodyBottom,
          )
          lineTo(radius, bodyBottom)
          quadTo(0f, bodyBottom, 0f, bodyBottom - radius)
          lineTo(0f, radius)
          quadTo(0f, 0f, radius, 0f)
          close()
        }

    canvas.drawPath(
        Path(path).apply { offset(2f * density, 3f * density) },
        Paint(Paint.ANTI_ALIAS_FLAG).apply { color = 0x14000000 },
    )
    canvas.drawPath(
        path,
        Paint(Paint.ANTI_ALIAS_FLAG).apply {
          color = fill
          style = Paint.Style.FILL
        },
    )
    canvas.drawPath(
        path,
        Paint(Paint.ANTI_ALIAS_FLAG).apply {
          color = border
          style = Paint.Style.STROKE
          strokeWidth = 1.5f * density
          strokeJoin = Paint.Join.ROUND
        },
    )

    return bitmap
  }

  private fun readColor(prefs: SharedPreferences, key: String, default: Int): Int {
    return try {
      when (val raw = prefs.all[key]) {
        is String -> {
          val cleaned = raw.removePrefix("#")
          (cleaned.toLong(16) and 0xFFFFFFFFL).toInt()
        }
        is Int -> raw
        is Long -> raw.toInt()
        else -> default
      }
    } catch (_: Exception) {
      default
    }
  }

  companion object {
    const val ACTION_HOURLY_REFRESH =
        "com.quotation.quotation.ACTION_HOURLY_WIDGET_REFRESH"

    private const val DEFAULT_ACCENT = 0xFF5B8DEF.toInt()
    private const val DEFAULT_BORDER = 0xFFB8C0CE.toInt()
    private const val DEFAULT_WINDOW_BAR = 0xFFBFD4F5.toInt()
    private const val HOUR_MS = AlarmManager.INTERVAL_HOUR

    fun scheduleHourlyRefresh(context: Context) {
      val alarmManager = context.getSystemService(AlarmManager::class.java) ?: return
      val pending = hourlyPendingIntent(context)
      val now = System.currentTimeMillis()
      val nextHour = ((now / HOUR_MS) + 1) * HOUR_MS
      alarmManager.setInexactRepeating(
          AlarmManager.RTC,
          nextHour,
          HOUR_MS,
          pending,
      )
    }

    fun cancelHourlyRefresh(context: Context) {
      val alarmManager = context.getSystemService(AlarmManager::class.java) ?: return
      alarmManager.cancel(hourlyPendingIntent(context))
    }

    private fun hourlyPendingIntent(context: Context): PendingIntent {
      val intent =
          Intent(context, DailyWordWidgetProvider::class.java).apply {
            action = ACTION_HOURLY_REFRESH
          }
      return PendingIntent.getBroadcast(
          context,
          7101,
          intent,
          PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
      )
    }
  }
}
