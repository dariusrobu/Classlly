package com.robudarius.classlly

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetProvider

class ClassllyWidget : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.classlly_widget).apply {
                setTextViewText(R.id.next_class_title, widgetData.getString("next_class_title", "No classes"))
                setTextViewText(R.id.next_class_time, widgetData.getString("next_class_time", ""))
                setTextViewText(R.id.next_task_title, widgetData.getString("next_task_title", "No tasks"))

                // Handle Task Completion Click
                // Note: In a real app, we'd pass the actual Task ID here. 
                // For the "Next Task" widget, we'll trigger a generic refresh/complete next logic.
                val backgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    Uri.parse("classlly://completeTask?id=next")
                )
                setOnClickPendingIntent(R.id.btn_complete_task, backgroundIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}