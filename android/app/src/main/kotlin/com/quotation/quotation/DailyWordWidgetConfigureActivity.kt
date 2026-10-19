package com.quotation.quotation

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.RadioGroup
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Lets the user pick which home-screen category the app (and widget quote) should follow.
 * The bubble text itself always comes from the Flutter home screen sync.
 */
class DailyWordWidgetConfigureActivity : Activity() {
  private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    setResult(RESULT_CANCELED)

    setContentView(R.layout.daily_word_widget_configure)

    appWidgetId =
        intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

    if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
      finish()
      return
    }

    val prefs = HomeWidgetPlugin.getData(this)
    val current = prefs.getString("categoryId", "comfort") ?: "comfort"
    val group = findViewById<RadioGroup>(R.id.category_group)

    when (current) {
      "faith" -> group.check(R.id.category_faith)
      "literature" -> group.check(R.id.category_literature)
      "daily" -> group.check(R.id.category_daily)
      else -> group.check(R.id.category_comfort)
    }

    findViewById<Button>(R.id.btn_add).setOnClickListener {
      val selectedId = group.checkedRadioButtonId
      val (categoryId, categoryTitle) =
          when (selectedId) {
            R.id.category_faith -> "faith" to getString(R.string.widget_category_faith)
            R.id.category_literature ->
                "literature" to getString(R.string.widget_category_literature)
            R.id.category_daily -> "daily" to getString(R.string.widget_category_daily)
            else -> "comfort" to getString(R.string.widget_category_comfort)
          }

      prefs
          .edit()
          .putString("categoryId", categoryId)
          .putString("categoryTitle", categoryTitle)
          .apply()

      val manager = AppWidgetManager.getInstance(this)
      val provider = DailyWordWidgetProvider()
      provider.onUpdate(this, manager, intArrayOf(appWidgetId), prefs)

      val result =
          Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
      setResult(RESULT_OK, result)
      finish()
    }
  }
}
