package com.sraig.jobtrigger

import android.content.Context

/**
 * US-SQ-WIDGET-01: pinned SonarQube projects on the home screen. The same
 * rows and states as the pinned-jobs widget, reading the snapshot the app
 * writes under its own key. It never calls SonarQube and holds no credential;
 * a tap opens the project through the `jobtrigger://app/sonarqube/project`
 * deep link (US-SQ-LINK-02).
 */
class PinnedProjectsWidgetProvider : PinnedJobsWidgetProvider() {
    override val snapshotKey: String = "sonarqube_snapshot"

    override fun title(context: Context): String =
        context.getString(R.string.widget_projects_title)

    override fun emptyText(context: Context): String =
        context.getString(R.string.widget_projects_empty)

    override fun upgradeHint(context: Context): String =
        context.getString(R.string.widget_projects_upgrade_hint)

    override fun lockedCount(context: Context, count: Int): String =
        context.resources.getQuantityString(R.plurals.widget_projects_locked_count, count, count)
}
