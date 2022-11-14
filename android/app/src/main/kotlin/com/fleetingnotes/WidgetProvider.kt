package com.fleetingnotes

import android.os.Build
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.app.PendingIntent;
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import android.util.Log
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
// import es.antonborri.home_widget.R
import com.fleetingnotes.R
import com.fleetingnotes.MainActivity

const val EXTRA_ITEM = "com.fleetingnotes.EXTRA_ITEM"
class WidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            Log.d("TAG", "onUpdate")
            val intent = Intent(context, ListWidgetService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                // When intents are compared, the extras are ignored, so we need to embed the extras
                // into the data so that the extras will not be ignored.
                data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
            }
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                // Open App on Widget Click
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(context,
                        MainActivity::class.java,
                        Uri.parse("fleetingNotesWidget://note?id=createNote"))
                setOnClickPendingIntent(R.id.add_note_bt, pendingIntent)
                setRemoteAdapter(R.id.notes_list, intent)
                
                // tell widget to refresh its data
                appWidgetManager.notifyAppWidgetViewDataChanged(widgetId, R.id.notes_list)
            }
            val clickPendingIntentTemplate: PendingIntent = Intent(
                    context,
                    WidgetProvider::class.java
            ).run {
                action = HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
                var flags = PendingIntent.FLAG_UPDATE_CURRENT
                if (Build.VERSION.SDK_INT >= 23) {
                    // https://stackoverflow.com/a/71829122/13659833
                    flags = flags or PendingIntent.FLAG_MUTABLE
                }
                PendingIntent.getBroadcast(context, 0, this, flags)
            }
            views.setPendingIntentTemplate(R.id.notes_list, clickPendingIntentTemplate)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
    override fun onReceive(context: Context, intent: Intent) {
      // open note on receieve
      if (intent.action === HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION) {
        val noteId = intent.getStringExtra(EXTRA_ITEM).toString()
        val pendingIntent = HomeWidgetLaunchIntent.getActivity(context,
                MainActivity::class.java,
                Uri.parse("fleetingNotesWidget://note?id=$noteId"))
        pendingIntent.send()
      }
      super.onReceive(context, intent)
    }
}