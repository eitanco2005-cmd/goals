package app.goalschallenge.goals_challenge

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.view.Gravity
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home-screen widget: rotates through the group members' photos of today, with
 * their names, daily % and (for one other member) the goals they completed.
 *
 * The Flutter app (and its 15-minute background job) writes the data and
 * calls updateWidget; this class only renders it.
 */
class PartnerWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val snapshot = PartnerWidgetSnapshot.parse(
            widgetData.getString(PartnerWidgetSnapshot.KEY, null)
        )
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, buildViews(context, id, snapshot))
            @Suppress("DEPRECATION")
            appWidgetManager.notifyAppWidgetViewDataChanged(id, R.id.widget_flipper)
        }
    }

    private fun buildViews(
        context: Context,
        widgetId: Int,
        snapshot: PartnerWidgetSnapshot?,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.partner_widget)
        val openApp = context.getString(R.string.widget_open_app)

        views.setTextViewText(R.id.widget_title, snapshot?.title ?: openApp)
        views.setTextViewText(R.id.widget_status, snapshot?.status ?: "")
        views.setTextViewText(R.id.widget_empty, snapshot?.emptyText ?: openApp)

        // Align texts to the app's language (Hebrew = right), not the
        // phone's.
        val side = if (snapshot?.rtl == true) Gravity.RIGHT else Gravity.LEFT
        views.setInt(R.id.widget_title, "setGravity", side or Gravity.CENTER_VERTICAL)
        views.setInt(R.id.widget_status, "setGravity", side or Gravity.CENTER_VERTICAL)

        // The rotating photos come from PartnerWidgetService. The extras make
        // the intent unique per widget and per snapshot, so Android rebinds.
        val adapter = Intent(context, PartnerWidgetService::class.java).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
            putExtra(EXTRA_VERSION, snapshot?.updatedAt ?: 0L)
            data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
        }
        @Suppress("DEPRECATION")
        views.setRemoteAdapter(R.id.widget_flipper, adapter)
        views.setEmptyView(R.id.widget_flipper, R.id.widget_empty)

        // Tapping anywhere opens the app.
        views.setOnClickPendingIntent(
            R.id.widget_root,
            HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
        )
        views.setPendingIntentTemplate(R.id.widget_flipper, photoClickTemplate(context))
        return views
    }

    /** Collection items need a mutable template that their fill-in intents complete. */
    private fun photoClickTemplate(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            flags = flags or PendingIntent.FLAG_MUTABLE
        }
        return PendingIntent.getActivity(context, 1, intent, flags)
    }

    companion object {
        private const val EXTRA_VERSION = "snapshotVersion"
    }
}
