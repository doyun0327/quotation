package com.quotation.quotation

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import org.json.JSONArray
import org.json.JSONObject

/** One local notification at 08:00. A second delivery within two minutes is dropped. */
object MorningFortuneAlarm {
  private const val PREFS = "morning_fortune_alarm"
  private const val KEY_ITEMS = "items"
  private const val KEY_SHOWN_AT = "shownAt"
  const val ACTION = "com.quotation.quotation.MORNING_FORTUNE"
  private const val CHANNEL_ID = "daily_encouragement"
  private const val NOTIFICATION_ID = 6400
  private const val REQUEST_BASE = 8800
  private const val DAY_COUNT = 14
  private const val DEDUPE_MS = 2 * 60 * 1000L

  fun cancel(context: Context) {
    context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().remove(KEY_ITEMS).apply()
    val alarmManager = context.getSystemService(AlarmManager::class.java) ?: return
    for (i in 0 until DAY_COUNT) {
      alarmManager.cancel(pending(context, i))
    }
  }

  fun schedule(context: Context, items: List<Map<String, Any?>>) {
    val array = JSONArray()
    for (item in items) {
      val at = (item["at"] as? Number)?.toLong() ?: continue
      val title = item["title"]?.toString().orEmpty()
      val body = item["body"]?.toString().orEmpty()
      if (title.isEmpty() || body.isEmpty()) continue
      array.put(
          JSONObject()
              .put("at", at)
              .put("title", title)
              .put("body", body),
      )
    }
    context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
        .putString(KEY_ITEMS, array.toString())
        .apply()
    arm(context, array)
  }

  fun armStored(context: Context) {
    val raw =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY_ITEMS, null)
            ?: return
    arm(context, JSONArray(raw))
  }

  fun shouldShow(context: Context, now: Long): Boolean {
    val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    val last = prefs.getLong(KEY_SHOWN_AT, 0L)
    if (now - last < DEDUPE_MS) return false
    prefs.edit().putLong(KEY_SHOWN_AT, now).apply()
    return true
  }

  private fun arm(context: Context, items: JSONArray) {
    val alarmManager = context.getSystemService(AlarmManager::class.java) ?: return
    for (i in 0 until DAY_COUNT) {
      alarmManager.cancel(pending(context, i))
    }
    val now = System.currentTimeMillis()
    for (i in 0 until items.length()) {
      val item = items.optJSONObject(i) ?: continue
      val at = item.optLong("at")
      if (at <= now) continue
      val intent =
          Intent(context, MorningFortuneReceiver::class.java).apply {
            action = ACTION
            putExtra("title", item.optString("title"))
            putExtra("body", item.optString("body"))
            putExtra("at", at)
            putExtra("slot", i)
          }
      val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
      val pending =
          PendingIntent.getBroadcast(context, REQUEST_BASE + i, intent, flags)
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending)
      } else {
        alarmManager.set(AlarmManager.RTC_WAKEUP, at, pending)
      }
    }
  }

  private fun pending(context: Context, slot: Int): PendingIntent {
    val intent =
        Intent(context, MorningFortuneReceiver::class.java).apply { action = ACTION }
    val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    return PendingIntent.getBroadcast(context, REQUEST_BASE + slot, intent, flags)
  }
}

class MorningFortuneReceiver : BroadcastReceiver() {
  override fun onReceive(context: Context, intent: Intent?) {
    if (intent?.action == Intent.ACTION_BOOT_COMPLETED ||
        intent?.action == Intent.ACTION_MY_PACKAGE_REPLACED
    ) {
      MorningFortuneAlarm.armStored(context)
      return
    }
    if (intent?.action != MorningFortuneAlarm.ACTION) return
    val now = System.currentTimeMillis()
    if (!MorningFortuneAlarm.shouldShow(context, now)) return
    val title = intent.getStringExtra("title").orEmpty()
    val body = intent.getStringExtra("body").orEmpty()
    if (title.isEmpty() || body.isEmpty()) return
    val at = intent.getLongExtra("at", now)

    val manager = context.getSystemService(NotificationManager::class.java)
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      val channel =
          NotificationChannel(
              "daily_encouragement",
              "Daily encouragement",
              NotificationManager.IMPORTANCE_HIGH,
          )
      channel.description = "Fortune at 8:00 and one afternoon encouragement"
      manager?.createNotificationChannel(channel)
    }

    val launch =
        PendingIntent.getActivity(
            context,
            0,
            Intent(context, MainActivity::class.java).apply {
              flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    val notification =
        NotificationCompat.Builder(context, "daily_encouragement")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setWhen(at)
            .setShowWhen(true)
            .setAutoCancel(true)
            .setContentIntent(launch)
            .setOnlyAlertOnce(true)
            .build()
    try {
      NotificationManagerCompat.from(context).notify(6400, notification)
    } catch (_: SecurityException) {}
  }
}
