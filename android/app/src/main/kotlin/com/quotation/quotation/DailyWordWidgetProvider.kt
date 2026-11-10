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
import android.os.Build
import android.os.Bundle
import android.util.TypedValue
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.util.Calendar
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

open class DailyWordWidgetProvider : HomeWidgetProvider() {
  override fun onEnabled(context: Context) {
    super.onEnabled(context)
    scheduleHourlyRefresh(context)
  }

  override fun onDisabled(context: Context) {
    if (!hasQuoteFamilyWidgets(context)) cancelHourlyRefresh(context)
    super.onDisabled(context)
  }

  override fun onReceive(context: Context, intent: Intent?) {
    if (intent?.action == ACTION_HOURLY_REFRESH ||
        intent?.action == Intent.ACTION_BOOT_COMPLETED ||
        intent?.action == Intent.ACTION_MY_PACKAGE_REPLACED
    ) {
      scheduleHourlyRefresh(context)
      refreshQuoteFamily(context)
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
                  cardFor(context, widgetData, widthDp, heightDp),
              )
            }

        appWidgetManager.updateAppWidget(widgetId, views)
      } catch (e: Exception) {
        android.util.Log.e("DailyWordWidget", "update failed id=$widgetId", e)
      }
    }
  }
  /** The home-screen export keeps the app-style card; the picker sizes override. */
  protected open fun cardFor(
      context: Context,
      widgetData: SharedPreferences,
      widthDp: Int,
      heightDp: Int,
  ): Bitmap = buildHomeCard(context, widgetData, widthDp, heightDp)

  companion object {
    const val ACTION_HOURLY_REFRESH =
        "com.quotation.quotation.ACTION_HOURLY_WIDGET_REFRESH"

    private const val DEFAULT_ACCENT = 0xFF5B8DEF.toInt()
    private const val QUOTE_COLOR = 0xFF3C4C60.toInt()
    private const val DATE_COLOR = 0xFF8EA0B5.toInt()
    /** iOS dateColor (0.45, 0.55, 0.68). */
    private const val IOS_DATE_COLOR = 0xFF738CAD.toInt()
    private const val PAW_ASSET = "assets/images/like/hamfoot.png"
    private const val HOUR_MS = AlarmManager.INTERVAL_HOUR

    fun buildPinBitmap(
        context: Context,
        widgetData: SharedPreferences,
        bubble: Boolean = false,
    ): Bitmap {
      return buildHomeCard(
          context = context,
          widgetData = widgetData,
          widthDp = 300,
          heightDp = 168,
          bubble = bubble,
      )
    }

    /**
     * Same layout as the app home card: one dashed quote box, the character
     * standing in front of its left edge, name tag on the box's bottom line.
     * No favorite paw on the widget. Long quotes shrink to fit instead of
     * scrolling, since home widgets cannot scroll.
     * Used by the home-screen export (내보내기) and widgets already placed;
     * the picker's 오늘의 말 sizes draw [buildIosHomeCard] instead.
     */
    fun buildHomeCard(
        context: Context,
        widgetData: SharedPreferences,
        widthDp: Int,
        heightDp: Int,
        bubble: Boolean = false,
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

      // Quote box. The character sits in front of its left part, or with
      // [bubble], stands beside a speech bubble whose tail points at it.
      val stroke = dp(1.4f)
      val boxTop = stroke
      val boxBottom = height - stroke

      // Character + name tag take three quarters of the box height.
      val tagHeight = dp(22f)
      val tagGap = dp(2f)
      val groupHeight = (boxBottom - boxTop) * 0.75f
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
      val tailWidth = dp(10f)
      val boxLeft: Float
      val bodyLeft: Float
      val bodyTop: Float
      if (bubble) {
        // Same layout as the app home: the column is at least as wide as a
        // short name tag, and the bubble starts past the character and tail.
        val groupWidth = max(bodyWidth, dp(56f))
        bodyLeft = dp(2f) + (groupWidth - bodyWidth) / 2f
        boxLeft =
            (dp(2f) + groupWidth + dp(4f) + tailWidth)
                .coerceIn(width * 0.2f, width * 0.34f)
        bodyTop = boxTop + (boxBottom - boxTop - groupHeight) * 0.6f
      } else {
        boxLeft = width * 0.21f
        // Right side always reaches into the box; wide bodies start at the edge.
        bodyLeft = (boxLeft + dp(22f) - bodyWidth).coerceAtLeast(0f)
        bodyTop = boxBottom - groupHeight
      }
      val bodyRight = bodyLeft + bodyWidth
      val box = RectF(boxLeft, boxTop, width - stroke, boxBottom)
      val fill =
          Paint().apply {
            color = 0xFFFFFFFF.toInt()
            style = Paint.Style.FILL
            isAntiAlias = true
          }
      if (bubble) {
        val radius = dp(if (pixel) 18f else 22f)
        // Tail points at the character's face.
        val outline =
            bubblePath(box, radius, tailWidth, bodyTop + bodyHeight * 0.4f, dp(7f), stroke)
        canvas.drawPath(outline, fill)
        drawDashedPath(canvas, outline, frame, stroke, dp(5f), dp(3.5f))
      } else {
        canvas.drawRoundRect(box, dp(14f), dp(14f), fill)
        drawDashedRoundRect(canvas, box, dp(14f), frame, stroke, dp(5f), dp(3.5f))
      }
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
        // Never past the body's right side (or the bubble's tail), so it
        // cannot reach the quote.
        val tagEdge = if (bubble) boxLeft - tailWidth - dp(2f) else bodyRight + dp(4f)
        val maxTag = ((tagEdge - center) * 2f).coerceAtLeast(dp(48f))
        val label =
            TextUtils.ellipsize(nickname, tagPaint, maxTag - padX * 2f, TextUtils.TruncateAt.END)
                .toString()
        val tagWidth = tagPaint.measureText(label) + padX * 2f
        val tagTop = bodyTop + bodyHeight + tagGap
        val tagRect =
            RectF(
                center - tagWidth / 2f,
                tagTop,
                center + tagWidth / 2f,
                tagTop + tagHeight,
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
      val textLeft =
          if (bubble) {
            box.left + dp(14f)
          } else {
            box.left + (bodyRight - boxLeft + dp(8f)).coerceAtLeast(dp(12f))
          }
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

    /**
     * Same layout as the iPhone "오늘의 말" widget (DailyWordWidget.swift):
     * the character and nickname in a panel on the left, the date panel top
     * right and the quote panel with the paw below it. Every panel is a
     * dashed rounded box; the space around them stays transparent. Long
     * quotes shrink to fit instead of scrolling, since widgets cannot scroll.
     */
    fun buildIosHomeCard(
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
      // iOS: accent at 75% opacity for the dashes, panels white at 92%.
      val frame = (accent and 0x00FFFFFF) or (0xBF shl 24)
      val pixel = prefString(widgetData, "visualStyle") != "clean"
      val face = bodyTypeface(context, pixel)
      val quote =
          prefString(widgetData, "quoteText").ifEmpty {
            context.getString(R.string.widget_placeholder_quote)
          }
      val characterId = prefString(widgetData, "characterId").ifEmpty { "basic" }
      val nickname = prefString(widgetData, "nickname")

      val gap = dp(8f)
      val corner = dp(12f)
      val stroke = dp(1.5f)
      val panelFill =
          Paint().apply {
            color = 0xEBFFFFFF.toInt()
            style = Paint.Style.FILL
            isAntiAlias = true
          }
      fun panel(rect: RectF) {
        canvas.drawRoundRect(rect, corner, corner, panelFill)
        drawDashedRoundRect(canvas, rect, corner, frame, stroke, dp(5f), dp(3.5f))
      }

      val w = width.toFloat()
      val h = height.toFloat()
      val leftW = min(w * 0.30f, dp(110f))
      val rightW = max(w - leftW - gap * 3f, dp(80f))
      val dateH = dp(36f)
      val quoteH = max(h - dateH - gap * 3f, dp(40f))
      val leftBox = RectF(gap, gap, gap + leftW, h - gap)
      val rightX = leftBox.right + gap
      val dateBox = RectF(rightX, gap, rightX + rightW, gap + dateH)
      val quoteBox =
          RectF(rightX, dateBox.bottom + gap, rightX + rightW, dateBox.bottom + gap + quoteH)
      panel(leftBox)
      panel(dateBox)
      panel(quoteBox)

      // Left: character over the nickname, centered together.
      val namePaint =
          TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            color = QUOTE_COLOR
            textSize = dp(12f)
            setTypeface(face)
            isFakeBoldText = !pixel
          }
      val maxName = (leftW - dp(16f)).coerceAtLeast(dp(24f))
      // Like minimumScaleFactor(0.7): shrink a long name before cutting it.
      while (nickname.isNotEmpty() &&
          namePaint.measureText(nickname) > maxName &&
          namePaint.textSize > dp(8.4f)) {
        namePaint.textSize -= dp(0.5f)
      }
      val nameH = if (nickname.isEmpty()) 0f else namePaint.descent() - namePaint.ascent()
      val spacing = if (nickname.isEmpty()) 0f else dp(6f)
      val art =
          DdayWidgetVisuals.characterBitmap(
              context = context,
              characterId = characterId,
              widthDp = 160,
              heightDp = 160,
              isPixel = true,
          )
      val ink = inkBounds(art)
      val maxCharW = (leftW - dp(20f)) * 0.82f
      val maxCharH = (h - gap * 2f - dp(36f)) * 0.72f
      val fit =
          min(
              maxCharW / ink.width().coerceAtLeast(1),
              maxCharH / ink.height().coerceAtLeast(1),
          )
      val charW = ink.width() * fit
      val charH = ink.height() * fit
      val groupTop = leftBox.centerY() - (charH + spacing + nameH) / 2f
      val charLeft = leftBox.centerX() - charW / 2f
      canvas.drawBitmap(
          art,
          ink,
          RectF(charLeft, groupTop, charLeft + charW, groupTop + charH),
          Paint().apply {
            isFilterBitmap = false
            isAntiAlias = false
          },
      )
      art.recycle()
      if (nickname.isNotEmpty()) {
        val label =
            TextUtils.ellipsize(nickname, namePaint, maxName, TextUtils.TruncateAt.END)
                .toString()
        val baseline = groupTop + charH + spacing - namePaint.ascent()
        canvas.drawText(
            label,
            leftBox.centerX() - namePaint.measureText(label) / 2f,
            baseline,
            namePaint,
        )
      }

      // Top right: date, right-aligned.
      val datePaint =
          Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = IOS_DATE_COLOR
            textSize = dp(12f)
            setTypeface(face)
            isFakeBoldText = !pixel
          }
      val dateLabel = homeDateLabel()
      val dateY = dateBox.centerY() - (datePaint.ascent() + datePaint.descent()) / 2f
      canvas.drawText(
          dateLabel,
          dateBox.right - dp(10f) - datePaint.measureText(dateLabel),
          dateY,
          datePaint,
      )

      // Bottom right: quote from the top left, paw in the bottom-right corner.
      drawFitted(
          canvas = canvas,
          text = quote,
          face = face,
          fakeBold = !pixel,
          left = quoteBox.left + dp(10f),
          top = quoteBox.top + dp(8f),
          maxWidth = (quoteBox.width() - dp(20f)).coerceAtLeast(dp(24f)),
          maxHeight = (quoteBox.height() - dp(8f) - dp(22f)).coerceAtLeast(dp(12f)),
          startSize = dp(13f),
          minSize = dp(9f),
      )
      val paw = DdayWidgetVisuals.decodeFlutterAsset(context, PAW_ASSET)
      if (paw != null) {
        val size = dp(18f)
        val pad = dp(8f)
        canvas.drawBitmap(
            paw,
            null,
            RectF(
                quoteBox.right - pad - size,
                quoteBox.bottom - pad - size,
                quoteBox.right - pad,
                quoteBox.bottom - pad,
            ),
            Paint().apply {
              isFilterBitmap = false
              isAntiAlias = false
            },
        )
        paw.recycle()
      }
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
      return width.coerceIn(80, 640) to height.coerceIn(80, 640)
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
      dashAlong(canvas, path, paint, dash, gap)
    }

    private fun dashAlong(canvas: Canvas, path: Path, paint: Paint, dash: Float, gap: Float) {
      val measure = PathMeasure(path, false)
      val segment = Path()
      do {
        var distance = 0f
        while (distance < measure.length) {
          segment.reset()
          val end = min(distance + dash, measure.length)
          measure.getSegment(distance, end, segment, true)
          canvas.drawPath(segment, paint)
          distance += dash + gap
        }
      } while (measure.nextContour())
    }

    private fun drawDashedPath(
        canvas: Canvas,
        path: Path,
        color: Int,
        strokeWidth: Float,
        dash: Float,
        gap: Float,
    ) {
      val paint =
          Paint().apply {
            this.color = color
            style = Paint.Style.STROKE
            this.strokeWidth = strokeWidth
            strokeCap = Paint.Cap.BUTT
            isAntiAlias = false
          }
      dashAlong(canvas, path, paint, dash, gap)
    }

    /**
     * Rounded [box] plus a tail on its left edge at [tailY], reaching
     * [tailWidth] to the left. Mirrors the app's home quote bubble.
     */
    private fun bubblePath(
        box: RectF,
        radius: Float,
        tailWidth: Float,
        tailY: Float,
        tailHalf: Float,
        stroke: Float,
    ): Path {
      val inset = stroke / 2f
      val body = RectF(box.left + inset, box.top + inset, box.right - inset, box.bottom - inset)
      val low = body.top + radius + tailHalf
      val high = body.bottom - radius - tailHalf
      // Keep the tail on the straight part of the left edge.
      val y = if (low <= high) tailY.coerceIn(low, high) else body.centerY()
      val path = Path().apply { addRoundRect(body, radius, radius, Path.Direction.CW) }
      val tail =
          Path().apply {
            moveTo(body.left + 1f, y - tailHalf)
            lineTo(box.left - tailWidth + inset, y + tailHalf * 3f / 7f)
            lineTo(body.left + 1f, y + tailHalf)
            close()
          }
      path.op(tail, Path.Op.UNION)
      return path
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

    /** Dashed quote box only. Same card as the iOS "오늘의 문구" widget. */
    fun buildQuoteOnlyCard(
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
      val frame = (accent and 0x00FFFFFF) or (0xBF shl 24)
      val pixel = prefString(widgetData, "visualStyle") != "clean"
      val face = bodyTypeface(context, pixel)
      val quote =
          prefString(widgetData, "quoteText").ifEmpty {
            context.getString(R.string.widget_placeholder_quote)
          }
      val stroke = dp(1.5f)
      val inset = max(dp(8f), stroke + dp(4f))
      val box = RectF(inset, inset, width - inset, height - inset)
      canvas.drawRoundRect(
          box,
          dp(14f),
          dp(14f),
          Paint().apply {
            color = 0xEBFFFFFF.toInt()
            style = Paint.Style.FILL
            isAntiAlias = true
          },
      )
      drawDashedRoundRect(canvas, box, dp(14f), frame, stroke, dp(5f), dp(3.5f))
      val pad = dp(12f)
      drawFitted(
          canvas = canvas,
          text = quote,
          face = face,
          fakeBold = !pixel,
          left = box.left + pad,
          top = box.top + pad,
          maxWidth = (box.width() - pad * 2f).coerceAtLeast(dp(24f)),
          maxHeight = (box.height() - pad * 2f).coerceAtLeast(dp(12f)),
          startSize = dp(if (widthDp < 160) 13f else 15f),
          minSize = dp(8f),
      )
      return bitmap
    }

    fun quoteFamilyClasses(): List<Class<out android.appwidget.AppWidgetProvider>> =
        listOf(
            DailyWordWidgetProvider::class.java,
            DailyWordBubbleWidgetProvider::class.java,
            DailyWordWidgetProviderMedium::class.java,
            DailyWordWidgetProviderLarge::class.java,
            QuoteOnlyWidgetProvider::class.java,
            QuoteOnlyWidgetProviderMedium::class.java,
        )

    fun hasQuoteFamilyWidgets(context: Context): Boolean {
      val manager = AppWidgetManager.getInstance(context)
      return quoteFamilyClasses().any { clazz ->
        manager.getAppWidgetIds(ComponentName(context, clazz)).isNotEmpty()
      }
    }

    fun refreshQuoteFamily(context: Context) {
      val manager = AppWidgetManager.getInstance(context)
      for (clazz in quoteFamilyClasses()) {
        val ids = manager.getAppWidgetIds(ComponentName(context, clazz))
        if (ids.isEmpty()) continue
        val provider = clazz.getDeclaredConstructor().newInstance()
        provider.onUpdate(context, manager, ids)
      }
      publishPickerPreviews(context)
    }

    /** Fills the long-press widget gallery with the same cards the widgets draw. */
    fun publishPickerPreviews(context: Context) {
      if (Build.VERSION.SDK_INT < 35) return
      val manager = AppWidgetManager.getInstance(context)
      val prefs = HomeWidgetPlugin.getData(context)
      fun show(clazz: Class<*>, views: RemoteViews) {
        try {
          manager.setWidgetPreview(
              ComponentName(context, clazz),
              android.appwidget.AppWidgetProviderInfo.WIDGET_CATEGORY_HOME_SCREEN,
              views,
          )
        } catch (e: Exception) {
          android.util.Log.w("WidgetPreview", clazz.simpleName, e)
        }
      }
      // One entry per iPhone size, each drawn at the size it is placed at.
      // The export widget (DailyWordWidgetProvider) is hidden from the picker.
      show(
          DailyWordWidgetProviderMedium::class.java,
          previewCard(context, buildIosHomeCard(context, prefs, 300, 150), 300, 150),
      )
      show(
          DailyWordWidgetProviderLarge::class.java,
          previewCard(context, buildIosHomeCard(context, prefs, 300, 300), 300, 300),
      )
      show(
          QuoteOnlyWidgetProvider::class.java,
          previewCard(context, buildQuoteOnlyCard(context, prefs, 150, 150), 150, 150),
      )
      show(
          QuoteOnlyWidgetProviderMedium::class.java,
          previewCard(context, buildQuoteOnlyCard(context, prefs, 300, 150), 300, 150),
      )
      try {
        show(
            DdayWidgetProvider::class.java,
            DdayWidgetProvider().buildPinPreview(context, "s42"),
        )
      } catch (e: Exception) {
        android.util.Log.w("WidgetPreview", "together", e)
      }
    }

    private fun previewCard(
        context: Context,
        bitmap: Bitmap,
        widthDp: Int,
        heightDp: Int,
    ): RemoteViews {
      val density = context.resources.displayMetrics.density.coerceAtLeast(1f)
      val width = (widthDp * density).roundToInt().coerceAtLeast(1)
      val height = (heightDp * density).roundToInt().coerceAtLeast(1)
      return RemoteViews(context.packageName, R.layout.daily_word_widget).apply {
        setImageViewBitmap(R.id.widget_card, bitmap)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
          setViewLayoutWidth(R.id.widget_card, width.toFloat(), TypedValue.COMPLEX_UNIT_PX)
          setViewLayoutHeight(R.id.widget_card, height.toFloat(), TypedValue.COMPLEX_UNIT_PX)
        }
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

/** 오늘의 말 export with the quote in a speech bubble, like the app home. */
class DailyWordBubbleWidgetProvider : DailyWordWidgetProvider() {
  override fun cardFor(
      context: Context,
      widgetData: SharedPreferences,
      widthDp: Int,
      heightDp: Int,
  ): Bitmap =
      DailyWordWidgetProvider.buildHomeCard(
          context,
          widgetData,
          widthDp,
          heightDp,
          bubble = true,
      )
}

/** iOS systemMedium for 오늘의 말, as listed in the widget picker. */
class DailyWordWidgetProviderMedium : DailyWordWidgetProvider() {
  override fun cardFor(
      context: Context,
      widgetData: SharedPreferences,
      widthDp: Int,
      heightDp: Int,
  ): Bitmap =
      DailyWordWidgetProvider.buildIosHomeCard(context, widgetData, widthDp, heightDp)
}

/** iOS systemLarge for 오늘의 말. */
class DailyWordWidgetProviderLarge : DailyWordWidgetProvider() {
  override fun cardFor(
      context: Context,
      widgetData: SharedPreferences,
      widthDp: Int,
      heightDp: Int,
  ): Bitmap =
      DailyWordWidgetProvider.buildIosHomeCard(context, widgetData, widthDp, heightDp)
}
