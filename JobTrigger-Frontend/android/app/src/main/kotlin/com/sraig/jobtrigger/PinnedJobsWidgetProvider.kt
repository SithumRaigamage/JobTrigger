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

        // AUD-54: the app lock is on, so the snapshot carries only how many
        // jobs are pinned (P14-25).
        val locked = snapshot != null && !snapshot.isNull("lockedCount")
        views.setViewVisibility(R.id.widget_locked, if (locked) View.VISIBLE else View.GONE)
        views.setViewVisibility(R.id.widget_header, if (locked) View.GONE else View.VISIBLE)
        if (locked) {
            val pinned = snapshot!!.optInt("lockedCount")
            views.setTextViewText(
                R.id.widget_locked_count,
                context.resources.getQuantityString(R.plurals.widget_locked_count, pinned, pinned),
            )
            views.setViewVisibility(R.id.widget_empty, View.GONE)
            ROWS.forEach { views.setViewVisibility(it.root, View.GONE) }
            manager.updateAppWidget(widgetId, views)
            return
        }

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
            val (textColor, dotColor) = colorsFor(context, job.optString("status"))
            views.setViewVisibility(row.root, View.VISIBLE)
            views.setTextViewText(row.label, job.optString("label"))
            // Status is spelled out, never color alone (NFR-A11Y-03).
            views.setTextViewText(row.status, job.optString("statusText"))
            views.setTextColor(row.status, textColor)
            views.setInt(row.dot, "setColorFilter", dotColor)
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

    // The app's status pill colors (AppColors); values-night has the dark pair.
    private fun colorsFor(context: Context, status: String): Pair<Int, Int> {
        val (text, dot) = when (status) {
            "success" -> R.color.widget_success_text to R.color.widget_success_dot
            "failure" -> R.color.widget_failure_text to R.color.widget_failure_dot
            "unstable" -> R.color.widget_unstable_text to R.color.widget_unstable_dot
            "running" -> R.color.widget_running_text to R.color.widget_running_dot
            else -> R.color.widget_neutral_text to R.color.widget_neutral_dot
        }
        return context.getColor(text) to context.getColor(dot)
    }

    private data class Row(val root: Int, val dot: Int, val label: Int, val status: Int)

    private companion object {
        const val SNAPSHOT_KEY = "snapshot"
        const val MEDIUM_MIN_HEIGHT_DP = 110

        val ROWS = listOf(
            Row(R.id.row1, R.id.row1_dot, R.id.row1_label, R.id.row1_status),
            Row(R.id.row2, R.id.row2_dot, R.id.row2_label, R.id.row2_status),
            Row(R.id.row3, R.id.row3_dot, R.id.row3_label, R.id.row3_status),
            Row(R.id.row4, R.id.row4_dot, R.id.row4_label, R.id.row4_status),
        )
    }
}
