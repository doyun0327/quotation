package com.quotation.quotation

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.widget.RemoteViews
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    val appContext = applicationContext
    widgetWorker.execute { DailyWordWidgetProvider.publishPickerPreviews(appContext) }
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
        call,
        result ->
      when (call.method) {
        "pinTogetherWidget" -> {
          val size =
              call.argument<String>("size")
                  ?: call.argument<String>("provider")
                  ?: "s42"
          result.success(pinTogetherWidget(size))
        }
        "pinCharacterWidget" ->
            result.success(pinCharacterWidget(bubble = call.argument<String>("style") == "bubble"))
        "refreshCharacterWidget" -> {
          val appContext = applicationContext
          offMain(result) { DailyWordWidgetProvider.refreshQuoteFamily(appContext) }
        }
        "refreshTogetherWidget" -> offMain(result) { refreshTogetherWidgets() }
        "togetherWidgetState" -> result.success(togetherWidgetState())
        "isSamsungDevice" ->
          result.success(Build.MANUFACTURER.equals("samsung", ignoreCase = true))
        "scheduleMorningFortunes" -> {
          val items = call.argument<List<*>>("items") ?: emptyList<Any>()
          val parsed =
              items.mapNotNull { entry ->
                val map = entry as? Map<*, *> ?: return@mapNotNull null
                mapOf<String, Any?>(
                    "at" to map["at"],
                    "title" to map["title"],
                    "body" to map["body"],
                )
              }
          MorningFortuneAlarm.schedule(applicationContext, parsed)
          result.success(true)
        }
        "cancelMorningFortunes" -> {
          MorningFortuneAlarm.cancel(applicationContext)
          result.success(true)
        }
        else -> result.notImplemented()
      }
    }
  }

  private fun pinTogetherWidget(sizeId: String): Boolean {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
    val manager = AppWidgetManager.getInstance(applicationContext)
    if (!manager.isRequestPinAppWidgetSupported) return false
    // 3×3 / 4×2 / 4×3 / 3×2
    val providerClass =
        when (sizeId) {
          "s33", "sq", "s22", "s" -> DdayWidgetProviderSq::class.java
          "s43", "xl", "s24" -> DdayWidgetProviderXl::class.java
          "s32", "m", "s23" -> DdayWidgetProviderM::class.java
          "tall" -> DdayWidgetProviderTall::class.java
          else -> DdayWidgetProvider::class.java // s42 / l
        }
    val provider = ComponentName(applicationContext, providerClass)
    val preview =
        try {
          DdayWidgetProvider().buildPinPreview(applicationContext, sizeId)
        } catch (e: Exception) {
          Log.w(TAG, "pin preview fell back", e)
          RemoteViews(packageName, R.layout.dday_widget_preview)
        }
    val extras =
        Bundle().apply {
          putParcelable(AppWidgetManager.EXTRA_APPWIDGET_PREVIEW, preview)
        }
    return manager.requestPinAppWidget(provider, extras, null)
  }

  private fun pinCharacterWidget(bubble: Boolean): Boolean {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
    val manager = AppWidgetManager.getInstance(applicationContext)
    if (!manager.isRequestPinAppWidgetSupported) return false
    val providerClass =
        if (bubble) DailyWordBubbleWidgetProvider::class.java
        else DailyWordWidgetProvider::class.java
    val provider = ComponentName(applicationContext, providerClass)
    val prefs = es.antonborri.home_widget.HomeWidgetPlugin.getData(applicationContext)
    val bitmap =
        DailyWordWidgetProvider.buildPinBitmap(
            context = applicationContext,
            widgetData = prefs,
            bubble = bubble,
        )
    val views =
        DdayWidgetProvider().wrapPinPreview(
            context = applicationContext,
            bitmap = bitmap,
            widthDp = 300f,
            heightDp = 168f,
        )
    val extras =
        Bundle().apply {
          putParcelable(AppWidgetManager.EXTRA_APPWIDGET_PREVIEW, views)
        }
    return manager.requestPinAppWidget(provider, extras, null)
  }

  private fun togetherProviderClasses(): List<Class<out AppWidgetProvider>> =
      listOf(
          DdayWidgetProvider::class.java,
          DdayWidgetProviderSq::class.java,
          DdayWidgetProviderXl::class.java,
          DdayWidgetProviderM::class.java,
          DdayWidgetProviderS::class.java,
          DdayWidgetProviderTall::class.java,
      )

  private fun togetherWidgetIds(): List<Int> {
    val manager = AppWidgetManager.getInstance(applicationContext)
    return togetherProviderClasses()
        .flatMap { clazz ->
          manager.getAppWidgetIds(ComponentName(applicationContext, clazz)).toList()
        }
        .distinct()
  }

  /** Ids already on the home screen, plus the room each one is locked to. */
  private fun togetherWidgetState(): Map<String, Any> {
    val prefs = es.antonborri.home_widget.HomeWidgetPlugin.getData(applicationContext)
    val bindings = mutableMapOf<String, String>()
    fun absorb(raw: String?) {
      if (raw.isNullOrBlank()) return
      try {
        val obj = org.json.JSONObject(raw)
        val keys = obj.keys()
        while (keys.hasNext()) {
          val key = keys.next()
          val value = obj.optString(key, "")
          if (value.isNotBlank()) bindings[key] = value
        }
      } catch (_: Exception) {}
    }
    absorb(prefs.getString("ddayWidgetBindings", null))
    absorb(prefs.getString("flutter.ddayWidgetBindings", null))
    return mapOf("ids" to togetherWidgetIds(), "bindings" to bindings)
  }

  private fun refreshTogetherWidgets() {
    val manager = AppWidgetManager.getInstance(applicationContext)
    for (clazz in togetherProviderClasses()) {
      val ids = manager.getAppWidgetIds(ComponentName(applicationContext, clazz))
      if (ids.isEmpty()) continue
      val provider =
          clazz.getDeclaredConstructor().newInstance() as AppWidgetProvider
      provider.onUpdate(applicationContext, manager, ids)
    }
    DailyWordWidgetProvider.publishPickerPreviews(applicationContext)
  }

  /** Draws placed widgets immediately. A broadcast to the provider can be dropped. */
  private fun refreshWidget(provider: AppWidgetProvider, clazz: Class<out AppWidgetProvider>) {
    val manager = AppWidgetManager.getInstance(applicationContext)
    val ids = manager.getAppWidgetIds(ComponentName(applicationContext, clazz))
    if (ids.isEmpty()) return
    provider.onUpdate(applicationContext, manager, ids)
  }

  /**
   * Widget bitmaps (1600px backgrounds, every size, picker previews) take
   * seconds. Flutter now shares Android's main thread, so drawing there froze
   * the app until the widget was done. One worker keeps redraws in order.
   */
  private fun offMain(result: MethodChannel.Result, work: () -> Unit) {
    widgetWorker.execute {
      val ok =
          try {
            work()
            true
          } catch (e: Exception) {
            Log.e(TAG, "widget refresh failed", e)
            false
          }
      mainHandler.post { result.success(ok) }
    }
  }

  companion object {
    private val widgetWorker = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private const val CHANNEL = "com.quotation.quotation/widget_pin"
    private const val TAG = "WidgetPin"
  }
}
