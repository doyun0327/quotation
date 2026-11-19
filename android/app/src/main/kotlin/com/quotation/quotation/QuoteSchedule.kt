package com.quotation.quotation

import android.content.SharedPreferences
import org.json.JSONArray

/**
 * The quote a home widget shows right now. The app writes `quoteSchedule`
 * (one line per half-hour slot, picked at random from every open category)
 * starting at `quoteScheduleStart`; the widget walks it by the clock so the
 * line changes every 30 minutes (:00 / :30) even while the app is closed.
 * Mirrors SelectionController.slotAt and iOS DearlyWidgetStore.currentQuote.
 */
object QuoteSchedule {
  const val SLOT_MS = 30L * 60L * 1000L

  data class Line(
      val id: String,
      val text: String,
      val categoryId: String,
      val subCategoryId: String,
  )

  fun slotAt(millis: Long): Long = Math.floorDiv(millis, SLOT_MS)

  fun current(prefs: SharedPreferences, now: Long = System.currentTimeMillis()): Line? {
    val lines = parse(pref(prefs, "quoteSchedule"))
    if (lines.isNotEmpty()) {
      val start = pref(prefs, "quoteScheduleStart").toLongOrNull()
      val slot = slotAt(now)
      val offset = if (start == null) -1L else slot - start
      // Past the end (app not opened for days): keep shuffling the same lines.
      val index =
          if (offset in 0 until lines.size) offset.toInt()
          else (mix(slot) % lines.size).toInt()
      return lines[index]
    }
    val text = pref(prefs, "quoteText")
    if (text.isEmpty()) return null
    return Line(
        id = pref(prefs, "quoteId"),
        text = text,
        categoryId = pref(prefs, "categoryId"),
        subCategoryId = pref(prefs, "subCategoryId"),
    )
  }

  private fun parse(raw: String): List<Line> {
    if (raw.isEmpty()) return emptyList()
    return try {
      val array = JSONArray(raw)
      buildList {
        for (i in 0 until array.length()) {
          val o = array.optJSONObject(i) ?: continue
          val text = o.optString("t").trim()
          if (text.isEmpty()) continue
          add(Line(o.optString("i"), text, o.optString("c"), o.optString("s")))
        }
      }
    } catch (_: Exception) {
      emptyList()
    }
  }

  /** Same 32-bit mix as SelectionController._mix. */
  private fun mix(value: Long): Long {
    var h = (value * 0x9E3779B1L) and 0xFFFFFFFFL
    h = h xor (h ushr 16)
    h = (h * 0x45D9F3BL) and 0xFFFFFFFFL
    h = h xor (h ushr 16)
    h = (h * 0x45D9F3BL) and 0xFFFFFFFFL
    h = h xor (h ushr 16)
    return h
  }

  private fun pref(prefs: SharedPreferences, key: String): String {
    return prefs.getString(key, null)?.trim().orEmpty().ifEmpty {
      prefs.getString("flutter.$key", null)?.trim().orEmpty()
    }
  }
}
