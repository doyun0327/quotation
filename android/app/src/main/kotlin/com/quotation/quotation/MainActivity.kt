package com.quotation.quotation

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.widget.RemoteViews
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
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
        "pinCharacterWidget" -> result.success(pinCharacterWidget())
        "refreshCharacterWidget" -> {
          refreshWidget(DailyWordWidgetProvider(), DailyWordWidgetProvider::class.java)
          result.success(true)
        }
        "refreshTogetherWidget" -> {
          refreshWidget(DdayWidgetProvider(), DdayWidgetProvider::class.java)
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

  private fun pinCharacterWidget(): Boolean {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
    val manager = AppWidgetManager.getInstance(applicationContext)
    if (!manager.isRequestPinAppWidgetSupported) return false
    val provider = ComponentName(applicationContext, DailyWordWidgetProvider::class.java)
    val prefs = es.antonborri.home_widget.HomeWidgetPlugin.getData(applicationContext)
    val quote =
        prefs.getString("quoteText", null)?.trim().orEmpty().ifEmpty {
          prefs.getString("flutter.quoteText", null)?.trim().orEmpty()
        }
    val characterId =
        prefs.getString("characterId", null)
            ?: prefs.getString("flutter.characterId", null)
            ?: "basic"
    val bitmap =
        DailyWordWidgetProvider.buildPinBitmap(
            context = applicationContext,
            widgetData = prefs,
            quote = quote,
            characterId = characterId,
        )
    val views =
        DdayWidgetProvider().wrapPinPreview(
            context = applicationContext,
            bitmap = bitmap,
            widthDp = 200f,
            heightDp = 86f,
        )
    val extras =
        Bundle().apply {
          putParcelable(AppWidgetManager.EXTRA_APPWIDGET_PREVIEW, views)
        }
    return manager.requestPinAppWidget(provider, extras, null)
  }

  /** Draws placed widgets immediately. A broadcast to the provider can be dropped. */
  private fun refreshWidget(provider: AppWidgetProvider, clazz: Class<out AppWidgetProvider>) {
    val manager = AppWidgetManager.getInstance(applicationContext)
    val ids = manager.getAppWidgetIds(ComponentName(applicationContext, clazz))
    if (ids.isEmpty()) return
    provider.onUpdate(applicationContext, manager, ids)
  }

  companion object {
    private const val CHANNEL = "com.quotation.quotation/widget_pin"
    private const val TAG = "WidgetPin"
  }
}
