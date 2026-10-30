package com.quotation.quotation

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.util.TypedValue
import android.widget.RemoteViews
import kotlin.math.max
import kotlin.math.roundToInt
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject

/** Legacy / fallback receiver (2×2). Prefer size-specific subclasses when pinning. */
open class DdayWidgetProvider : HomeWidgetProvider() {
  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    appWidgetIds.forEach { widgetId ->
      updateOne(context, appWidgetManager, widgetId, widgetData)
    }
  }

  override fun onAppWidgetOptionsChanged(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetId: Int,
      newOptions: Bundle,
  ) {
    super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
    onUpdate(context, appWidgetManager, intArrayOf(appWidgetId))
  }

  override fun onDeleted(context: Context, appWidgetIds: IntArray) {
    super.onDeleted(context, appWidgetIds)
    val prefs = HomeWidgetPlugin.getData(context)
    val bindings = readJson(prefs, "ddayWidgetBindings")
    for (id in appWidgetIds) bindings.remove(id.toString())
    prefs.edit().putString("ddayWidgetBindings", bindings.toString()).apply()
  }

  private fun updateOne(
      context: Context,
      appWidgetManager: AppWidgetManager,
      widgetId: Int,
      widgetData: SharedPreferences,
  ) {
    try {
      drawOne(context, appWidgetManager, widgetId, widgetData)
    } catch (e: Exception) {
      Log.e(TAG, "together widget update failed id=$widgetId", e)
    }
  }

  private fun drawOne(
      context: Context,
      appWidgetManager: AppWidgetManager,
      widgetId: Int,
      widgetData: SharedPreferences,
  ) {
    val shape = readShape(widgetData)
    val sizeId = readSize(widgetData)
    val screenWidthDp = readInt(widgetData, "ddayScreenWidthDp", 0).let { saved ->
      if (saved > 0) {
        saved
      } else {
        val metrics = context.resources.displayMetrics
        (metrics.widthPixels / metrics.density).toInt().coerceAtLeast(320)
      }
    }
    // Fill the launcher-allocated cell (not the 70×n−30 minimum).
    val (canvasW, canvasH) =
        DdayWidgetVisuals.hostSizeDp(
            context,
            appWidgetManager,
            widgetId,
            sizeId,
            screenWidthDp,
        )
    val cornerDp = DdayWidgetVisuals.systemWidgetCornerDp(context)

    val roomId = bindRoom(widgetData, widgetId)
    if (roomId.isBlank()) return
    val room = readJson(widgetData, "ddayRoomsJson").optJSONObject(roomId)
    val label = roomStr(room, "label", readString(widgetData, "ddayLabel"))
    val meId = roomStr(room, "me", readString(widgetData, "ddayCharMe")).ifBlank { "basic" }
    val friendId = roomStr(room, "friend", readString(widgetData, "ddayCharFriend"))
    val chars = room?.optJSONArray("chars") ?: JSONArray()
    val style = readString(widgetData, "visualStyle").ifBlank { "pixel" }
    val meOffsetX = roomInt(room, "meX", readInt(widgetData, "ddayMeOffsetX", 0))
    val meOffsetY = roomInt(room, "meY", readInt(widgetData, "ddayMeOffsetY", 0))
    val friendOffsetX = roomInt(room, "friendX", readInt(widgetData, "ddayFriendOffsetX", 0))
    val friendOffsetY = roomInt(room, "friendY", readInt(widgetData, "ddayFriendOffsetY", 0))
    val textOffsetX = roomInt(room, "textX", readInt(widgetData, "ddayTextOffsetX", 0))
    val textOffsetY = roomInt(room, "textY", readInt(widgetData, "ddayTextOffsetY", 0))
    val textRotation = roomInt(room, "textRotation", 0)
    val charScale = roomInt(room, "charScale", readInt(widgetData, "ddayCharScale", 100)).coerceIn(60, 240)
    val friendScale =
        roomInt(room, "friendScale", readInt(widgetData, "ddayFriendCharScale", charScale))
            .coerceIn(60, 240)
    val textScale =
        roomInt(room, "textScale", readInt(widgetData, "ddayTextScale", 100)).coerceIn(60, 240)
    val bgAsset = roomStr(room, "bgAsset", readString(widgetData, "ddayBgAsset"))
    val textColor =
        DdayWidgetVisuals.parseArgb(
            roomStr(room, "textColor", readString(widgetData, "ddayTextColor")).ifBlank { null },
            default = 0xFFF26B8A.toInt(),
        )
    val isPixel = style != "clean"

    val composite =
        DdayWidgetVisuals.buildTogetherWidgetBitmap(
            context = context,
            shape = shape,
            widthDp = canvasW,
            heightDp = canvasH,
            bgAssetPath = bgAsset.ifBlank { null },
            textColorArgb = textColor,
            isPixel = isPixel,
            label = label,
            textScale = textScale,
            textOffsetX = textOffsetX,
            textOffsetY = textOffsetY,
            textRotation = textRotation,
            meId = meId,
            friendId = friendId,
            meOffsetX = meOffsetX,
            meOffsetY = meOffsetY,
            friendOffsetX = friendOffsetX,
            friendOffsetY = friendOffsetY,
            charScale = charScale,
            friendScale = friendScale,
            sizeCharFactor = DdayWidgetVisuals.charFactor(sizeId),
            chars = chars,
        )

    val views =
        RemoteViews(context.packageName, R.layout.dday_widget).apply {
          val launchUri =
              Uri.parse("dearly://together").buildUpon().apply {
                if (roomId.isNotBlank()) appendQueryParameter("room", roomId)
              }.build()
          val launchIntent =
              HomeWidgetLaunchIntent.getActivity(
                  context,
                  MainActivity::class.java,
                  launchUri,
              )
          setOnClickPendingIntent(R.id.dday_widget_root, launchIntent)
          setOnClickPendingIntent(R.id.dday_composite, launchIntent)
          setImageViewBitmap(
              R.id.dday_composite,
              DdayWidgetVisuals.fitBitmap(composite, 480),
          )
        }

    // Let Flutter decorate preview use the same dp + corner as this host.
    val hosts = readJson(widgetData, "ddayHostByRoom")
    if (roomId.isNotBlank()) {
      hosts.put(
          roomId,
          JSONObject()
              .put("w", canvasW.toString())
              .put("h", canvasH.toString())
              .put("corner", cornerDp)
              .put("sizeId", sizeId),
      )
    }
    widgetData
        .edit()
        .putInt("ddayHostWidthDp", canvasW.roundToInt())
        .putInt("ddayHostHeightDp", canvasH.roundToInt())
        .putString("ddayHostWidthExact", canvasW.toString())
        .putString("ddayHostHeightExact", canvasH.toString())
        .putString("ddayHostSizeId", sizeId)
        .putInt("ddayHostCornerDp", cornerDp)
        .putInt("flutter.ddayHostWidthDp", canvasW.roundToInt())
        .putInt("flutter.ddayHostHeightDp", canvasH.roundToInt())
        .putString("flutter.ddayHostWidthExact", canvasW.toString())
        .putString("flutter.ddayHostHeightExact", canvasH.toString())
        .putString("flutter.ddayHostSizeId", sizeId)
        .putInt("flutter.ddayHostCornerDp", cornerDp)
        .putString("ddayHostByRoom", hosts.toString())
        .apply()

    appWidgetManager.updateAppWidget(widgetId, views)
  }

  /**
   * Preview shown in the system "add to home screen" sheet.
   * Uses the room the app just saved, so the sheet matches the decorated widget.
   */
  fun buildPinPreview(context: Context, sizeId: String): RemoteViews {
    val prefs = HomeWidgetPlugin.getData(context)
    val normalized = normalizeSize(sizeId)
    val pending = readString(prefs, "ddayPendingRoomId")
    val roomId = if (pending.isNotBlank()) pending else readString(prefs, "ddayRoomId")
    val room = readJson(prefs, "ddayRoomsJson").optJSONObject(roomId)
    val label = roomStr(room, "label", readString(prefs, "ddayLabel"))
    val meId = roomStr(room, "me", readString(prefs, "ddayCharMe")).ifBlank { "basic" }
    val friendId = roomStr(room, "friend", readString(prefs, "ddayCharFriend"))
    val chars = room?.optJSONArray("chars") ?: JSONArray()
    val style = readString(prefs, "visualStyle").ifBlank { "pixel" }
    val meOffsetX = roomInt(room, "meX", readInt(prefs, "ddayMeOffsetX", 0))
    val meOffsetY = roomInt(room, "meY", readInt(prefs, "ddayMeOffsetY", 0))
    val friendOffsetX = roomInt(room, "friendX", readInt(prefs, "ddayFriendOffsetX", 0))
    val friendOffsetY = roomInt(room, "friendY", readInt(prefs, "ddayFriendOffsetY", 0))
    val textOffsetX = roomInt(room, "textX", readInt(prefs, "ddayTextOffsetX", 0))
    val textOffsetY = roomInt(room, "textY", readInt(prefs, "ddayTextOffsetY", 0))
    val textRotation = roomInt(room, "textRotation", 0)
    val charScale = roomInt(room, "charScale", readInt(prefs, "ddayCharScale", 100)).coerceIn(60, 240)
    val friendScale =
        roomInt(room, "friendScale", readInt(prefs, "ddayFriendCharScale", charScale))
            .coerceIn(60, 240)
    val textScale =
        roomInt(room, "textScale", readInt(prefs, "ddayTextScale", 100)).coerceIn(60, 240)
    val bgAsset = roomStr(room, "bgAsset", readString(prefs, "ddayBgAsset"))
    val textColor =
        DdayWidgetVisuals.parseArgb(
            roomStr(room, "textColor", readString(prefs, "ddayTextColor")).ifBlank { null },
            default = 0xFFF26B8A.toInt(),
        )
    val isPixel = style != "clean"
    val screenWidthDp = readInt(prefs, "ddayScreenWidthDp", 0).let { saved ->
      if (saved > 0) {
        saved
      } else {
        val metrics = context.resources.displayMetrics
        (metrics.widthPixels / metrics.density).toInt().coerceAtLeast(320)
      }
    }
    val (canvasW, canvasH) =
        DdayWidgetVisuals.previewSizeDp("square", normalized, screenWidthDp)
    val bitmap =
        DdayWidgetVisuals.buildTogetherWidgetBitmap(
            context = context,
            shape = "square",
            widthDp = canvasW,
            heightDp = canvasH,
            bgAssetPath = bgAsset.ifBlank { null },
            textColorArgb = textColor,
            isPixel = isPixel,
            label = label,
            textScale = textScale,
            textOffsetX = textOffsetX,
            textOffsetY = textOffsetY,
            textRotation = textRotation,
            meId = meId,
            friendId = friendId,
            meOffsetX = meOffsetX,
            meOffsetY = meOffsetY,
            friendOffsetX = friendOffsetX,
            friendOffsetY = friendOffsetY,
            charScale = charScale,
            friendScale = friendScale,
            sizeCharFactor = DdayWidgetVisuals.charFactor(normalized),
            chars = chars,
        )
    val preview = scaleForPinSheet(bitmap, isPixel)
    return wrapPinPreview(context, preview, canvasW, canvasH)
  }

  /** Compact image shown in the system add-widget sheet. */
  fun wrapPinPreview(
      context: Context,
      bitmap: Bitmap,
      widthDp: Float,
      heightDp: Float,
  ): RemoteViews {
    val (viewW, viewH) = pinPreviewPx(context, widthDp, heightDp)
    return RemoteViews(context.packageName, R.layout.dday_widget_pin_prompt).apply {
      setImageViewBitmap(R.id.dday_pin_preview, bitmap)
      setInt(R.id.dday_pin_preview, "setMinimumWidth", viewW)
      setInt(R.id.dday_pin_preview, "setMinimumHeight", viewH)
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        setViewLayoutWidth(R.id.dday_pin_preview, viewW.toFloat(), TypedValue.COMPLEX_UNIT_PX)
        setViewLayoutHeight(R.id.dday_pin_preview, viewH.toFloat(), TypedValue.COMPLEX_UNIT_PX)
      }
    }
  }

  /** Widget aspect, shrunk so the pin sheet stays short. */
  private fun pinPreviewPx(context: Context, widthDp: Float, heightDp: Float): Pair<Int, Int> {
    val metrics = context.resources.displayMetrics
    val density = metrics.density.coerceAtLeast(0.5f)
    val maxW = (metrics.widthPixels * 0.56f).roundToInt().coerceAtLeast(1)
    val maxH = (metrics.heightPixels * 0.14f).roundToInt().coerceAtLeast(1)
    var w = (widthDp * density).roundToInt().coerceAtLeast(1)
    var h = (heightDp * density).roundToInt().coerceAtLeast(1)
    val fit = minOf(maxW.toFloat() / w, maxH.toFloat() / h, 1f)
    w = (w * fit).roundToInt().coerceAtLeast(1)
    h = (h * fit).roundToInt().coerceAtLeast(1)
    return w to h
  }

  /** Keep each home-widget instance on its own room. Only a newly pinned widget takes the pending room. */
  private fun bindRoom(prefs: SharedPreferences, widgetId: Int): String {
    val bindings = mergedBindings(prefs)
    val key = widgetId.toString()
    val existing = bindings.optString(key, "")
    if (existing.isNotBlank()) return existing
    val pending = readString(prefs, "ddayPendingRoomId")
    val known = readJson(prefs, "ddayKnownWidgetIds")
    if (known.has(key)) {
      val legacy = readString(prefs, "ddayLegacyRoomId")
      if (legacy.isBlank() || legacy == pending) return ""
      bindings.put(key, legacy)
      writeBindings(prefs, bindings).apply()
      return legacy
    }
    val fallback = readString(prefs, "ddayRoomId")
    val room = if (pending.isNotBlank()) pending else fallback
    if (room.isBlank()) return ""
    bindings.put(key, room)
    val editor = writeBindings(prefs, bindings)
    if (pending.isNotBlank()) {
      editor.remove("ddayPendingRoomId").remove("flutter.ddayPendingRoomId")
    }
    editor.apply()
    return room
  }

  private fun mergedBindings(prefs: SharedPreferences): JSONObject {
    val merged = JSONObject()
    fun absorb(raw: String?) {
      if (raw.isNullOrBlank()) return
      try {
        val obj = JSONObject(raw)
        val keys = obj.keys()
        while (keys.hasNext()) {
          val key = keys.next()
          val value = obj.optString(key, "")
          if (value.isNotBlank()) merged.put(key, value)
        }
      } catch (_: Exception) {}
    }
    absorb(prefs.getString("ddayWidgetBindings", null))
    absorb(prefs.getString("flutter.ddayWidgetBindings", null))
    return merged
  }

  private fun writeBindings(
      prefs: SharedPreferences,
      bindings: JSONObject,
  ): SharedPreferences.Editor {
    val raw = bindings.toString()
    return prefs.edit().putString("ddayWidgetBindings", raw).putString("flutter.ddayWidgetBindings", raw)
  }

  private fun readJson(prefs: SharedPreferences, key: String): JSONObject {
    val raw = readString(prefs, key)
    if (raw.isBlank()) return JSONObject()
    return try {
      JSONObject(raw)
    } catch (_: Exception) {
      JSONObject()
    }
  }

  private fun roomStr(room: JSONObject?, key: String, fallback: String): String {
    if (room == null || !room.has(key)) return fallback
    return room.optString(key, fallback)
  }

  private fun roomInt(room: JSONObject?, key: String, fallback: Int): Int {
    if (room == null || !room.has(key)) return fallback
    return room.optInt(key, fallback)
  }

  private fun readShape(prefs: SharedPreferences): String {
    // Shape picker removed — always rounded rectangle.
    return "square"
  }

  private fun normalizeSize(raw: String): String {
    return when (raw) {
      "s33", "sq", "s22", "s",
      "s42", "l",
      "s43", "xl", "s24",
      "s32", "m", "s23", "tall",
      -> raw
      else -> "s42"
    }
  }

  private fun readSize(prefs: SharedPreferences): String {
    return normalizeSize(readString(prefs, "ddayWidgetSize"))
  }

  /** Keep the pin-sheet bitmap under the Binder limit. */
  private fun scaleForPinSheet(source: Bitmap, isPixel: Boolean): Bitmap {
    val maxEdge = 420
    val longest = max(source.width, source.height)
    if (longest <= maxEdge) return source
    val scale = maxEdge.toFloat() / longest
    val w = (source.width * scale).roundToInt().coerceAtLeast(1)
    val h = (source.height * scale).roundToInt().coerceAtLeast(1)
    val scaled = Bitmap.createScaledBitmap(source, w, h, !isPixel)
    if (scaled != source) source.recycle()
    return scaled
  }

  companion object {
    private const val TAG = "DdayWidget"
  }

  private fun readString(prefs: SharedPreferences, key: String): String {
    return prefs.getString(key, null)
        ?: prefs.getString("flutter.$key", null).orEmpty()
  }

  private fun readInt(prefs: SharedPreferences, key: String, default: Int): Int {
    return try {
      when (val raw = prefs.all[key] ?: prefs.all["flutter.$key"]) {
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
