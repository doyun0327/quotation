package com.quotation.quotation

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.os.Bundle
import android.widget.RemoteViews
import kotlin.math.roundToInt
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
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
    val room = readJson(widgetData, "ddayRoomsJson").optJSONObject(roomId)
    val label = roomStr(room, "label", readString(widgetData, "ddayLabel"))
    val meId = roomStr(room, "me", readString(widgetData, "ddayCharMe")).ifBlank { "basic" }
    val friendId = roomStr(room, "friend", readString(widgetData, "ddayCharFriend"))
    val style = readString(widgetData, "visualStyle").ifBlank { "pixel" }
    val meOffsetX = roomInt(room, "meX", readInt(widgetData, "ddayMeOffsetX", 0))
    val meOffsetY = roomInt(room, "meY", readInt(widgetData, "ddayMeOffsetY", 0))
    val friendOffsetX = roomInt(room, "friendX", readInt(widgetData, "ddayFriendOffsetX", 0))
    val friendOffsetY = roomInt(room, "friendY", readInt(widgetData, "ddayFriendOffsetY", 0))
    val textOffsetX = roomInt(room, "textX", readInt(widgetData, "ddayTextOffsetX", 0))
    val textOffsetY = roomInt(room, "textY", readInt(widgetData, "ddayTextOffsetY", 0))
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
            meId = meId,
            friendId = friendId,
            meOffsetX = meOffsetX,
            meOffsetY = meOffsetY,
            friendOffsetX = friendOffsetX,
            friendOffsetY = friendOffsetY,
            charScale = charScale,
            friendScale = friendScale,
            sizeCharFactor = DdayWidgetVisuals.charFactor(sizeId),
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
          setImageViewBitmap(R.id.dday_composite, composite)
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

  /** Keep each home-widget instance on its own room. A new widget takes [ddayPendingRoomId]. */
  private fun bindRoom(prefs: SharedPreferences, widgetId: Int): String {
    val bindings = readJson(prefs, "ddayWidgetBindings")
    val key = widgetId.toString()
    val existing = bindings.optString(key, "")
    if (existing.isNotBlank()) return existing
    val pending = readString(prefs, "ddayPendingRoomId")
    val fallback = readString(prefs, "ddayRoomId")
    val room = if (pending.isNotBlank()) pending else fallback
    if (room.isBlank()) return ""
    bindings.put(key, room)
    val editor = prefs.edit().putString("ddayWidgetBindings", bindings.toString())
    if (pending.isNotBlank()) {
      editor.remove("ddayPendingRoomId").remove("flutter.ddayPendingRoomId")
    }
    editor.apply()
    return room
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

  private fun readSize(prefs: SharedPreferences): String {
    val raw = readString(prefs, "ddayWidgetSize")
    return when (raw) {
      "s33", "sq", "s22", "s",
      "s42", "l",
      "s43", "xl", "s24",
      "s32", "m", "s23", "tall",
      -> raw
      else -> "s42"
    }
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
