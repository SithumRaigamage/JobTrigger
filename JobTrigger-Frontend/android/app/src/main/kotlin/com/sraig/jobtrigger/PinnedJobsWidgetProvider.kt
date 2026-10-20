package com.sraig.jobtrigger

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Bundle
import android.text.format.DateUtils
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject

/**
 * US-JX-23: pinned jobs on the home screen. Renders the snapshot the app
 * writes (`HomeWidgetBridge`); it never fetches from Jenkins and holds no
 * credentials. A tap opens the job through the US-JX-19 deep link.
 */
class PinnedJobsWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            render(context, appWidgetManager, id, widgetData)
        }
    }

    // Resizing between small and medium changes how many rows fit.
    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        render(context, appWidgetManager, appWidgetId, HomeWidgetPlugin.getData(context))
    }

    private fun render(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
        data: SharedPreferences,
    ) {
        val views = RemoteViews(context.packageName, R.layout.pinned_jobs_widget)
        val snapshot = data.getString(SNAPSHOT_KEY, null)?.let {
            runCatching { JSONObject(it) }.getOrNull()
        }
        val jobs = snapshot?.optJSONArray("jobs")
        val minHeight = manager.getAppWidgetOptions(widgetId)
            .getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
        val capacity = if (minHeight in 1 until MEDIUM_MIN_HEIGHT_DP) 2 else ROWS.size

        views.setOnClickPendingIntent(R.id.widget_root, openApp(context, widgetId))
        val count = minOf(jobs?.length() ?: 0, capacity)
        views.setViewVisibility(R.id.widget_empty, if (count == 0) View.VISIBLE else View.GONE)

        val updatedAt = snapshot?.optLong("updatedAt", 0L) ?: 0L
        views.setTextViewText(
            R.id.widget_updated,
            if (count > 0 && updatedAt > 0) {
                context.getString(R.string.widget_updated, relative(updatedAt))
            } else {
                ""
            },
        )

        ROWS.forEachIndexed { index, row ->
            if (index >= count) {
                views.setViewVisibility(row.root, View.GONE)
                return@forEachIndexed
            }
            val job = jobs!!.getJSONObject(index)
            views.setViewVisibility(row.root, View.VISIBLE)
            views.setTextViewText(row.label, job.optString("label"))
            val number = if (job.isNull("buildNumber")) null else job.optInt("buildNumber")
            val started = if (job.isNull("buildTimestamp")) null else job.optLong("buildTimestamp")
            val detail = buildString {
                append(job.optString("statusText"))
                if (number != null) append(" · #").append(number)
                if (started != null && started > 0) append(" · ").append(relative(started))
            }
            views.setTextViewText(row.detail, detail)
            views.setInt(row.dot, "setColorFilter", colorFor(job.optString("status")))
            views.setOnClickPendingIntent(
                row.root,
                openLink(context, widgetId * ROWS.size + index, job.optString("link")),
            )
        }
        manager.updateAppWidget(widgetId, views)
    }

    private fun relative(millis: Long): CharSequence = DateUtils.getRelativeTimeSpanString(
        millis,
        System.currentTimeMillis(),
        DateUtils.MINUTE_IN_MILLIS,
        DateUtils.FORMAT_ABBREV_RELATIVE,
    )

    private fun openLink(context: Context, requestCode: Int, link: String): PendingIntent {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(link))
            .setPackage(context.packageName)
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    private fun openApp(context: Context, widgetId: Int): PendingIntent {
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?: Intent(context, MainActivity::class.java)
        return PendingIntent.getActivity(
            context,
            -1 - widgetId,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    // Matches AppColors: build success/failure/unstable, brand, grey.
    private fun colorFor(status: String): Int = when (status) {
        "success" -> 0xFF4CAF50.toInt()
        "failure" -> 0xFFF44336.toInt()
        "unstable" -> 0xFFFF9800.toInt()
        "running" -> 0xFF007AFF.toInt()
        else -> 0xFF9E9E9E.toInt()
    }

    private data class Row(val root: Int, val dot: Int, val label: Int, val detail: Int)

    private companion object {
        const val SNAPSHOT_KEY = "snapshot"
        const val MEDIUM_MIN_HEIGHT_DP = 110

        val ROWS = listOf(
            Row(R.id.row1, R.id.row1_dot, R.id.row1_label, R.id.row1_detail),
            Row(R.id.row2, R.id.row2_dot, R.id.row2_label, R.id.row2_detail),
            Row(R.id.row3, R.id.row3_dot, R.id.row3_label, R.id.row3_detail),
            Row(R.id.row4, R.id.row4_dot, R.id.row4_label, R.id.row4_detail),
        )
    }
}
