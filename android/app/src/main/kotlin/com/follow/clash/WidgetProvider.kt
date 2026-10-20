package com.follow.clash

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.follow.clash.common.QuickAction
import com.follow.clash.common.action

/**
 * The home screen tile: it says whether the VPN runs and toggles it through the
 * same quick action the shortcut uses, so it never needs its own state.
 */
class WidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { update(context, appWidgetManager, it) }
    }

    companion object {
        private const val FLAGS =
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE

        /** Every placed widget, called whenever the run state changes. */
        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context) ?: return
            val ids = manager.getAppWidgetIds(
                ComponentName(context, WidgetProvider::class.java),
            )
            ids.forEach { update(context, manager, it) }
        }

        private fun update(context: Context, manager: AppWidgetManager, id: Int) {
            val running = ServiceState.runState.value == RunState.STARTED
            val views = RemoteViews(context.packageName, R.layout.widget)
            views.setTextViewText(
                R.id.widget_status,
                context.getString(
                    if (running) R.string.widget_running else R.string.widget_stopped,
                ),
            )
            views.setTextViewText(
                R.id.widget_toggle,
                context.getString(
                    if (running) R.string.widget_stop else R.string.widget_start,
                ),
            )
            views.setOnClickPendingIntent(R.id.widget_toggle, toggleIntent(context))
            views.setOnClickPendingIntent(R.id.widget_root, openIntent(context))
            manager.updateAppWidget(id, views)
        }

        private fun toggleIntent(context: Context): PendingIntent {
            val intent = Intent(context, QuickActionActivity::class.java)
                .setAction(QuickAction.TOGGLE.action)
            return PendingIntent.getActivity(context, 1, intent, FLAGS)
        }

        private fun openIntent(context: Context): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            return PendingIntent.getActivity(context, 0, intent, FLAGS)
        }
    }
}
