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
import android.graphics.Rect
import android.graphics.Typeface
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import android.text.TextUtils
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

    /**
     * Same layout as the app home card: one dashed quote box, the character
     * standing in front of its left edge, name tag on the box's bottom line.
     * No favorite paw on the widget. Long quotes shrink to fit instead of
     * scrolling, since home widgets cannot scroll.
     */
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
      val nickname = prefString(widgetData, "nickname")

      // Quote box. Character sits in front of its left part.
      val stroke = dp(1.4f)
      val boxLeft = width * 0.21f
      val box = RectF(boxLeft, stroke, width - stroke, height - stroke)
      val fill =
          Paint().apply {
            color = 0xFFFFFFFF.toInt()
            style = Paint.Style.FILL
            isAntiAlias = true
          }
      canvas.drawRoundRect(box, dp(14f), dp(14f), fill)
      drawDashedRoundRect(canvas, box, dp(14f), frame, stroke, dp(5f), dp(3.5f))

      // Character + name tag take three quarters of the box height.
      val tagHeight = dp(22f)
      val tagGap = dp(2f)
      val groupHeight = box.height() * 0.75f
      val bodyHeight = (groupHeight - tagGap - tagHeight).coerceAtLeast(dp(24f))
      val art =
          DdayWidgetVisuals.characterBitmap(
              context = context,
              characterId = characterId,
              widthDp = 160,
              heightDp = 160,
              isPixel = true,
          )
      val ink = inkBounds(art)
      val bodyScale = bodyHeight / ink.height().coerceAtLeast(1)
      val bodyWidth = ink.width() * bodyScale
      // Right side always reaches into the box; wide bodies start at the edge.
      val bodyLeft = (boxLeft + dp(22f) - bodyWidth).coerceAtLeast(0f)
      val bodyRight = bodyLeft + bodyWidth
      val bodyTop = box.bottom - groupHeight
      canvas.drawBitmap(
          art,
          ink,
          RectF(bodyLeft, bodyTop, bodyRight, bodyTop + bodyHeight),
          Paint().apply {
            isFilterBitmap = false
            isAntiAlias = false
          },
      )
      art.recycle()

      if (nickname.isNotEmpty()) {
        val tagPaint =
            TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
              color = QUOTE_COLOR
              textSize = dp(12f)
              setTypeface(face)
              isFakeBoldText = !pixel
            }
        val padX = dp(8f)
        val center = bodyLeft + bodyWidth / 2f
        // Never past the body's right side, so it cannot reach the quote.
        val maxTag = ((bodyRight + dp(4f) - center) * 2f).coerceAtLeast(dp(48f))
        val label =
            TextUtils.ellipsize(nickname, tagPaint, maxTag - padX * 2f, TextUtils.TruncateAt.END)
                .toString()
        val tagWidth = tagPaint.measureText(label) + padX * 2f
        val tagRect =
            RectF(
                center - tagWidth / 2f,
                box.bottom - tagHeight,
                center + tagWidth / 2f,
                box.bottom,
            )
        canvas.drawRoundRect(tagRect, dp(10f), dp(10f), fill)
        canvas.drawRoundRect(
            tagRect,
            dp(10f),
            dp(10f),
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
              color = (accent and 0x00FFFFFF) or (0x8C shl 24)
              style = Paint.Style.STROKE
              strokeWidth = stroke
            },
        )
        val baseline =
            tagRect.centerY() - (tagPaint.ascent() + tagPaint.descent()) / 2f
        canvas.drawText(label, tagRect.left + padX, baseline, tagPaint)
      }

      // Date on the top line of the box, clear of the character.
      val textLeft = box.left + (bodyRight - boxLeft + dp(8f)).coerceAtLeast(dp(12f))
      val textRight = box.right - dp(10f)
      val datePaint =
          Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = DATE_COLOR
            textSize = dp(if (heightDp < 140) 11f else 13f)
            setTypeface(face)
            isFakeBoldText = !pixel
          }
      val dateRow = RectF(textLeft, box.top + dp(8f), textRight, box.top + dp(30f))
      val dateY = dateRow.centerY() - (datePaint.ascent() + datePaint.descent()) / 2f
      canvas.drawText(homeDateLabel(), textLeft, dateY, datePaint)

      // Quote: start at the app size and shrink until every line fits.
      val quoteTop = dateRow.bottom + dp(6f)
      val quoteBottom = box.bottom - dp(10f)
      drawFitted(
          canvas = canvas,
          text = quote,
          face = face,
          fakeBold = !pixel,
          left = textLeft,
          top = quoteTop,
          maxWidth = (textRight - textLeft).coerceAtLeast(dp(24f)),
          maxHeight = (quoteBottom - quoteTop).coerceAtLeast(dp(12f)),
          startSize = dp(if (heightDp < 140) 13f else 15f),
          minSize = dp(7f),
      )
      return bitmap
    }

    /** Opaque bounds of [bitmap] (alpha > 10), or the whole bitmap. */
    private fun inkBounds(bitmap: Bitmap): Rect {
      val w = bitmap.width
      val h = bitmap.height
      val row = IntArray(w)
      var minX = w
      var minY = h
      var maxX = -1
      var maxY = -1
      for (y in 0 until h) {
        bitmap.getPixels(row, 0, w, 0, y, w, 1)
        for (x in 0 until w) {
          if ((row[x] ushr 24) > 10) {
            if (x < minX) minX = x
            if (x > maxX) maxX = x
            if (y < minY) minY = y
            if (y > maxY) maxY = y
          }
        }
      }
      if (maxX < 0) return Rect(0, 0, w, h)
      return Rect(minX, minY, maxX + 1, maxY + 1)
    }

    /** Draws [text] wrapped in the box, shrinking the size until it all fits. */
    private fun drawFitted(
        canvas: Canvas,
        text: String,
        face: Typeface,
        fakeBold: Boolean,
        left: Float,
        top: Float,
        maxWidth: Float,
        maxHeight: Float,
        startSize: Float,
        minSize: Float,
    ) {
      val paint =
          TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = QUOTE_COLOR
            setTypeface(face)
            isFakeBoldText = fakeBold
          }
      val width = maxWidth.roundToInt().coerceAtLeast(1)
      fun build(): StaticLayout =
          StaticLayout.Builder.obtain(text, 0, text.length, paint, width)
              .setAlignment(Layout.Alignment.ALIGN_NORMAL)
              .setLineSpacing(0f, 1.35f)
              .setIncludePad(false)
              .build()
      var size = startSize
      paint.textSize = size
      var layout = build()
      while (layout.height > maxHeight && size > minSize) {
        size = max(minSize, size - max(0.5f, size * 0.06f))
        paint.textSize = size
        layout = build()
      }
      canvas.save()
      canvas.translate(left, top)
      canvas.clipRect(0f, 0f, maxWidth, maxHeight)
      layout.draw(canvas)
      canvas.restore()
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
