package com.quotation.quotation

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.net.Uri
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PathMeasure
import android.graphics.RectF
import android.graphics.Typeface
import android.os.Bundle
import android.widget.RemoteViews
import java.util.Calendar
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

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
    scheduleHourlyRefresh(context)

    appWidgetIds.forEach { widgetId ->
      try {
        val views =
            RemoteViews(context.packageName, R.layout.daily_word_widget).apply {
              val quoteId = prefString(widgetData, "quoteId")
              val categoryId = prefString(widgetData, "categoryId")
              val subId = prefString(widgetData, "subCategoryId")
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

              val options = appWidgetManager.getAppWidgetOptions(widgetId)
              val (widthDp, heightDp) = widgetSizeDp(context, options)
              setImageViewBitmap(
                  R.id.widget_card,
                  buildHomeCard(
                      context = context,
                      widgetData = widgetData,
                      widthDp = widthDp,
                      heightDp = heightDp,
                  ),
              )
            }

        appWidgetManager.updateAppWidget(widgetId, views)
      } catch (e: Exception) {
        android.util.Log.e("DailyWordWidget", "update failed id=$widgetId", e)
      }
    }
  }
  companion object {
    const val ACTION_HOURLY_REFRESH =
        "com.quotation.quotation.ACTION_HOURLY_WIDGET_REFRESH"

    private const val DEFAULT_ACCENT = 0xFF5B8DEF.toInt()
    private const val DATE_COLOR = 0xFF8EA0B5.toInt()
    private const val QUOTE_COLOR = 0xFF3C4C60.toInt()
    private const val HOUR_MS = AlarmManager.INTERVAL_HOUR

    fun buildPinBitmap(
        context: Context,
        widgetData: SharedPreferences,
    ): Bitmap {
      return buildHomeCard(
          context = context,
          widgetData = widgetData,
          widthDp = 300,
          heightDp = 168,
      )
    }

    fun buildHomeCard(
        context: Context,
        widgetData: SharedPreferences,
        widthDp: Int,
        heightDp: Int,
    ): Bitmap {
      val metricsDensity =
          context.resources.displayMetrics.density.coerceAtLeast(1f)
      var scale = 1f
      var width = (widthDp * metricsDensity).roundToInt().coerceAtLeast(1)
      var height = (heightDp * metricsDensity).roundToInt().coerceAtLeast(1)
      while (width.toLong() * height > 420_000L && scale > 0.5f) {
        scale -= 0.08f
        width = (widthDp * metricsDensity * scale).roundToInt().coerceAtLeast(1)
        height = (heightDp * metricsDensity * scale).roundToInt().coerceAtLeast(1)
      }
      val d = metricsDensity * scale
      fun dp(value: Float) = value * d

      val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
      val canvas = Canvas(bitmap)
      val accent = readColor(widgetData, "themeAccent", DEFAULT_ACCENT)
      val frame = lerpWhite(accent, 0.42f)
      val pixel = prefString(widgetData, "visualStyle") != "clean"
      val face = bodyTypeface(context, pixel)
      val quote =
          prefString(widgetData, "quoteText").ifEmpty {
            context.getString(R.string.widget_placeholder_quote)
          }
      val characterId = prefString(widgetData, "characterId").ifEmpty { "basic" }

      val outer =
          RectF(dp(1.5f), dp(1.5f), width - dp(1.5f), height - dp(1.5f))
      val fill =
          Paint().apply {
            color = 0xFFFFFFFF.toInt()
            style = Paint.Style.FILL
            isAntiAlias = false
          }
      canvas.drawRoundRect(outer, dp(18f), dp(18f), fill)
      drawDashedRoundRect(canvas, outer, dp(18f), frame, dp(1.6f), dp(5f), dp(3.5f))

      val content =
          RectF(
              outer.left + dp(10f),
              outer.top + dp(10f),
              outer.right - dp(10f),
              outer.bottom - dp(10f),
          )
      val gap = dp(8f)
      val leftWidth = ((content.width() - gap) * 0.40f).coerceAtLeast(dp(48f))
      val left = RectF(content.left, content.top, content.left + leftWidth, content.bottom)
      val right = RectF(left.right + gap, content.top, content.right, content.bottom)
      var dateHeight = min(dp(38f), right.height() * 0.26f)
      if (right.height() - dateHeight - gap < dp(48f)) {
        dateHeight = (right.height() * 0.22f).coerceAtLeast(dp(28f))
      }
      val dateRect = RectF(right.left, right.top, right.right, right.top + dateHeight)
      val quoteRect =
          RectF(right.left, dateRect.bottom + gap, right.right, right.bottom)

      drawDashedRoundRect(canvas, left, dp(14f), frame, dp(1.4f), dp(5f), dp(3.5f))
      drawDashedRoundRect(canvas, dateRect, dp(14f), frame, dp(1.4f), dp(5f), dp(3.5f))
      drawDashedRoundRect(canvas, quoteRect, dp(14f), frame, dp(1.4f), dp(5f), dp(3.5f))

      val slotW = (left.width() - dp(16f)).roundToInt().coerceAtLeast(8)
      val slotH = (left.height() - dp(16f)).roundToInt().coerceAtLeast(8)
      val character =
          DdayWidgetVisuals.characterBitmap(
              context = context,
              characterId = characterId,
              widthDp = (slotW / metricsDensity).roundToInt().coerceAtLeast(8),
              heightDp = (slotH / metricsDensity).roundToInt().coerceAtLeast(8),
              isPixel = true,
          )
      val charLeft = left.centerX() - character.width / 2f
      val charTop = left.centerY() - character.height / 2f
      canvas.drawBitmap(
          character,
          null,
          RectF(charLeft, charTop, charLeft + character.width, charTop + character.height),
          Paint().apply {
            isFilterBitmap = false
            isAntiAlias = false
          },
      )
      if (character != bitmap) character.recycle()

      val datePaint =
          Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = DATE_COLOR
            textSize = dp(if (heightDp < 140) 11f else 13f)
            setTypeface(face)
            isFakeBoldText = !pixel
          }
      val dateLabel = homeDateLabel()
      val dateWidth = datePaint.measureText(dateLabel)
      val dateX =
          (dateRect.right - dp(12f) - dateWidth).coerceAtLeast(dateRect.left + dp(8f))
      val dateY = dateRect.centerY() - (datePaint.ascent() + datePaint.descent()) / 2f
      canvas.drawText(dateLabel, dateX, dateY, datePaint)

      val quotePaint =
          Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = QUOTE_COLOR
            textSize = dp(if (heightDp < 140) 13f else 15f)
            setTypeface(face)
            isFakeBoldText = !pixel
          }
      val textLeft = quoteRect.left + dp(14f)
      val textRight = quoteRect.right - dp(12f)
      val textTop = quoteRect.top + dp(10f)
      val textBottom = quoteRect.bottom - dp(12f)
      drawWrapped(
          canvas = canvas,
          text = quote,
          paint = quotePaint,
          x = textLeft,
          y = textTop - quotePaint.ascent(),
          maxWidth = (textRight - textLeft).coerceAtLeast(dp(24f)),
          maxBottom = textBottom,
          lineHeight = quotePaint.textSize * 1.35f,
      )
      return bitmap
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
              ?: max(minW, maxW).takeIf { it > 40 }
              ?: 300
      val height =
          (if (portrait) maxH else minH).takeIf { it > 40 }
              ?: max(minH, maxH).takeIf { it > 40 }
              ?: 168
      return width.coerceIn(180, 460) to height.coerceIn(120, 360)
    }

    private fun homeDateLabel(): String {
      val calendar = Calendar.getInstance()
      val year = calendar.get(Calendar.YEAR)
      val month = calendar.get(Calendar.MONTH) + 1
      val day = calendar.get(Calendar.DAY_OF_MONTH)
      return "$year. $month. $day"
    }

    /** Same mix as the home dashed frame: accent faded 42% toward white. */
    private fun lerpWhite(color: Int, amount: Float): Int {
      fun channel(shift: Int): Int {
        val value = (color shr shift) and 0xFF
        return (value + ((255 - value) * amount)).roundToInt().coerceIn(0, 255)
      }
      return (0xFF shl 24) or (channel(16) shl 16) or (channel(8) shl 8) or channel(0)
    }

    private fun bodyTypeface(context: Context, pixel: Boolean): Typeface {
      if (!pixel) return Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD)
      val paths =
          listOf(
              "flutter_assets/assets/fonts/Galmuri11.ttf",
              "fonts/Galmuri11.ttf",
          )
      for (path in paths) {
        try {
          return Typeface.createFromAsset(context.assets, path)
        } catch (_: Exception) {
          // try the next asset path
        }
      }
      return Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD)
    }

    private fun drawDashedRoundRect(
        canvas: Canvas,
        rect: RectF,
        radius: Float,
        color: Int,
        strokeWidth: Float,
        dash: Float,
        gap: Float,
    ) {
      if (rect.width() <= strokeWidth || rect.height() <= strokeWidth) return
      val paint =
          Paint().apply {
            this.color = color
            style = Paint.Style.STROKE
            this.strokeWidth = strokeWidth
            strokeCap = Paint.Cap.BUTT
            isAntiAlias = false
          }
      val inset = strokeWidth / 2f
      val inner =
          RectF(
              rect.left + inset,
              rect.top + inset,
              rect.right - inset,
              rect.bottom - inset,
          )
      val path =
          Path().apply {
            addRoundRect(inner, radius, radius, Path.Direction.CW)
          }
      val measure = PathMeasure(path, false)
      val segment = Path()
      var distance = 0f
      while (distance < measure.length) {
        segment.reset()
        val end = min(distance + dash, measure.length)
        measure.getSegment(distance, end, segment, true)
        canvas.drawPath(segment, paint)
        distance += dash + gap
      }
    }

    private fun drawWrapped(
        canvas: Canvas,
        text: String,
        paint: Paint,
        x: Float,
        y: Float,
        maxWidth: Float,
        maxBottom: Float,
        lineHeight: Float,
    ) {
      if (maxWidth <= 0f || text.isEmpty() || y > maxBottom) return
      val maxLines = ((maxBottom - (y + paint.ascent())) / lineHeight).toInt().coerceIn(1, 8)
      val lines = mutableListOf<String>()
      var line = ""
      var index = 0
      while (index < text.length && lines.size < maxLines) {
        val ch = text[index]
        if (ch == '\n') {
          lines.add(line)
          line = ""
          index++
          continue
        }
        val trial = line + ch
        if (line.isNotEmpty() && paint.measureText(trial) > maxWidth) {
          lines.add(line)
          line = ""
          continue
        }
        line = trial
        index++
      }
      if (line.isNotEmpty() && lines.size < maxLines) lines.add(line)
      if (index < text.length && lines.isNotEmpty()) {
        var trimmed = lines.last()
        while (trimmed.isNotEmpty() && paint.measureText("$trimmed…") > maxWidth) {
          trimmed = trimmed.dropLast(1)
        }
        lines[lines.lastIndex] = "$trimmed…"
      }
      var top = y
      for (row in lines) {
        if (top > maxBottom) break
        canvas.drawText(row, x, top, paint)
        top += lineHeight
      }
    }

    private fun prefString(prefs: SharedPreferences, key: String): String {
      return prefs.getString(key, null)?.trim().orEmpty().ifEmpty {
        prefs.getString("flutter.$key", null)?.trim().orEmpty()
      }
    }

    private fun readColor(prefs: SharedPreferences, key: String, default: Int): Int {
      val raw = prefs.all[key] ?: prefs.all["flutter.$key"]
      return try {
        when (raw) {
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
