package com.fleetingnotes;

import android.appwidget.AppWidgetManager;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.net.Uri
import android.view.View
import android.widget.RemoteViews;
import android.widget.RemoteViewsService;
import kotlinx.serialization.*
import kotlinx.serialization.json.*
import es.antonborri.home_widget.HomeWidgetPlugin

//dev
import android.util.Log

public class ListWidgetService: RemoteViewsService() {
  override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
    return ListRemoteViewsFactory(this.applicationContext, intent)
  }
}

private const val REMOTE_VIEW_COUNT: Int = 10
@Serializable
data class NoteItem(val id: String, val title: String, val content: String, val source: String, val timestamp: String)

class ListRemoteViewsFactory(
        private val context: Context,
        intent: Intent
) : RemoteViewsService.RemoteViewsFactory {
  private var noteItems: List<NoteItem> = listOf<NoteItem>();

  override fun onCreate() {
    // In onCreate() you setup any connections / cursors to your data
    // source. Heavy lifting, for example downloading or creating content
    // etc, should be deferred to onDataSetChanged() or getViewAt(). Taking
    // more than 20 seconds in this call will result in an ANR.
    // widgetItems = List(REMOTE_VIEW_COUNT) { index -> WidgetItem("$index!") }
  }
  override fun getViewAt(position: Int): RemoteViews {
      // Construct a remote views item based on the widget item XML file,
      // and set the text based on the position.
      return RemoteViews(context.packageName, R.layout.note_card_layout).apply {
          setTextViewText(R.id.title_text_view, noteItems[position].title)
          setTextViewText(R.id.content_text_view, noteItems[position].content)
          // Next, set a fill-intent, which will be used to fill in the pending intent template
          // that is set on the collection view in StackWidgetProvider.
          val fillInIntent = Intent().apply {
              Bundle().also { extras ->
                  extras.putString(EXTRA_ITEM, noteItems[position].id)
                  putExtras(extras)
              }
          }
          // Make it possible to distinguish the individual on-click
          // action of a given item
          setOnClickFillInIntent(R.id.note_container, fillInIntent)
      }
  }
  override fun onDataSetChanged() {
    val widgetData = HomeWidgetPlugin.getData(context)
    val notesStr = widgetData.getString("notes", "[]") ?: "[]"
    noteItems = Json.decodeFromString<List<NoteItem>>(notesStr)
  }
  override fun onDestroy() {

  }
  override fun getCount(): Int {
      return noteItems.size;
  }

  override fun getLoadingView(): RemoteViews? {
      return null
  }

  override fun getViewTypeCount(): Int {
      return 1
  }

  override fun getItemId(position: Int): Long {
      return noteItems[position].hashCode().toLong()
  }

  override fun hasStableIds(): Boolean {
      return true
  }

}