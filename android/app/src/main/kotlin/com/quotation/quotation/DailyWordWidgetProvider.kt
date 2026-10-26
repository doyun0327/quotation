package com.quotation.quotation

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.PorterDuff
import android.graphics.PorterDuffColorFilter
import android.net.Uri
import android.graphics.BlurMaskFilter
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.util.TypedValue
import android.widget.RemoteViews
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
              setOnClickPendingIntent(R.id.widget_character, pendingIntent)
              setOnClickPendingIntent(R.id.widget_bubble_stack, pendingIntent)
              setOnClickPendingIntent(R.id.widget_bubble_bg, pendingIntent)
              setOnClickPendingIntent(R.id.widget_quote, pendingIntent)

              val quoteText =
                  widgetData.getString("quoteText", null)?.trim().orEmpty().ifEmpty {
                    widgetData.getString("flutter.quoteText", null)?.trim().orEmpty()
                  }.ifEmpty {
                    context.getString(R.string.widget_placeholder_quote)
                  }

              setTextViewText(R.id.widget_quote, quoteText)
              val characterId =
                  widgetData.getString("characterId", null)?.trim().orEmpty().ifEmpty {
                    widgetData.getString("flutter.characterId", null)?.trim().orEmpty()
                  }.ifEmpty { "basic" }
              setImageViewBitmap(
                  R.id.widget_character,
                  DdayWidgetVisuals.fitBitmap(
                      DdayWidgetVisuals.characterBitmap(
                          context = context,
                          characterId = characterId,
                          widthDp = 112,
                          heightDp = 148,
                          isPixel = false,
                      ),
                      280,
                  ),
              )

              val options = appWidgetManager.getAppWidgetOptions(widgetId)
              val maxWidthDp =
                  options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, 250)
              val bubbleWidthDp = (maxWidthDp - 98).coerceAtLeast(140)
              val bubbleHeightDp = 118
              applyHomeBubble(
                  context = context,
                  views = this,
                  widgetData = widgetData,
                  widthDp = bubbleWidthDp,
                  heightDp = bubbleHeightDp,
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

    private const val DEFAULT_BORDER = 0xFFB8C0CE.toInt()
    private const val DEFAULT_ACCENT = 0xFF5B8DEF.toInt()
    private const val HOUR_MS = AlarmManager.INTERVAL_HOUR

    fun applyHomeBubble(
        context: Context,
        views: RemoteViews,
        widgetData: SharedPreferences,
        widthDp: Int,
        heightDp: Int,
    ) {
      val border = readColor(widgetData, "themeBorder", DEFAULT_BORDER)
      val accent = readColor(widgetData, "themeAccent", DEFAULT_ACCENT)
      val style =
          widgetData.getString("visualStyle", null)?.trim().orEmpty().ifEmpty {
            widgetData.getString("flutter.visualStyle", null)?.trim().orEmpty()
          }
      views.setImageViewBitmap(
          R.id.widget_bubble_bg,
          DdayWidgetVisuals.fitBitmap(
              buildBubbleBitmap(
                  context = context,
                  widthDp = widthDp,
                  heightDp = heightDp,
                  fill = 0xFFFFFFFF.toInt(),
                  border = border,
                  accent = accent,
                  clean = style == "clean",
              ),
              360,
          ),
      )
    }

    private fun buildBubbleBitmap(
        context: Context,
        widthDp: Int,
        heightDp: Int,
        fill: Int,
        border: Int,
        accent: Int,
        clean: Boolean,
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
      val radius = (if (clean) 22f else 14f) * density
      val tailHeight = 12f * density
      val bodyBottom = height - tailHeight
      val tailAnchor = 16f * density
      val tipX = 6f * density

      val path =
          Path().apply {
            moveTo(radius, 0f)
            lineTo(width - radius, 0f)
            quadTo(width.toFloat(), 0f, width.toFloat(), radius)
            lineTo(width.toFloat(), bodyBottom - radius)
            quadTo(width.toFloat(), bodyBottom, width - radius, bodyBottom)
            lineTo(tailAnchor + 20f * density, bodyBottom)
            cubicTo(
                tailAnchor + 12f * density,
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

      val shadow = Paint().apply {
        color = if (clean) 0x18000000 else 0x14000000
        isAntiAlias = clean
        if (clean) {
          maskFilter = BlurMaskFilter(6f * density, BlurMaskFilter.Blur.NORMAL)
        }
      }
      canvas.drawPath(
          Path(path).apply {
            offset(if (clean) 0f else 2f * density, if (clean) 2f * density else 3f * density)
          },
          shadow,
      )
      canvas.drawPath(
          path,
          Paint().apply {
            color = fill
            style = Paint.Style.FILL
            isAntiAlias = clean
          },
      )
      canvas.drawPath(
          path,
          Paint().apply {
            color = border
            style = Paint.Style.STROKE
            strokeWidth = (if (clean) 1f else 1.5f) * density
            strokeJoin = Paint.Join.ROUND
            isAntiAlias = clean
          },
      )
      drawThemePaw(
          context = context,
          canvas = canvas,
          color = accent,
          right = width - 10f * density,
          bottom = bodyBottom - 6f * density,
          sizeDp = 16f,
      )
      return bitmap
    }

    private fun drawThemePaw(
        context: Context,
        canvas: Canvas,
        color: Int,
        right: Float,
        bottom: Float,
        sizeDp: Float,
    ) {
      val density = context.resources.displayMetrics.density
      val size = (sizeDp * density).toInt().coerceAtLeast(1)
      val source =
          DdayWidgetVisuals.decodeFlutterAsset(
              context,
              "assets/images/like/hamfoot.png",
          ) ?: return
      val scaled =
          if (source.width == size && source.height == size) {
            source
          } else {
            Bitmap.createScaledBitmap(source, size, size, false)
          }
      val paint =
          Paint().apply {
            colorFilter = PorterDuffColorFilter(color, PorterDuff.Mode.SRC_IN)
            isFilterBitmap = false
            isAntiAlias = false
          }
      canvas.drawBitmap(scaled, right - size, bottom - size, paint)
      if (scaled != source) scaled.recycle()
      source.recycle()
    }

    private fun prefString(prefs: SharedPreferences, key: String): String {
      return prefs.getString(key, null)?.trim().orEmpty().ifEmpty {
        prefs.getString("flutter.$key", null)?.trim().orEmpty()
      }
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

    fun buildPinBitmap(
        context: Context,
        widgetData: SharedPreferences,
        quote: String,
        characterId: String,
    ): Bitmap {
      val density = context.resources.displayMetrics.density.coerceAtLeast(0.5f)
      val width = (200f * density).toInt().coerceAtLeast(1)
      val height = (86f * density).toInt().coerceAtLeast(1)
      val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
      val canvas = Canvas(bitmap)
      val character =
          DdayWidgetVisuals.characterBitmap(
              context = context,
              characterId = characterId.ifBlank { "basic" },
              widthDp = 62,
              heightDp = 80,
              isPixel = false,
          )
      canvas.drawBitmap(
          character,
          0f,
          (height - character.height).toFloat().coerceAtLeast(0f),
          null,
      )
      val border = readColor(widgetData, "themeBorder", DEFAULT_BORDER)
      val accent = readColor(widgetData, "themeAccent", DEFAULT_ACCENT)
      val style =
          widgetData.getString("visualStyle", null)?.trim().orEmpty().ifEmpty {
            widgetData.getString("flutter.visualStyle", null)?.trim().orEmpty()
          }
      val bubbleLeft = (character.width - 8f * density).coerceAtLeast(0f)
      val bubble =
          buildBubbleBitmap(
              context = context,
              widthDp = ((width - bubbleLeft) / density).toInt().coerceAtLeast(80),
              heightDp = 74,
              fill = 0xFFFFFFFF.toInt(),
              border = border,
              accent = accent,
              clean = style == "clean",
          )
      canvas.drawBitmap(bubble, bubbleLeft, 2f * density, null)
      val textPaint =
          Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = 0xFF2C3340.toInt()
            textSize = 11f * density
            isFakeBoldText = true
          }
      drawWrapped(
          canvas = canvas,
          text = quote.ifBlank { context.getString(R.string.widget_placeholder_quote) },
          paint = textPaint,
          x = bubbleLeft + 10f * density,
          y = 18f * density,
          maxWidth = (width - 12f * density) - (bubbleLeft + 10f * density),
          maxLines = 3,
      )
      if (character != bitmap) character.recycle()
      if (bubble != bitmap) bubble.recycle()
      return bitmap
    }

    private fun drawWrapped(
        canvas: Canvas,
        text: String,
        paint: Paint,
        x: Float,
        y: Float,
        maxWidth: Float,
        maxLines: Int,
    ) {
      if (maxWidth <= 0f || text.isEmpty()) return
      var line = ""
      var top = y
      var lines = 0
      for (ch in text) {
        if (ch == '\n') {
          canvas.drawText(line, x, top, paint)
          lines++
          if (lines >= maxLines) return
          line = ""
          top += paint.textSize * 1.25f
          continue
        }
        val trial = line + ch
        if (line.isNotEmpty() && paint.measureText(trial) > maxWidth) {
          canvas.drawText(line, x, top, paint)
          lines++
          if (lines >= maxLines) return
          line = ch.toString()
          top += paint.textSize * 1.25f
        } else {
          line = trial
        }
      }
      if (line.isNotEmpty() && lines < maxLines) {
        canvas.drawText(line, x, top, paint)
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
