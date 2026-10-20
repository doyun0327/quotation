package com.quotation.quotation

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.os.Build
import android.os.Bundle
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
    val preview = RemoteViews(packageName, R.layout.dday_widget_pin_prompt)
    val extras =
        Bundle().apply {
          putParcelable(AppWidgetManager.EXTRA_APPWIDGET_PREVIEW, preview)
        }
    return manager.requestPinAppWidget(provider, extras, null)
  }

  companion object {
    private const val CHANNEL = "com.quotation.quotation/widget_pin"
  }
}
