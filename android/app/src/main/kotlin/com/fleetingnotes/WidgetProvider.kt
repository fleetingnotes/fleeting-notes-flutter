package com.appwidgetflutter

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
// import es.antonborri.home_widget.R
import com.fleetingnotes.R
import com.fleetingnotes.MainActivity

class WidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {

                // Open App on Widget Click
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(context,
                        MainActivity::class.java)
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
                // setOnClickPendingIntent(R.id.bt_add, pendingIntent)

                // val counter = widgetData.getInt("_counter", 0)

                // var counterText = "Your counter value is: $counter"

                // if (counter == 0) {
                //     counterText = "You have not pressed the counter button"
                // }

                // setTextViewText(R.id.tv_counter, counterText)

                // Pending intent to update counter on button click
                val backgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(context,
                        Uri.parse("myAppWidget://updatecounter"))
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}