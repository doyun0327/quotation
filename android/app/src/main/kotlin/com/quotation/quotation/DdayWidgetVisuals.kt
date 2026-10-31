package com.quotation.quotation

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.Path
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.Typeface
import android.media.ExifInterface
import android.os.Build
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import android.util.TypedValue
import androidx.core.content.res.ResourcesCompat
import org.json.JSONArray
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/** Shared drawables/bitmaps for the D-Day home widget. */
object DdayWidgetVisuals {
  fun drawableFor(characterId: String): Int {
    return if (characterId == "bul") R.drawable.character_bul else R.drawable.character
  }

  /** Flutter asset for a shop character. Falls back to the default sprite. */
  fun assetFor(characterId: String): String {
    if (characterId == "c65") return "assets/images/character/character(65).png"
    if (characterId.startsWith("c")) {
      val n = characterId.removePrefix("c").toIntOrNull()
      if (n != null && n in 1..64) {
        return "assets/images/character/character ($n).png"
      }
    }
    if (characterId == "bul") return "assets/images/character/character (1).png"
    return "assets/images/character/character.png"
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
   * One UI cell span. Same formula as Flutter [TogetherWidgetSize.homeSize]
   * (360dp phone: 4×2 = 301×202, 3×2 = 221×202).
   */
  fun launcherSpanDp(cells: Int, horizontal: Boolean, screenWidthDp: Int): Float {
    val screen = screenWidthDp.coerceIn(320, 480).toFloat()
    val raw =
        if (horizontal) {
          screen * (80 * cells - 19) / 360f
        } else {
          screen * (111 * cells - 20) / 360f
        }
    return raw.coerceAtLeast(8f)
  }

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

  /** Shared Together card aspect (w / h) — matches Flutter TogetherWidgetSize.cardAspect. */
  const val CARD_ASPECT = 2.14f

  /** Largest [CARD_ASPECT] card inside the launcher cell; the rest stays transparent. */
  fun cardSizeDp(cellW: Float, cellH: Float): Pair<Float, Float> =
      if (cellW / cellH > CARD_ASPECT) {
        cellH * CARD_ASPECT to cellH
      } else {
        cellW to cellW / CARD_ASPECT
      }

  // GENERATED alongside lib/data/character_art_insets.dart.
  // file -> aspect (w/h), left, right, top, bottom transparent fractions.
  private val ART_INSETS: Map<String, FloatArray> =
      mapOf(
          "character (1).png" to floatArrayOf(1.0210f, 0.233f, 0.252f, 0.160f, 0.072f),
          "character (10).png" to floatArrayOf(1.0218f, 0.024f, 0.017f, 0.006f, 0.024f),
          "character (11).png" to floatArrayOf(1.0218f, 0.086f, 0.039f, 0.082f, 0.027f),
          "character (12).png" to floatArrayOf(1.0218f, 0.148f, 0.147f, 0.081f, 0.017f),
          "character (13).png" to floatArrayOf(1.0218f, 0.229f, 0.132f, 0.081f, 0.028f),
          "character (14).png" to floatArrayOf(1.0218f, 0.223f, 0.230f, 0.065f, 0.029f),
          "character (15).png" to floatArrayOf(1.0218f, 0.214f, 0.145f, 0.000f, 0.011f),
          "character (16).png" to floatArrayOf(1.0210f, 0.268f, 0.268f, 0.039f, 0.040f),
          "character (17).png" to floatArrayOf(1.0210f, 0.254f, 0.256f, 0.121f, 0.052f),
          "character (18).png" to floatArrayOf(1.0218f, 0.285f, 0.288f, 0.143f, 0.032f),
          "character (19).png" to floatArrayOf(1.0210f, 0.245f, 0.251f, 0.121f, 0.046f),
          "character (2).png" to floatArrayOf(1.0000f, 0.218f, 0.222f, 0.128f, 0.067f),
          "character (20).png" to floatArrayOf(1.0234f, 0.143f, 0.143f, 0.081f, 0.027f),
          "character (21).png" to floatArrayOf(1.0210f, 0.278f, 0.264f, 0.051f, 0.042f),
          "character (22).png" to floatArrayOf(1.0210f, 0.251f, 0.254f, 0.110f, 0.046f),
          "character (23).png" to floatArrayOf(1.0210f, 0.000f, 0.000f, 0.000f, 0.000f),
          "character (24).png" to floatArrayOf(1.0218f, 0.185f, 0.182f, 0.052f, 0.033f),
          "character (25).png" to floatArrayOf(1.0210f, 0.178f, 0.178f, 0.093f, 0.028f),
          "character (26).png" to floatArrayOf(1.0218f, 0.195f, 0.203f, 0.081f, 0.040f),
          "character (27).png" to floatArrayOf(1.0210f, 0.240f, 0.240f, 0.085f, 0.027f),
          "character (28).png" to floatArrayOf(1.0210f, 0.134f, 0.133f, 0.106f, 0.032f),
          "character (29).png" to floatArrayOf(1.0210f, 0.236f, 0.236f, 0.079f, 0.037f),
          "character (3).png" to floatArrayOf(1.0000f, 0.253f, 0.250f, 0.104f, 0.046f),
          "character (30).png" to floatArrayOf(1.0210f, 0.245f, 0.245f, 0.101f, 0.035f),
          "character (31).png" to floatArrayOf(1.0250f, 0.238f, 0.247f, 0.118f, 0.027f),
          "character (32).png" to floatArrayOf(1.0210f, 0.264f, 0.260f, 0.055f, 0.027f),
          "character (33).png" to floatArrayOf(1.0242f, 0.243f, 0.202f, 0.040f, 0.032f),
          "character (34).png" to floatArrayOf(1.0210f, 0.232f, 0.270f, 0.076f, 0.022f),
          "character (35).png" to floatArrayOf(1.0210f, 0.255f, 0.190f, 0.044f, 0.022f),
          "character (36).png" to floatArrayOf(1.0210f, 0.249f, 0.220f, 0.067f, 0.013f),
          "character (37).png" to floatArrayOf(1.0193f, 0.246f, 0.263f, 0.076f, 0.024f),
          "character (38).png" to floatArrayOf(1.0210f, 0.249f, 0.247f, 0.083f, 0.029f),
          "character (39).png" to floatArrayOf(1.0210f, 0.259f, 0.218f, 0.072f, 0.024f),
          "character (4).png" to floatArrayOf(1.0218f, 0.230f, 0.173f, 0.061f, 0.024f),
          "character (40).png" to floatArrayOf(1.0210f, 0.254f, 0.176f, 0.066f, 0.018f),
          "character (41).png" to floatArrayOf(1.0210f, 0.255f, 0.231f, 0.079f, 0.019f),
          "character (42).png" to floatArrayOf(1.0210f, 0.264f, 0.264f, 0.037f, 0.026f),
          "character (43).png" to floatArrayOf(1.0210f, 0.260f, 0.249f, 0.098f, 0.024f),
          "character (44).png" to floatArrayOf(1.0210f, 0.258f, 0.263f, 0.073f, 0.019f),
          "character (45).png" to floatArrayOf(1.0210f, 0.277f, 0.268f, 0.051f, 0.013f),
          "character (46).png" to floatArrayOf(1.0210f, 0.267f, 0.265f, 0.034f, 0.020f),
          "character (47).png" to floatArrayOf(1.0210f, 0.264f, 0.236f, 0.085f, 0.015f),
          "character (48).png" to floatArrayOf(1.0210f, 0.270f, 0.241f, 0.056f, 0.019f),
          "character (49).png" to floatArrayOf(1.0210f, 0.292f, 0.233f, 0.080f, 0.022f),
          "character (5).png" to floatArrayOf(1.0210f, 0.239f, 0.244f, 0.156f, 0.040f),
          "character (50).png" to floatArrayOf(1.0218f, 0.278f, 0.271f, 0.074f, 0.014f),
          "character (51).png" to floatArrayOf(1.0218f, 0.300f, 0.274f, 0.055f, 0.007f),
          "character (52).png" to floatArrayOf(1.0218f, 0.259f, 0.253f, 0.079f, 0.019f),
          "character (53).png" to floatArrayOf(1.0218f, 0.291f, 0.276f, 0.088f, 0.023f),
          "character (54).png" to floatArrayOf(1.0218f, 0.289f, 0.261f, 0.073f, 0.023f),
          "character (55).png" to floatArrayOf(1.0218f, 0.276f, 0.250f, 0.108f, 0.009f),
          "character (56).png" to floatArrayOf(1.0218f, 0.271f, 0.186f, 0.063f, 0.028f),
          "character (57).png" to floatArrayOf(1.0218f, 0.278f, 0.187f, 0.072f, 0.030f),
          "character (58).png" to floatArrayOf(1.0218f, 0.258f, 0.278f, 0.078f, 0.015f),
          "character (59).png" to floatArrayOf(1.0218f, 0.265f, 0.240f, 0.090f, 0.023f),
          "character (6).png" to floatArrayOf(1.0210f, 0.252f, 0.264f, 0.080f, 0.056f),
          "character (60).png" to floatArrayOf(1.0218f, 0.293f, 0.295f, 0.070f, 0.017f),
          "character (61).png" to floatArrayOf(1.0218f, 0.285f, 0.262f, 0.059f, 0.019f),
          "character (62).png" to floatArrayOf(1.0218f, 0.276f, 0.221f, 0.047f, 0.021f),
          "character (63).png" to floatArrayOf(1.0218f, 0.289f, 0.273f, 0.075f, 0.021f),
          "character (64).png" to floatArrayOf(0.9795f, 0.258f, 0.262f, 0.109f, 0.047f),
          "character (7).png" to floatArrayOf(1.0210f, 0.232f, 0.229f, 0.106f, 0.038f),
          "character (8).png" to floatArrayOf(1.0210f, 0.251f, 0.255f, 0.129f, 0.030f),
          "character (9).png" to floatArrayOf(1.0218f, 0.224f, 0.224f, 0.082f, 0.035f),
          "character(65).png" to floatArrayOf(1.0000f, 0.245f, 0.255f, 0.208f, 0.132f),
          "character.png" to floatArrayOf(1.0000f, 0.242f, 0.255f, 0.203f, 0.125f),
      )

  /**
   * Transparent gaps (px) left, right, top, bottom between a sprite box and
   * the character art contained in it (per-character margins). Matches
   * Flutter CharacterArtInsets.gaps so positions agree with the editor.
   */
  fun artGaps(characterId: String, boxW: Float, boxH: Float): FloatArray {
    val ins =
        ART_INSETS[assetFor(characterId).substringAfterLast('/')]
            ?: floatArrayOf(1f, 0f, 0f, 0f, 0f)
    val aspect = ins[0]
    val dw = min(boxW, boxH * aspect)
    val dh = dw / aspect
    val ox = (boxW - dw) / 2f
    val oy = (boxH - dh) / 2f
    return floatArrayOf(ox + dw * ins[1], ox + dw * ins[2], oy + dh * ins[3], oy + dh * ins[4])
  }

  /** Clamps a sprite box's left so its art (not the box) stays inside the card. */
  fun artLeft(left: Float, originX: Float, contentW: Float, boxW: Float, gaps: FloatArray): Float {
    val lo = originX - gaps[0]
    val hi = (originX + contentW - boxW + gaps[1]).coerceAtLeast(lo)
    return left.coerceIn(lo, hi)
  }

  /** Clamps a sprite box's top so its art (not the box) stays inside the card. */
  fun artTop(top: Float, originY: Float, contentH: Float, boxH: Float, gaps: FloatArray): Float {
    val lo = originY - gaps[2]
    val hi = (originY + contentH - boxH + gaps[3]).coerceAtLeast(lo)
    return top.coerceIn(lo, hi)
  }

  /** Fallback when the launcher has not reported a size yet. Default 4×2. */
  fun previewSizeDp(
      shape: String,
      sizeId: String = "s42",
      screenWidthDp: Int = 360,
  ): Pair<Float, Float> {
    val (cellsW, cellsH) = cellsForSize(sizeId)
    return launcherSpanDp(cellsW, true, screenWidthDp) to
        launcherSpanDp(cellsH, false, screenWidthDp)
  }

  /**
   * Actual host size from launcher options (portrait: minW × maxH).
   * Falls back to [previewSizeDp] when options are not ready.
   */
  fun hostSizeDp(
      context: Context,
      appWidgetManager: android.appwidget.AppWidgetManager,
      widgetId: Int,
      sizeId: String,
      screenWidthDp: Int,
  ): Pair<Float, Float> {
    val fallback = previewSizeDp("square", sizeId, screenWidthDp)
    val options = appWidgetManager.getAppWidgetOptions(widgetId) ?: return fallback
    val portrait =
        context.resources.configuration.orientation ==
            android.content.res.Configuration.ORIENTATION_PORTRAIT
    val minW = options.getInt(android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
    val maxW = options.getInt(android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, 0)
    val minH = options.getInt(android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
    val maxH = options.getInt(android.appwidget.AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0)
    val targetW = if (portrait) (if (minW > 0) minW else maxW) else (if (maxW > 0) maxW else minW)
    val targetH = if (portrait) (if (maxH > 0) maxH else minH) else (if (minH > 0) minH else maxH)
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      val sizes =
          options.getParcelableArrayList<android.util.SizeF>(
              android.appwidget.AppWidgetManager.OPTION_APPWIDGET_SIZES,
          )
      if (!sizes.isNullOrEmpty()) {
        val size =
            if (targetW > 0 && targetH > 0) {
              sizes.minBy {
                kotlin.math.abs(it.width - targetW) + kotlin.math.abs(it.height - targetH)
              }
            } else {
              sizes.first()
            }
        if (size.width >= 8f && size.height >= 8f) return size.width to size.height
      }
    }
    if (targetW <= 0 || targetH <= 0) return fallback
    return targetW.toFloat() to targetH.toFloat()
  }

  fun systemWidgetCornerDp(context: Context): Int {
    val density = context.resources.displayMetrics.density.coerceAtLeast(0.5f)
    return (systemWidgetCornerPx(context) / density).toInt().coerceIn(12, 40)
  }

  /**
   * Full widget frame matching Flutter [TogetherWidgetPreview] pixel-for-pixel.
   * Shown with ImageView fitCenter so the launcher cannot stretch the aspect ratio.
   */
  fun buildTogetherWidgetBitmap(
      context: Context,
      shape: String,
      widthDp: Float,
      heightDp: Float,
      bgColorArgb: Int = 0,
      bgOpacity: Int = 100,
      bgAssetPath: String? = null,
      textColorArgb: Int = 0xFFF26B8A.toInt(),
      isPixel: Boolean,
      label: String,
      textScale: Int,
      textOffsetX: Int,
      textOffsetY: Int,
      textRotation: Int = 0,
      textFontAsset: String = "",
      meId: String,
      friendId: String,
      meOffsetX: Int,
      meOffsetY: Int,
      friendOffsetX: Int,
      friendOffsetY: Int,
      charScale: Int,
      friendScale: Int,
      sizeCharFactor: Float,
      chars: JSONArray? = null,
  ): Bitmap {
    val density = context.resources.displayMetrics.density
    val w = px(context, widthDp).coerceAtLeast(8)
    val h = px(context, heightDp).coerceAtLeast(8)
    val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bitmap)

    // No border. Image theme when set; otherwise transparent.
    val pixelCorner =
        systemWidgetCornerPx(context).coerceAtMost(min(w, h) / 2f).coerceAtLeast(0f)
    val cardRect = RectF(0f, 0f, w.toFloat(), h.toFloat())
    val themeBmp = decodeFlutterAsset(context, bgAssetPath)
    if (themeBmp != null) {
      val clipPath =
          Path().apply {
            addRoundRect(cardRect, pixelCorner, pixelCorner, Path.Direction.CW)
          }
      canvas.save()
      canvas.clipPath(clipPath)
      val paint =
          Paint().apply {
            isFilterBitmap = !isPixel
            isAntiAlias = !isPixel
          }
      val dest = Rect(0, 0, w, h)
      if (isPhotoFile(bgAssetPath)) {
        drawCover(canvas, themeBmp, dest, paint)
      } else {
        canvas.drawBitmap(themeBmp, null, dest, paint)
      }
      canvas.restore()
      themeBmp.recycle()
    }

    val clipPath = Path()
    clipPath.addRoundRect(cardRect, pixelCorner, pixelCorner, Path.Direction.CW)

    val originX = 0f
    val originY = 0f
    val contentW = w.toFloat()
    val contentH = h.toFloat()

    canvas.save()
    canvas.clipPath(clipPath)

    val meScale = (charScale / 100f).coerceIn(0.6f, 3.0f)
    val frScale = (friendScale / 100f).coerceIn(0.6f, 3.0f)
    val meWDp = (72f * sizeCharFactor * meScale).toInt().coerceAtLeast(20)
    val meHDp = (96f * sizeCharFactor * meScale).toInt().coerceAtLeast(28)
    val meW = (meWDp * density).toInt().coerceAtLeast(8)
    val meH = (meHDp * density).toInt().coerceAtLeast(8)
    val friendWDp = (72f * sizeCharFactor * frScale).toInt().coerceAtLeast(20)
    val friendHDp = (96f * sizeCharFactor * frScale).toInt().coerceAtLeast(28)
    val friendW = (friendWDp * density).toInt().coerceAtLeast(8)
    val friendH = (friendHDp * density).toInt().coerceAtLeast(8)
    val charPaint =
        Paint().apply {
          isFilterBitmap = !isPixel
          isAntiAlias = !isPixel
        }

    val trimmed = label.trim()
    if (trimmed.isNotEmpty()) {
      val cornerDp = systemWidgetCornerDp(context).toFloat()
      val insetX = max(cornerDp, 16f)
      val insetY = max(cornerDp, 12f)
      val maxLabelPx =
          (contentW - insetX * density * 2f).roundToInt().coerceAtLeast(32)
      val maxLabelHeightPx =
          (contentH - insetY * density * 2f).roundToInt().coerceAtLeast(1)
      val labelBmp =
          buildLabelBitmap(
              context = context,
              text = trimmed,
              textScale = textScale,
              isPixel = isPixel,
              maxWidthPx = maxLabelPx,
              maxHeightPx = maxLabelHeightPx,
              textColorArgb = textColorArgb,
              fontAsset = textFontAsset,
          )
      val lx = originX + (contentW - labelBmp.width) / 2f + textOffsetX * density
      val ly = originY + (contentH - labelBmp.height) / 2f - textOffsetY * density
      val degrees = ((textRotation % 360) + 360) % 360
      if (degrees != 0) {
        canvas.save()
        canvas.rotate(
            degrees.toFloat(),
            lx + labelBmp.width / 2f,
            ly + labelBmp.height / 2f,
        )
        canvas.drawBitmap(labelBmp, lx, ly, null)
        canvas.restore()
      } else {
        canvas.drawBitmap(labelBmp, lx, ly, null)
      }
      labelBmp.recycle()
    }

    val hasFriend = friendId.isNotBlank()

    if (chars != null && chars.length() > 0) {
      for (i in 0 until chars.length()) {
        val obj = chars.optJSONObject(i) ?: continue
        val id = obj.optString("id").ifBlank { "basic" }
        val offsetX = obj.optInt("x", 0)
        val offsetY = obj.optInt("y", 0)
        // Upper bound matches Flutter widgetChars (400) so large sizes survive.
        val spriteScale = (obj.optInt("s", 100) / 100f).coerceIn(0.28f, 4.0f)
        val spriteWDp = (72f * sizeCharFactor * spriteScale).toInt().coerceAtLeast(16)
        val spriteHDp = (96f * sizeCharFactor * spriteScale).toInt().coerceAtLeast(20)
        val spriteW = (spriteWDp * density).toInt().coerceAtLeast(8)
        val spriteH = (spriteHDp * density).toInt().coerceAtLeast(8)
        val bmp =
            characterBitmap(
                context = context,
                characterId = id,
                widthDp = spriteWDp,
                heightDp = spriteHDp,
                isPixel = isPixel,
            )
        val gaps = artGaps(id, spriteW.toFloat(), spriteH.toFloat())
        val left =
            artLeft(originX + (4f + offsetX) * density, originX, contentW, spriteW.toFloat(), gaps)
        val top =
            artTop(
                originY + contentH - offsetY * density - spriteH,
                originY,
                contentH,
                spriteH.toFloat(),
                gaps,
            )
        val degrees = obj.optInt("r", 0)
        if (degrees % 360 != 0) {
          canvas.save()
          canvas.rotate(degrees.toFloat(), left + spriteW / 2f, top + spriteH / 2f)
          canvas.drawBitmap(bmp, left, top, charPaint)
          canvas.restore()
        } else {
          canvas.drawBitmap(bmp, left, top, charPaint)
        }
        bmp.recycle()
      }
      canvas.restore()
      return bitmap
    }

    val meBmp =
        characterBitmap(
            context = context,
            characterId = meId,
            widthDp = meWDp,
            heightDp = meHDp,
            isPixel = isPixel,
        )
    val meGaps = artGaps(meId, meW.toFloat(), meH.toFloat())
    val meLeft =
        artLeft(originX + (4f + meOffsetX) * density, originX, contentW, meW.toFloat(), meGaps)
    val meTop =
        artTop(
            originY + contentH - meOffsetY * density - meH,
            originY,
            contentH,
            meH.toFloat(),
            meGaps,
        )
    canvas.drawBitmap(meBmp, meLeft, meTop, charPaint)
    meBmp.recycle()

    if (hasFriend) {
      val friendBmp =
          characterBitmap(
              context = context,
              characterId = friendId,
              widthDp = friendWDp,
              heightDp = friendHDp,
              isPixel = isPixel,
          )
      val friendGaps = artGaps(friendId, friendW.toFloat(), friendH.toFloat())
      val friendLeft =
          artLeft(
              originX + (4f + friendOffsetX) * density,
              originX,
              contentW,
              friendW.toFloat(),
              friendGaps,
          )
      val friendTop =
          artTop(
              originY + contentH - friendOffsetY * density - friendH,
              originY,
              contentH,
              friendH.toFloat(),
              friendGaps,
          )
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
      maxWidthPx: Int,
      maxHeightPx: Int,
      textColorArgb: Int = 0xFFF26B8A.toInt(),
      fontAsset: String = "",
  ): Bitmap {
    val density = context.resources.displayMetrics.density
    val maxWidth = maxWidthPx.coerceAtLeast(32)
    val maxHeight = maxHeightPx.coerceAtLeast(1)
    // Decorate font picked in the app. Same size/weight as TogetherCheerLayout.style.
    val custom = if (fontAsset.isBlank()) null else assetTypeface(context, fontAsset)
    val pixel = isPixel && custom == null
    val baseSp = if (pixel) 16f else 22f
    val textSizePx = baseSp * (textScale / 100f) * density
    val face =
        custom
            ?: if (isPixel) pixelTypeface(context)
            else Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
    val paint =
        TextPaint().apply {
          color = textColorArgb
          this.textSize = textSizePx
          typeface = face
          isAntiAlias = !pixel
          isFilterBitmap = !pixel
          // Galmuri has no bold face. Faux bold widens glyphs and wraps earlier than Flutter.
          isFakeBoldText = false
          if (!pixel && custom == null) letterSpacing = -0.1f / textSizePx
        }
    val fontHeight = (paint.fontMetrics.descent - paint.fontMetrics.ascent).coerceAtLeast(1f)
    val spacingAdd = textSizePx * 1.2f - fontHeight
    // Newlines come from the Flutter preview. Do not wrap those lines again.
    // StaticLayout.width is the constraint (16384), not the ink width — scale by the lines.
    val layout =
        StaticLayout.Builder.obtain(text, 0, text.length, paint, 16384)
            .setAlignment(Layout.Alignment.ALIGN_CENTER)
            .setLineSpacing(spacingAdd, 1f)
            .setIncludePad(false)
            .build()
    var textWidth = 1f
    for (i in 0 until layout.lineCount) {
      textWidth = max(textWidth, layout.getLineWidth(i))
    }
    val scaleH = if (layout.height > maxHeight) maxHeight.toFloat() / layout.height else 1f
    val scaleW = if (textWidth > maxWidth) maxWidth / textWidth else 1f
    val scale = min(scaleH, scaleW)
    val width = (textWidth * scale).roundToInt().coerceAtLeast(1)
    val height = (layout.height * scale).roundToInt().coerceAtLeast(1)
    val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bitmap)
    // Center alignment sits in the 16384px layout, not at x=0. Shift the ink into the bitmap.
    val inkLeft = (layout.width - textWidth) / 2f
    canvas.translate(-inkLeft * scale, 0f)
    canvas.scale(scale, scale)
    layout.draw(canvas)
    return bitmap
  }

  /**
   * RemoteViews parcels fail once a bitmap is about 1MB.
   * ImageViews scale the result back up, so a smaller bitmap still fills the widget.
   */
  fun fitBitmap(source: Bitmap, maxEdge: Int): Bitmap {
    val longest = max(source.width, source.height)
    if (longest <= maxEdge) return source
    val scale = maxEdge.toFloat() / longest
    val w = (source.width * scale).roundToInt().coerceAtLeast(1)
    val h = (source.height * scale).roundToInt().coerceAtLeast(1)
    val scaled = Bitmap.createScaledBitmap(source, w, h, true)
    if (scaled != source) source.recycle()
    return scaled
  }

  /** Character art; nearest-neighbor when pixel so sprites stay crisp. */
  fun characterBitmap(
      context: Context,
      characterId: String,
      widthDp: Int,
      heightDp: Int,
      isPixel: Boolean,
  ): Bitmap {
    val w = dp(context, widthDp).coerceAtLeast(8)
    val h = dp(context, heightDp).coerceAtLeast(8)
    val resId = drawableFor(characterId)
    val src =
        decodeFlutterAsset(context, assetFor(characterId))
            ?: BitmapFactory.decodeResource(context.resources, resId)
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
  private val assetTypefaces = java.util.concurrent.ConcurrentHashMap<String, Typeface>()

  /** Font bundled by Flutter (pubspec `fonts:`), e.g. `assets/fonts/Jua-Regular.ttf`. */
  private fun assetTypeface(context: Context, asset: String): Typeface? {
    assetTypefaces[asset]?.let { return it }
    return try {
      Typeface.createFromAsset(context.assets, "flutter_assets/$asset").also {
        assetTypefaces[asset] = it
      }
    } catch (e: Exception) {
      android.util.Log.e("DdayWidget", "Widget font missing: $asset", e)
      null
    }
  }

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

  /** Gallery photos are absolute files. Bundled themes stay in assets. */
  private fun isPhotoFile(assetPath: String?): Boolean {
    if (assetPath.isNullOrBlank()) return false
    return assetPath.startsWith("/") || assetPath.startsWith("file://")
  }

  /** Fill [dest] without stretching. Extra edges are cropped. */
  private fun drawCover(canvas: Canvas, bitmap: Bitmap, dest: Rect, paint: Paint) {
    val srcW = bitmap.width.toFloat()
    val srcH = bitmap.height.toFloat()
    if (srcW <= 0f || srcH <= 0f) return
    val dstW = dest.width().toFloat()
    val dstH = dest.height().toFloat()
    val scale = max(dstW / srcW, dstH / srcH)
    val cropW = dstW / scale
    val cropH = dstH / scale
    val left = ((srcW - cropW) / 2f).roundToInt().coerceAtLeast(0)
    val top = ((srcH - cropH) / 2f).roundToInt().coerceAtLeast(0)
    val right = (left + cropW.roundToInt()).coerceAtMost(bitmap.width)
    val bottom = (top + cropH.roundToInt()).coerceAtMost(bitmap.height)
    if (right <= left || bottom <= top) {
      canvas.drawBitmap(bitmap, null, dest, paint)
      return
    }
    canvas.drawBitmap(bitmap, Rect(left, top, right, bottom), dest, paint)
  }

  /** Downsample and honor camera rotation so a gallery photo stays intact. */
  private fun decodePhotoFile(filePath: String): Bitmap? {
    val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
    BitmapFactory.decodeFile(filePath, bounds)
    if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null
    val maxEdge = 1600
    var sample = 1
    while (bounds.outWidth / sample > maxEdge || bounds.outHeight / sample > maxEdge) {
      sample *= 2
    }
    val decoded =
        BitmapFactory.decodeFile(
            filePath,
            BitmapFactory.Options().apply { inSampleSize = sample },
        ) ?: return null
    val orientation =
        try {
          ExifInterface(filePath).getAttributeInt(
              ExifInterface.TAG_ORIENTATION,
              ExifInterface.ORIENTATION_NORMAL,
          )
        } catch (_: Exception) {
          ExifInterface.ORIENTATION_NORMAL
        }
    val matrix = Matrix()
    when (orientation) {
      ExifInterface.ORIENTATION_ROTATE_90 -> matrix.postRotate(90f)
      ExifInterface.ORIENTATION_ROTATE_180 -> matrix.postRotate(180f)
      ExifInterface.ORIENTATION_ROTATE_270 -> matrix.postRotate(270f)
      ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> matrix.preScale(-1f, 1f)
      ExifInterface.ORIENTATION_FLIP_VERTICAL -> matrix.preScale(1f, -1f)
      ExifInterface.ORIENTATION_TRANSPOSE -> {
        matrix.postRotate(90f)
        matrix.preScale(-1f, 1f)
      }
      ExifInterface.ORIENTATION_TRANSVERSE -> {
        matrix.postRotate(270f)
        matrix.preScale(-1f, 1f)
      }
      else -> return decoded
    }
    val rotated =
        Bitmap.createBitmap(decoded, 0, 0, decoded.width, decoded.height, matrix, true)
    if (rotated != decoded) decoded.recycle()
    return rotated
  }

  /** Load a Flutter asset (e.g. assets/images/…) from the APK AssetManager. */
  fun decodeFlutterAsset(context: Context, assetPath: String?): Bitmap? {
    if (assetPath.isNullOrBlank()) return null
    val filePath = when {
      assetPath.startsWith("file://") -> assetPath.removePrefix("file://")
      assetPath.startsWith("/") -> assetPath
      else -> null
    }
    if (filePath != null) {
      return try {
        decodePhotoFile(filePath)
      } catch (_: Throwable) {
        null
      }
    }
    // Flutter stores spaces in asset file names as %20 inside the APK.
    val encoded = assetPath.replace(" ", "%20")
    val candidates =
        listOf(
            "flutter_assets/$encoded",
            "flutter_assets/$assetPath",
            encoded,
            assetPath,
            assetPath.removePrefix("assets/").let { "flutter_assets/assets/$it" },
            encoded.removePrefix("assets/").let { "flutter_assets/assets/$it" },
        )
    for (path in candidates) {
      try {
        context.assets.open(path).use { stream ->
          return BitmapFactory.decodeStream(stream)
        }
      } catch (_: Exception) {
        // try next
      }
    }
    return null
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

  /**
   * Soft mosaic: equal-size square pixels, subtle shade noise (not a checker).
   */
  private fun drawPixelMosaicRoundRect(
      canvas: Canvas,
      rect: RectF,
      cornerPx: Float,
      fillArgb: Int,
      density: Float,
  ) {
    val path =
        Path().apply {
          addRoundRect(rect, cornerPx, cornerPx, Path.Direction.CW)
        }
    canvas.save()
    canvas.clipPath(path)

    val a = (fillArgb ushr 24) and 0xFF
    val r = (fillArgb ushr 16) and 0xFF
    val g = (fillArgb ushr 8) and 0xFF
    val b = fillArgb and 0xFF
    fun mix(t: Float, toward: Int): Int {
      val tr = (toward ushr 16) and 0xFF
      val tg = (toward ushr 8) and 0xFF
      val tb = toward and 0xFF
      val nr = (r + (tr - r) * t).toInt().coerceIn(0, 255)
      val ng = (g + (tg - g) * t).toInt().coerceIn(0, 255)
      val nb = (b + (tb - b) * t).toInt().coerceIn(0, 255)
      return (a shl 24) or (nr shl 16) or (ng shl 8) or nb
    }
    val shades =
        intArrayOf(
            mix(0.14f, 0xFFFFFFFF.toInt()),
            mix(0.07f, 0xFFFFFFFF.toInt()),
            fillArgb,
            mix(0.10f, 0xFFE8D98A.toInt()),
            mix(0.035f, 0xFF000000.toInt()),
            mix(0.06f, 0xFF000000.toInt()),
        )

    val w = rect.width()
    val h = rect.height()
    var seed =
        (fillArgb xor w.toInt() xor (h.toInt() shl 8)).let { if (it == 0) 0xA5A5 else it }
    fun next(): Float {
      seed = (1103515245 * seed + 12345) and 0x7fffffff
      return seed / 2147483647f
    }

    val unit = (8f * density).coerceIn(4f, 18f)
    val cols = kotlin.math.ceil(w / unit).toInt()
    val rows = kotlin.math.ceil(h / unit).toInt()
    val paint = Paint().apply { isAntiAlias = false }

    for (row in 0 until rows) {
      for (col in 0 until cols) {
        val n = next()
        val idx =
            when {
              n < 0.22f -> 0
              n < 0.42f -> 1
              n < 0.62f -> 2
              n < 0.80f -> 3
              n < 0.92f -> 4
              else -> 5
            }
        paint.color = shades[idx]
        val x = rect.left + col * unit
        val y = rect.top + row * unit
        canvas.drawRect(x, y, x + unit + 0.4f, y + unit + 0.4f, paint)
      }
    }
    canvas.restore()
  }

  private fun px(context: Context, dp: Float): Int {
    return (dp * context.resources.displayMetrics.density).roundToInt().coerceAtLeast(1)
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
