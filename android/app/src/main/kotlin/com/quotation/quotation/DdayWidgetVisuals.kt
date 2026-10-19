package com.quotation.quotation

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.util.TypedValue

/** Shared drawables/bitmaps for the D-Day home widget. */
object DdayWidgetVisuals {
  fun drawableFor(characterId: String): Int {
    return if (characterId == "bul") R.drawable.character_bul else R.drawable.character
  }

  fun buildPixelHeartBitmap(context: Context): Bitmap {
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
    val size = dp(context, 18).coerceAtLeast(16)
    val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bitmap)
    val cell = size / 16f
    val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.FILL }
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

  fun buildCleanHeartBitmap(context: Context): Bitmap {
    val size = dp(context, 18).coerceAtLeast(16)
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
