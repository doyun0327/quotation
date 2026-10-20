package com.quotation.quotation

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.Typeface
import android.os.Build
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import android.util.TypedValue
import androidx.core.content.res.ResourcesCompat
import kotlin.math.max
import kotlin.math.min

/** Shared drawables/bitmaps for the D-Day home widget. */
object DdayWidgetVisuals {
  fun drawableFor(characterId: String): Int {
    return if (characterId == "bul") R.drawable.character_bul else R.drawable.character
  }

  /** Same cell grid as Flutter [TogetherWidgetSize]. */
  fun cellsForSize(sizeId: String): Pair<Int, Int> {
    return when (sizeId) {
      "s33", "sq", "s22" -> 3 to 3
      "s43", "xl", "s24" -> 4 to 3
      "s32", "m", "s23" -> 3 to 2
      "tall" -> 2 to 3
      "s" -> 2 to 2
      else -> 4 to 2 // s42 / l
    }
  }

  /** Android docs minimum: 70 × cells − 30. */
  fun spanDp(cells: Int): Int = 70 * cells - 30

  /**
   * Launcher round-clips every app widget to this radius (API 31+).
   * Our card corners must match or the border gets shaved at the arcs.
   */
  fun systemWidgetCornerPx(context: Context): Float {
    val density = context.resources.displayMetrics.density
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      try {
        return context.resources.getDimension(
            android.R.dimen.system_app_widget_background_radius,
        )
      } catch (_: Exception) {
        // OEM may not expose the dimen
      }
    }
    return 16f * density
  }

  /** Character base scale vs 4×2 — matches Flutter charFactor. */
  fun charFactor(sizeId: String): Float {
    val (cellsW, _) = cellsForSize(sizeId)
    return (cellsW / 4f).coerceIn(0.7f, 1.2f)
  }

  /**
   * Fallback canvas when launcher options are missing.
   * Uses screen-width / 4 cell (typical 4-column home) so the widget fills
   * like One UI — not the tiny 70×n−30 minimum.
   */
  fun previewSizeDp(
      shape: String,
      sizeId: String = "s42",
      screenWidthDp: Int = 360,
  ): Pair<Int, Int> {
    val (cellsW, cellsH) = cellsForSize(sizeId)
    val cell = (screenWidthDp / 4).coerceIn(80, 110)
    return (cell * cellsW).coerceAtLeast(8) to (cell * cellsH).coerceAtLeast(8)
  }

  /**
   * Actual host size from [AppWidgetManager] options — fill the cell.
   * Falls back to [previewSizeDp] when options are not ready yet.
   */
  fun hostSizeDp(
      appWidgetManager: android.appwidget.AppWidgetManager,
      widgetId: Int,
      sizeId: String,
      screenWidthDp: Int,
  ): Pair<Int, Int> {
    val fallback = previewSizeDp("square", sizeId, screenWidthDp)
    val options = appWidgetManager.getAppWidgetOptions(widgetId) ?: return fallback
    val minW = options.getInt(android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
    val maxW = options.getInt(android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, 0)
    val minH = options.getInt(android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
    val maxH = options.getInt(android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0)
    // Prefer the larger reported size so Samsung/One UI cells are filled edge-to-edge.
    val w = max(minW, maxW)
    val h = max(minH, maxH)
    if (w <= 0 || h <= 0) return fallback
    return w.coerceAtLeast(8) to h.coerceAtLeast(8)
  }

  /**
   * Full widget frame matching Flutter [TogetherWidgetPreview] pixel-for-pixel.
   * Shown with ImageView fitCenter so the launcher cannot stretch the aspect ratio.
   */
  fun buildTogetherWidgetBitmap(
      context: Context,
      shape: String,
      widthDp: Int,
      heightDp: Int,
      bgColorArgb: Int,
      bgOpacity: Int = 100,
      textColorArgb: Int = 0xFFF26B8A.toInt(),
      isPixel: Boolean,
      label: String,
      textScale: Int,
      textOffsetX: Int,
      textOffsetY: Int,
      meId: String,
      friendId: String,
      meOffsetX: Int,
      meOffsetY: Int,
      friendOffsetX: Int,
      friendOffsetY: Int,
      charScale: Int,
      sizeCharFactor: Float,
  ): Bitmap {
    val density = context.resources.displayMetrics.density
    val w = dp(context, widthDp).coerceAtLeast(8)
    val h = dp(context, heightDp).coerceAtLeast(8)
    val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bitmap)

    val strokeDp = if (isPixel) 2f else 1.5f
    val strokePx = strokeDp * density
    // Prefer alpha baked into ARGB (transparent swatch). Legacy: bgOpacity %.
    val bakedAlpha = (bgColorArgb ushr 24) and 0xFF
    val alpha =
        when {
          bakedAlpha == 0 -> 0
          bakedAlpha in 1..254 -> bakedAlpha
          else -> ((bgOpacity.coerceIn(0, 100) / 100f) * 255f).toInt().coerceIn(0, 255)
        }
    val fillArgb = (bgColorArgb and 0x00FFFFFF) or (alpha shl 24)
    val borderBase = borderColorForBg(bgColorArgb or -0x1000000)
    val borderAlpha = if (alpha == 0) 0x66 else alpha.coerceAtLeast(90)
    val borderArgb = (borderBase and 0x00FFFFFF) or (borderAlpha shl 24)

    val fillPaint =
        Paint(Paint.ANTI_ALIAS_FLAG).apply {
          color = fillArgb
          style = Paint.Style.FILL
          isAntiAlias = !isPixel
        }
    val borderFillPaint =
        Paint(Paint.ANTI_ALIAS_FLAG).apply {
          color = borderArgb
          style = Paint.Style.FILL
          isAntiAlias = !isPixel
        }
    // Launcher round-clips the host. Draw a full-bleed RECT for the border color
    // so One UI's clip creates the outer curve — never fight it with our own radius.
    val hostCorner =
        min(systemWidgetCornerPx(context), min(w, h) / 2f).coerceAtLeast(0f)
    val innerInset = strokePx.coerceAtLeast(density)
    val innerRect =
        RectF(
            innerInset,
            innerInset,
            w - innerInset,
            h - innerInset,
        )
    val innerCorner = (hostCorner - innerInset).coerceAtLeast(0f)

    if (alpha == 0) {
      val ring =
          Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = borderArgb
            style = Paint.Style.STROKE
            strokeWidth = strokePx
            isAntiAlias = !isPixel
          }
      val mid = strokePx / 2f
      val midR = (hostCorner - mid).coerceAtLeast(0f)
      canvas.drawRoundRect(RectF(mid, mid, w - mid, h - mid), midR, midR, ring)
    } else {
      // Border color fills the bitmap; host rounds the outer edge.
      canvas.drawColor(borderArgb)
      canvas.drawRoundRect(innerRect, innerCorner, innerCorner, fillPaint)
    }

    val clipPath = Path()
    clipPath.addRoundRect(innerRect, innerCorner, innerCorner, Path.Direction.CW)

    val originX = 0f
    val originY = 0f
    val contentW = w.toFloat()
    val contentH = h.toFloat()

    canvas.save()
    canvas.clipPath(clipPath)

    val scale = (charScale / 100f).coerceIn(0.6f, 1.6f)
    val charWDp = (72f * sizeCharFactor * scale).toInt().coerceAtLeast(20)
    val charHDp = (96f * sizeCharFactor * scale).toInt().coerceAtLeast(28)
    val charW = (charWDp * density).toInt().coerceAtLeast(8)
    val charH = (charHDp * density).toInt().coerceAtLeast(8)
    val charPaint =
        Paint().apply {
          isFilterBitmap = !isPixel
          isAntiAlias = !isPixel
        }

    val trimmed = label.trim()
    if (trimmed.isNotEmpty()) {
      val maxLabelDp = (widthDp - 32).coerceAtLeast(48)
      val labelBmp =
          buildLabelBitmap(
              context = context,
              text = trimmed,
              textScale = textScale,
              isPixel = isPixel,
              maxWidthDp = maxLabelDp,
              textColorArgb = textColorArgb,
          )
      val lx = originX + (contentW - labelBmp.width) / 2f + textOffsetX * density
      val ly = originY + (contentH - labelBmp.height) / 2f - textOffsetY * density
      canvas.drawBitmap(labelBmp, lx, ly, null)
      labelBmp.recycle()
    }

    val hasFriend = friendId.isNotBlank()
    if (hasFriend) {
      val heart =
          if (isPixel) {
            buildPixelHeartBitmap(context, sizeDp = 16)
          } else {
            buildCleanHeartBitmap(context, sizeDp = 14)
          }
      // Flutter Align center + Offset(-40, 0) for the heart widget's top-left.
      val hx = originX + contentW / 2f - 40f * density - heart.width / 2f
      val hy = originY + contentH / 2f - heart.height / 2f
      canvas.drawBitmap(heart, hx, hy, null)
      heart.recycle()
    }

    val meBmp =
        characterBitmap(
            context = context,
            characterId = meId,
            widthDp = charWDp,
            heightDp = charHDp,
            isPixel = isPixel,
        )
    val meLeft = originX + (4f + meOffsetX) * density
    val meTop = originY + contentH - meOffsetY * density - charH
    canvas.drawBitmap(meBmp, meLeft, meTop, charPaint)
    meBmp.recycle()

    if (hasFriend) {
      val friendBmp =
          characterBitmap(
              context = context,
              characterId = friendId,
              widthDp = charWDp,
              heightDp = charHDp,
              isPixel = isPixel,
          )
      // Flutter: right: 4 - friendX
      val friendLeft = originX + contentW - (4f - friendOffsetX) * density - charW
      val friendTop = originY + contentH - friendOffsetY * density - charH
      canvas.drawBitmap(friendBmp, friendLeft, friendTop, charPaint)
      friendBmp.recycle()
    }

    canvas.restore()
    return bitmap
  }

  /** Cheer text as bitmap so pixel (Galmuri) / clean fonts both work in RemoteViews. */
  fun buildLabelBitmap(
      context: Context,
      text: String,
      textScale: Int,
      isPixel: Boolean,
      maxWidthDp: Int,
      textColorArgb: Int = 0xFFF26B8A.toInt(),
  ): Bitmap {
    val density = context.resources.displayMetrics.density
    val maxWidth = (maxWidthDp * density).toInt().coerceAtLeast(32)
    val baseSp = if (isPixel) 16f else 22f
    val textSizePx = baseSp * (textScale / 100f) * density
    val face =
        if (isPixel) pixelTypeface(context) else Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
    val paint =
        TextPaint().apply {
          color = textColorArgb
          this.textSize = textSizePx
          typeface = face
          isAntiAlias = !isPixel
          isFilterBitmap = !isPixel
          isFakeBoldText = !isPixel
        }
    val layout =
        StaticLayout.Builder.obtain(text, 0, text.length, paint, maxWidth)
            .setAlignment(Layout.Alignment.ALIGN_CENTER)
            .setMaxLines(3)
            .setEllipsize(android.text.TextUtils.TruncateAt.END)
            .setIncludePad(false)
            .build()
    val width = maxWidth.coerceAtLeast(layout.width.coerceAtLeast(1))
    val height = layout.height.coerceAtLeast(1)
    val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bitmap)
    layout.draw(canvas)
    return bitmap
  }

  /** Character art; nearest-neighbor when pixel so sprites stay crisp. */
  fun characterBitmap(
      context: Context,
      characterId: String,
      widthDp: Int,
      heightDp: Int,
      isPixel: Boolean,
  ): Bitmap {
    val resId = drawableFor(characterId)
    val w = dp(context, widthDp).coerceAtLeast(8)
    val h = dp(context, heightDp).coerceAtLeast(8)
    val src =
        BitmapFactory.decodeResource(context.resources, resId)
            ?: run {
              val drawable =
                  ResourcesCompat.getDrawable(context.resources, resId, null)
              val bw = drawable?.intrinsicWidth?.coerceAtLeast(1) ?: w
              val bh = drawable?.intrinsicHeight?.coerceAtLeast(1) ?: h
              val bmp = Bitmap.createBitmap(bw, bh, Bitmap.Config.ARGB_8888)
              val canvas = Canvas(bmp)
              drawable?.setBounds(0, 0, bw, bh)
              drawable?.draw(canvas)
              bmp
            }
    val out = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(out)
    val paint =
        Paint().apply {
          isFilterBitmap = !isPixel
          isAntiAlias = !isPixel
        }
    // BoxFit.contain — same as Flutter Image.asset fit.
    val scale = min(w.toFloat() / src.width, h.toFloat() / src.height)
    val dw = (src.width * scale).toInt().coerceAtLeast(1)
    val dh = (src.height * scale).toInt().coerceAtLeast(1)
    val left = (w - dw) / 2
    val top = (h - dh) / 2
    canvas.drawBitmap(src, null, Rect(left, top, left + dw, top + dh), paint)
    if (src != out) src.recycle()
    return out
  }

  @Volatile private var cachedPixelTypeface: Typeface? = null

  private fun pixelTypeface(context: Context): Typeface {
    cachedPixelTypeface?.let { return it }
    val assetPaths =
        listOf(
            "fonts/Galmuri11.ttf",
            "flutter_assets/assets/fonts/Galmuri11.ttf",
            "fonts/PressStart2P-Regular.ttf",
            "flutter_assets/assets/fonts/PressStart2P-Regular.ttf",
        )
    for (path in assetPaths) {
      try {
        val face = Typeface.createFromAsset(context.assets, path)
        cachedPixelTypeface = face
        return face
      } catch (_: Exception) {
        // try next
      }
    }
    try {
      ResourcesCompat.getFont(context, R.font.galmuri11)?.let {
        cachedPixelTypeface = it
        return it
      }
    } catch (_: Exception) {
      // ignore
    }
    try {
      ResourcesCompat.getFont(context, R.font.press_start_2p)?.let {
        cachedPixelTypeface = it
        return it
      }
    } catch (_: Exception) {
      // ignore
    }
    android.util.Log.e("DdayWidget", "Pixel font missing; widget text will look non-pixel")
    return Typeface.DEFAULT
  }

  fun parseArgb(hex: String?, default: Int = 0xFFFFF3E8.toInt()): Int {
    if (hex.isNullOrBlank()) return default
    return try {
      val cleaned = hex.trim().removePrefix("#")
      val value = cleaned.toLong(16)
      when (cleaned.length) {
        6 -> (0xFF000000 or value).toInt()
        8 -> value.toInt()
        else -> default
      }
    } catch (_: Exception) {
      default
    }
  }

  /**
   * Slightly darker tone of the fill — matches Flutter
   * [TogetherWidgetPreview.borderColorForBg] (HSL, not HSV).
   */
  fun borderColorForBg(bgArgb: Int): Int {
    val r = Color.red(bgArgb) / 255f
    val g = Color.green(bgArgb) / 255f
    val b = Color.blue(bgArgb) / 255f
    val (h, s, l) = rgbToHsl(r, g, b)
    val newL = (l * 0.78f).coerceIn(0.15f, 0.92f)
    val newS = (s * 1.05f).coerceIn(0f, 1f)
    val (nr, ng, nb) = hslToRgb(h, newS, newL)
    return Color.argb(
        Color.alpha(bgArgb),
        (nr * 255f + 0.5f).toInt().coerceIn(0, 255),
        (ng * 255f + 0.5f).toInt().coerceIn(0, 255),
        (nb * 255f + 0.5f).toInt().coerceIn(0, 255),
    )
  }

  private fun rgbToHsl(r: Float, g: Float, b: Float): FloatArray {
    val maxC = max(r, max(g, b))
    val minC = min(r, min(g, b))
    val l = (maxC + minC) / 2f
    if (maxC == minC) return floatArrayOf(0f, 0f, l)
    val d = maxC - minC
    val s = if (l > 0.5f) d / (2f - maxC - minC) else d / (maxC + minC)
    val h =
        when (maxC) {
          r -> ((g - b) / d + if (g < b) 6f else 0f) / 6f
          g -> ((b - r) / d + 2f) / 6f
          else -> ((r - g) / d + 4f) / 6f
        }
    return floatArrayOf(h, s, l)
  }

  private fun hslToRgb(h: Float, s: Float, l: Float): FloatArray {
    if (s == 0f) return floatArrayOf(l, l, l)
    val q = if (l < 0.5f) l * (1f + s) else l + s - l * s
    val p = 2f * l - q
    return floatArrayOf(
        hueToRgb(p, q, h + 1f / 3f),
        hueToRgb(p, q, h),
        hueToRgb(p, q, h - 1f / 3f),
    )
  }

  private fun hueToRgb(p: Float, q: Float, tIn: Float): Float {
    var t = tIn
    if (t < 0f) t += 1f
    if (t > 1f) t -= 1f
    return when {
      t < 1f / 6f -> p + (q - p) * 6f * t
      t < 1f / 2f -> q
      t < 2f / 3f -> p + (q - p) * (2f / 3f - t) * 6f
      else -> p
    }
  }

  fun buildPixelHeartBitmap(context: Context, sizeDp: Int = 16): Bitmap {
    val rows =
        arrayOf(
            "................",
            "...RRR....RRR...",
            "..RRRRR..RRRRR..",
            ".RRRRRRRRRRRRRR.",
            ".RRRRRRRRRRRRRR.",
            "..RRRRRRRRRRRR..",
            "...RRRRRRRRRR...",
            "....RRRRRRRR....",
            ".....RRRRRR.....",
            "......RRRR......",
            ".......RR.......",
            "................",
            "................",
            "................",
            "................",
            "................",
        )
    val size = dp(context, sizeDp).coerceAtLeast(12)
    val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bitmap)
    val cell = size / 16f
    val paint = Paint().apply {
      style = Paint.Style.FILL
      isAntiAlias = false
      isFilterBitmap = false
    }
    val color = 0xFFE85A7A.toInt()
    for (y in rows.indices) {
      val row = rows[y]
      for (x in row.indices) {
        if (row[x] != 'R') continue
        paint.color = color
        canvas.drawRect(x * cell, y * cell, (x + 1) * cell + 0.3f, (y + 1) * cell + 0.3f, paint)
      }
    }
    return bitmap
  }

  fun buildCleanHeartBitmap(context: Context, sizeDp: Int = 14): Bitmap {
    val size = dp(context, sizeDp).coerceAtLeast(12)
    val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bitmap)
    val paint =
        Paint(Paint.ANTI_ALIAS_FLAG).apply {
          color = 0xFFF5A0B8.toInt()
          style = Paint.Style.FILL
        }
    val w = size.toFloat()
    val h = size.toFloat()
    val path =
        Path().apply {
          moveTo(w * 0.5f, h * 0.82f)
          cubicTo(w * 0.12f, h * 0.58f, w * 0.05f, h * 0.28f, w * 0.32f, h * 0.18f)
          cubicTo(w * 0.42f, h * 0.12f, w * 0.5f, h * 0.22f, w * 0.5f, h * 0.32f)
          cubicTo(w * 0.5f, h * 0.22f, w * 0.58f, h * 0.12f, w * 0.68f, h * 0.18f)
          cubicTo(w * 0.95f, h * 0.28f, w * 0.88f, h * 0.58f, w * 0.5f, h * 0.82f)
          close()
        }
    canvas.drawPath(path, paint)
    return bitmap
  }

  private fun dp(context: Context, value: Int): Int {
    return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            value.toFloat(),
            context.resources.displayMetrics,
        )
        .toInt()
  }
}
