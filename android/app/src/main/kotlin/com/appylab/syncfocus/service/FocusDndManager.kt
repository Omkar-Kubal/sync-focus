package com.appylab.syncfocus.service

import android.app.NotificationManager
import android.content.Context

/** Applies DND only while a running focus session owns the interruption filter. */
internal class FocusDndManager(context: Context) {
    private val notificationManager =
        context.getSystemService(NotificationManager::class.java)
    private val preferences =
        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)

    @Synchronized
    fun enableForFocus() {
        if (!notificationManager.isNotificationPolicyAccessGranted) return
        if (!preferences.getBoolean(KEY_MANAGED, false)) {
            preferences.edit()
                .putInt(KEY_PREVIOUS_FILTER, notificationManager.currentInterruptionFilter)
                .putBoolean(KEY_MANAGED, true)
                .apply()
        }
        runCatching {
            if (notificationManager.currentInterruptionFilter != NotificationManager.INTERRUPTION_FILTER_PRIORITY) {
                notificationManager.setInterruptionFilter(
                    NotificationManager.INTERRUPTION_FILTER_PRIORITY,
                )
            }
        }.onFailure { restoreAfterFocus() }
    }

    @Synchronized
    fun restoreAfterFocus() {
        if (!preferences.getBoolean(KEY_MANAGED, false)) return
        val previous = preferences.getInt(
            KEY_PREVIOUS_FILTER,
            NotificationManager.INTERRUPTION_FILTER_ALL,
        )
        runCatching {
            if (notificationManager.isNotificationPolicyAccessGranted &&
                notificationManager.currentInterruptionFilter == NotificationManager.INTERRUPTION_FILTER_PRIORITY
            ) {
                notificationManager.setInterruptionFilter(previous)
            }
        }
        preferences.edit().remove(KEY_MANAGED).remove(KEY_PREVIOUS_FILTER).apply()
    }

    companion object {
        private const val PREFERENCES = "sync_focus_dnd_state"
        private const val KEY_MANAGED = "managed_by_sync_focus"
        private const val KEY_PREVIOUS_FILTER = "previous_interruption_filter"
    }
}
