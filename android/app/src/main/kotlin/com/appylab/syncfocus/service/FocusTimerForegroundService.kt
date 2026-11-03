package com.appylab.syncfocus.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import com.appylab.syncfocus.MainActivity
import com.appylab.syncfocus.R
import com.appylab.syncfocus.widget.FocusWidgetStateStore
import kotlin.math.max

/** Keeps a user-started focus countdown alive while Flutter is backgrounded. */
class FocusTimerForegroundService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private val notificationManager by lazy {
        getSystemService(NotificationManager::class.java)
    }

    private var phase = PHASE_READY
    private var durationSeconds = DEFAULT_DURATION_SECONDS
    private var focusDurationSeconds = DEFAULT_DURATION_SECONDS
    private var breakDurationSeconds = DEFAULT_BREAK_DURATION_SECONDS
    private var remainingSeconds = DEFAULT_DURATION_SECONDS
    private var deadlineEpochMilliseconds: Long? = null
    private var taskTitle: String? = null
    private var taskTag = "Focus"
    private var running = false
    private var lastWidgetMinute: Int? = null
    private var autoDndEnabled = false
    private var focusGuardEnabled = false
    private var blockedApps = emptySet<String>()
    private val dndManager by lazy { FocusDndManager(this) }
    private val focusGuardOverlay by lazy { FocusGuardOverlay(this) }

    private val timerTick = object : Runnable {
        override fun run() = tick()
    }

    private val focusGuardTick = object : Runnable {
        override fun run() {
            pollFocusGuard()
            if (isFocusRunning() && focusGuardEnabled && blockedApps.isNotEmpty()) {
                handler.postDelayed(this, FOCUS_GUARD_POLL_MS)
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannels(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_SYNC -> applyIntentSnapshot(intent)
            ACTION_PAUSE -> pauseTimer()
            ACTION_RESUME -> resumeTimer()
            ACTION_STOP -> resetTimer()
            ACTION_COMPLETION_ALARM -> handleCompletionAlarm(this)
            else -> restoreSavedSnapshot()
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        handler.removeCallbacks(timerTick)
        handler.removeCallbacks(focusGuardTick)
        focusGuardOverlay.hide()
        dndManager.restoreAfterFocus()
        super.onDestroy()
    }

    private fun applyIntentSnapshot(intent: Intent) {
        phase = intent.getStringExtra(EXTRA_PHASE) ?: PHASE_READY
        durationSeconds = intent.getIntExtra(
            EXTRA_DURATION_SECONDS,
            DEFAULT_DURATION_SECONDS,
        ).coerceIn(
            if (phase == PHASE_BREAK_RUNNING || phase == PHASE_BREAK_PAUSED) {
                MIN_BREAK_DURATION_SECONDS
            } else {
                MIN_DURATION_SECONDS
            },
            if (phase == PHASE_BREAK_RUNNING || phase == PHASE_BREAK_PAUSED) {
                MAX_BREAK_DURATION_SECONDS
            } else {
                MAX_DURATION_SECONDS
            },
        )
        focusDurationSeconds = intent.getIntExtra(
            EXTRA_FOCUS_DURATION_SECONDS,
            durationSeconds,
        ).coerceIn(MIN_DURATION_SECONDS, MAX_DURATION_SECONDS)
        breakDurationSeconds = intent.getIntExtra(
            EXTRA_BREAK_DURATION_SECONDS,
            DEFAULT_BREAK_DURATION_SECONDS,
        ).coerceIn(MIN_BREAK_DURATION_SECONDS, MAX_BREAK_DURATION_SECONDS)
        remainingSeconds = intent.getIntExtra(
            EXTRA_REMAINING_SECONDS,
            durationSeconds,
        ).coerceIn(0, durationSeconds)
        deadlineEpochMilliseconds = intent.getLongExtra(EXTRA_DEADLINE, 0L)
            .takeIf { it > 0L }
        taskTitle = intent.getStringExtra(EXTRA_TASK_TITLE)
        taskTag = intent.getStringExtra(EXTRA_TASK_TAG) ?: "Focus"
        autoDndEnabled = intent.getBooleanExtra(EXTRA_AUTO_DND, false)
        focusGuardEnabled = intent.getBooleanExtra(EXTRA_FOCUS_GUARD, false)
        blockedApps = intent.getStringArrayListExtra(EXTRA_BLOCKED_APPS)
            ?.filterNot(::isNeverBlockPackage)
            ?.toSet()
            .orEmpty()
        activateForCurrentState()
    }

    private fun restoreSavedSnapshot() {
        val snapshot = FocusWidgetStateStore.readSnapshot(this)
        if (snapshot == null) {
            stopService()
            return
        }
        phase = snapshot["phase"] as? String ?: PHASE_READY
        durationSeconds = (snapshot["durationSeconds"] as? Number)?.toInt()
            ?.coerceIn(
                if (phase == PHASE_BREAK_RUNNING || phase == PHASE_BREAK_PAUSED) {
                    MIN_BREAK_DURATION_SECONDS
                } else {
                    MIN_DURATION_SECONDS
                },
                if (phase == PHASE_BREAK_RUNNING || phase == PHASE_BREAK_PAUSED) {
                    MAX_BREAK_DURATION_SECONDS
                } else {
                    MAX_DURATION_SECONDS
                },
            )
            ?: DEFAULT_DURATION_SECONDS
        focusDurationSeconds = ((snapshot["focusDurationMinutes"] as? Number)?.toInt()
            ?.times(60) ?: durationSeconds)
            .coerceIn(MIN_DURATION_SECONDS, MAX_DURATION_SECONDS)
        breakDurationSeconds = (snapshot["breakDurationSeconds"] as? Number)?.toInt()
            ?.coerceIn(MIN_BREAK_DURATION_SECONDS, MAX_BREAK_DURATION_SECONDS)
            ?: DEFAULT_BREAK_DURATION_SECONDS
        remainingSeconds = (snapshot["remainingSeconds"] as? Number)?.toInt()
            ?.coerceIn(0, durationSeconds)
            ?: durationSeconds
        deadlineEpochMilliseconds = (snapshot["deadlineEpochMilliseconds"] as? Number)
            ?.toLong()
        taskTitle = snapshot["taskTitle"] as? String
        taskTag = snapshot["taskTag"] as? String ?: "Focus"
        autoDndEnabled = snapshot["autoDndEnabled"] as? Boolean ?: false
        focusGuardEnabled = snapshot["focusGuardEnabled"] as? Boolean ?: false
        blockedApps = (snapshot["blockedApps"] as? List<*>)
            ?.filterIsInstance<String>()
            ?.filterNot(::isNeverBlockPackage)
            ?.toSet()
            .orEmpty()
        activateForCurrentState()
    }

    private fun activateForCurrentState() {
        when (phase) {
            PHASE_RUNNING, PHASE_BREAK_RUNNING -> {
                if (deadlineEpochMilliseconds == null) {
                    deadlineEpochMilliseconds =
                        System.currentTimeMillis() + remainingSeconds * 1000L
                }
                remainingSeconds = remainingFromDeadline()
                running = true
                enterForeground()
                if (remainingSeconds <= 0) {
                    completeTimer()
                    return
                }
                applyFocusProtections()
                lastWidgetMinute = remainingSeconds / 60
                scheduleTick()
            }

            PHASE_PAUSED, PHASE_BREAK_PAUSED -> {
                running = false
                deadlineEpochMilliseconds = null
                handler.removeCallbacks(timerTick)
                stopFocusProtections()
                enterForeground()
            }

            else -> stopService()
        }
    }

    private fun pauseTimer() {
        if ((phase != PHASE_RUNNING && phase != PHASE_BREAK_RUNNING) || !running) return
        remainingSeconds = remainingFromDeadline()
        if (remainingSeconds <= 0) {
            completeTimer()
            return
        }
        phase = if (phase == PHASE_BREAK_RUNNING) PHASE_BREAK_PAUSED else PHASE_PAUSED
        running = false
        deadlineEpochMilliseconds = null
        handler.removeCallbacks(timerTick)
        stopFocusProtections()
        persistSnapshotAndNotifyApp()
        updateForegroundNotification()
    }

    private fun resumeTimer() {
        if ((phase != PHASE_PAUSED && phase != PHASE_BREAK_PAUSED) || remainingSeconds <= 0) return
        phase = if (phase == PHASE_BREAK_PAUSED) PHASE_BREAK_RUNNING else PHASE_RUNNING
        running = true
        deadlineEpochMilliseconds =
            System.currentTimeMillis() + remainingSeconds * 1000L
        lastWidgetMinute = remainingSeconds / 60
        persistSnapshotAndNotifyApp()
        enterForeground()
        applyFocusProtections()
        scheduleTick()
    }

    private fun resetTimer() {
        handler.removeCallbacks(timerTick)
        phase = PHASE_READY
        running = false
        durationSeconds = focusDurationSeconds
        remainingSeconds = focusDurationSeconds
        deadlineEpochMilliseconds = null
        stopFocusProtections()
        persistSnapshotAndNotifyApp()
        stopService()
    }

    private fun tick() {
        if (!running || (phase != PHASE_RUNNING && phase != PHASE_BREAK_RUNNING)) return
        remainingSeconds = remainingFromDeadline()
        if (remainingSeconds <= 0) {
            completeTimer()
            return
        }

        val minuteBucket = remainingSeconds / 60
        val minuteChanged = minuteBucket != lastWidgetMinute
        if (minuteChanged) {
            lastWidgetMinute = minuteBucket
            persistSnapshotAndNotifyApp()
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N || minuteChanged) {
            updateForegroundNotification()
        }
        scheduleTick()
    }

    private fun remainingFromDeadline(): Int {
        val deadline = deadlineEpochMilliseconds ?: return remainingSeconds
        val milliseconds = (deadline - System.currentTimeMillis()).coerceAtLeast(0L)
        return ((milliseconds + 999L) / 1000L).toInt()
    }

    private fun scheduleTick() {
        handler.removeCallbacks(timerTick)
        handler.postDelayed(timerTick, 1000L)
    }

    private fun applyFocusProtections() {
        if (isFocusRunning() && autoDndEnabled) dndManager.enableForFocus()
        else dndManager.restoreAfterFocus()

        handler.removeCallbacks(focusGuardTick)
        if (isFocusRunning() && focusGuardEnabled && blockedApps.isNotEmpty() &&
            hasUsageAccess() && Settings.canDrawOverlays(this)
        ) {
            handler.post(focusGuardTick)
        } else {
            focusGuardOverlay.hide()
        }
    }

    private fun stopFocusProtections() {
        handler.removeCallbacks(focusGuardTick)
        focusGuardOverlay.hide()
        dndManager.restoreAfterFocus()
    }

    private fun isFocusRunning(): Boolean = running && phase == PHASE_RUNNING

    private fun pollFocusGuard() {
        if (!isFocusRunning() || !focusGuardEnabled || blockedApps.isEmpty() ||
            !hasUsageAccess() || !Settings.canDrawOverlays(this)
        ) {
            focusGuardOverlay.hide()
            return
        }

        val foregroundPackage = foregroundPackageName()
        if (foregroundPackage != null &&
            foregroundPackage in blockedApps &&
            !isNeverBlockPackage(foregroundPackage)
        ) {
            focusGuardOverlay.show()
        } else {
            focusGuardOverlay.hide()
        }
    }

    private fun foregroundPackageName(): String? = runCatching {
        val manager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val end = System.currentTimeMillis()
        val events = manager.queryEvents(end - USAGE_QUERY_WINDOW_MS, end)
        val event = UsageEvents.Event()
        var lastForeground: String? = null
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND ||
                event.eventType == UsageEvents.Event.ACTIVITY_RESUMED
            ) {
                lastForeground = event.packageName
            }
        }
        lastForeground
    }.getOrNull()

    private fun hasUsageAccess(): Boolean = runCatching {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName,
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName,
            )
        }
        mode == AppOpsManager.MODE_ALLOWED
    }.getOrDefault(false)

    private fun isNeverBlockPackage(candidate: String): Boolean {
        val homeIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        val homePackage = packageManager.resolveActivity(
            homeIntent,
            android.content.pm.PackageManager.MATCH_DEFAULT_ONLY,
        )?.activityInfo?.packageName
        return candidate == packageName ||
            candidate == homePackage ||
            candidate == "com.android.settings" ||
            candidate == "com.android.permissioncontroller" ||
            candidate == "com.google.android.permissioncontroller" ||
            candidate.startsWith("com.android.systemui")
    }

    private fun completeTimer() {
        val completedDeadline = deadlineEpochMilliseconds
        val wasBreak = phase == PHASE_BREAK_RUNNING
        handler.removeCallbacks(timerTick)
        phase = if (wasBreak) PHASE_BREAK_COMPLETE else PHASE_COMPLETE
        durationSeconds = if (wasBreak) breakDurationSeconds else focusDurationSeconds
        running = false
        remainingSeconds = 0
        deadlineEpochMilliseconds = null
        stopFocusProtections()
        persistSnapshotAndNotifyApp()
        if (wasBreak) showBreakCompletionNotification(this, completedDeadline)
        else showCompletionNotification(this, completedDeadline)
        stopService()
    }

    private fun persistSnapshotAndNotifyApp() {
        FocusWidgetStateStore.writeSnapshot(this, snapshot())
        sendBroadcast(Intent(ACTION_TIMER_STATE_CHANGED).setPackage(packageName))
    }

    private fun snapshot(): Map<String, Any?> = mapOf(
        "phase" to phase,
        "durationSeconds" to durationSeconds,
        "focusDurationMinutes" to (focusDurationSeconds / 60),
        "breakDurationSeconds" to breakDurationSeconds,
        "remainingSeconds" to remainingSeconds,
        "deadlineEpochMilliseconds" to deadlineEpochMilliseconds,
        "taskTitle" to taskTitle,
        "taskTag" to taskTag,
        "autoDndEnabled" to autoDndEnabled,
        "focusGuardEnabled" to focusGuardEnabled,
        "blockedApps" to blockedApps.toList(),
    )

    private fun enterForeground() {
        ServiceCompat.startForeground(
            this,
            NOTIFICATION_ID,
            buildOngoingNotification(),
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            } else {
                0
            },
        )
    }

    private fun updateForegroundNotification() {
        notificationManager.notify(NOTIFICATION_ID, buildOngoingNotification())
    }

    private fun buildOngoingNotification(): Notification {
        val openApp = PendingIntent.getActivity(
            this,
            20,
            Intent(this, MainActivity::class.java).addFlags(
                Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP,
            ),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val toggleAction = if (running) ACTION_PAUSE else ACTION_RESUME
        val toggleLabel = if (running) "Pause" else "Resume"
        val toggleIcon = if (running) {
            android.R.drawable.ic_media_pause
        } else {
            android.R.drawable.ic_media_play
        }
        val toggle = servicePendingIntent(toggleAction, 21)
        val stop = servicePendingIntent(ACTION_STOP, 22)
        val status = when (phase) {
            PHASE_RUNNING -> "Focus in progress"
            PHASE_BREAK_RUNNING -> "Break in progress"
            PHASE_BREAK_PAUSED -> "Break paused"
            else -> "Focus paused"
        }
        val taskLine = if (phase == PHASE_RUNNING || phase == PHASE_PAUSED) {
            taskTitle?.takeIf { it.isNotBlank() }?.let { " · $it" }.orEmpty()
        } else {
            ""
        }
        val countdownChronometerEnabled =
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.N &&
                running &&
                deadlineEpochMilliseconds != null

        val notification = NotificationCompat.Builder(this, CHANNEL_TIMER)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle("$status$taskLine")
            .setContentText(
                if (countdownChronometerEnabled) {
                    if (phase == PHASE_BREAK_RUNNING) "Take a moment to rest" else "Stay focused"
                } else {
                    "${formatTime(remainingSeconds)} remaining"
                },
            )
            .setContentIntent(openApp)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .addAction(toggleIcon, toggleLabel, toggle)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Stop", stop)

        if (countdownChronometerEnabled) {
            notification
                .setWhen(deadlineEpochMilliseconds!!)
                .setShowWhen(true)
                .setUsesChronometer(true)
                .setChronometerCountDown(true)
        }

        return notification.build()
    }

    private fun servicePendingIntent(action: String, requestCode: Int): PendingIntent =
        PendingIntent.getService(
            this,
            requestCode,
            Intent(this, FocusTimerForegroundService::class.java).setAction(action),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    private fun stopService() {
        handler.removeCallbacks(timerTick)
        stopFocusProtections()
        running = false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    companion object {
        const val ACTION_TIMER_STATE_CHANGED = "com.appylab.syncfocus.TIMER_STATE_CHANGED"

        private const val ACTION_SYNC = "com.appylab.syncfocus.timer.SYNC"
        private const val ACTION_PAUSE = "com.appylab.syncfocus.timer.PAUSE"
        private const val ACTION_RESUME = "com.appylab.syncfocus.timer.RESUME"
        private const val ACTION_STOP = "com.appylab.syncfocus.timer.STOP"
        private const val ACTION_COMPLETION_ALARM = "com.appylab.syncfocus.timer.COMPLETION_ALARM"
        private const val CHANNEL_TIMER = "sync_focus_timer"
        private const val CHANNEL_COMPLETION = "sync_focus_completion"
        private const val NOTIFICATION_ID = 5101
        private const val COMPLETION_NOTIFICATION_ID = 5102
        private const val BREAK_COMPLETION_NOTIFICATION_ID = 5103
        private const val PREFS = "sync_focus_widget_timer"
        private const val KEY_LAST_NOTIFIED_DEADLINE = "last_notified_deadline_ms"
        private const val KEY_LAST_NOTIFIED_BREAK_DEADLINE = "last_notified_break_deadline_ms"
        private const val EXTRA_PHASE = "phase"
        private const val EXTRA_DURATION_SECONDS = "duration_seconds"
        private const val EXTRA_REMAINING_SECONDS = "remaining_seconds"
        private const val EXTRA_DEADLINE = "deadline_epoch_ms"
        private const val EXTRA_TASK_TITLE = "task_title"
        private const val EXTRA_TASK_TAG = "task_tag"
        private const val EXTRA_FOCUS_DURATION_SECONDS = "focus_duration_seconds"
        private const val EXTRA_BREAK_DURATION_SECONDS = "break_duration_seconds"
        private const val EXTRA_AUTO_DND = "auto_dnd_enabled"
        private const val EXTRA_FOCUS_GUARD = "focus_guard_enabled"
        private const val EXTRA_BLOCKED_APPS = "blocked_apps"
        private const val PHASE_READY = "ready"
        private const val PHASE_RUNNING = "running"
        private const val PHASE_PAUSED = "paused"
        private const val PHASE_COMPLETE = "complete"
        private const val PHASE_BREAK_RUNNING = "breakRunning"
        private const val PHASE_BREAK_PAUSED = "breakPaused"
        private const val PHASE_BREAK_COMPLETE = "breakComplete"
        private const val DEFAULT_DURATION_SECONDS = 25 * 60
        private const val DEFAULT_BREAK_DURATION_SECONDS = 5 * 60
        private const val MIN_DURATION_SECONDS = 5 * 60
        private const val MAX_DURATION_SECONDS = 240 * 60
        private const val MIN_BREAK_DURATION_SECONDS = 60
        private const val MAX_BREAK_DURATION_SECONDS = 60 * 60
        private const val FOCUS_GUARD_POLL_MS = 1000L
        private const val USAGE_QUERY_WINDOW_MS = 10_000L

        fun syncFromFlutter(
            context: Context,
            previous: Map<String, Any?>?,
            current: Map<String, Any?>,
            force: Boolean = false,
        ) {
            val newPhase = current["phase"] as? String ?: PHASE_READY
            val isRunningOrPaused = newPhase == PHASE_RUNNING ||
                newPhase == PHASE_PAUSED ||
                newPhase == PHASE_BREAK_RUNNING ||
                newPhase == PHASE_BREAK_PAUSED
            if (isRunningOrPaused) {
                val previousPhase = previous?.get("phase") as? String
                val previousDeadline = (previous?.get("deadlineEpochMilliseconds") as? Number)
                    ?.toLong()
                val currentDeadline = (current["deadlineEpochMilliseconds"] as? Number)?.toLong()
                val protectionSettingsChanged = previous?.get("autoDndEnabled") != current["autoDndEnabled"] ||
                    previous?.get("focusGuardEnabled") != current["focusGuardEnabled"] ||
                    previous?.get("blockedApps") != current["blockedApps"]
                if (force || previousPhase != newPhase || previousDeadline != currentDeadline ||
                    protectionSettingsChanged
                ) {
                    ContextCompat.startForegroundService(
                        context,
                        syncIntent(context, current),
                    )
                }
            } else {
                if (newPhase == PHASE_COMPLETE && previous?.get("phase") == PHASE_RUNNING) {
                    val completedDeadline =
                        (previous["deadlineEpochMilliseconds"] as? Number)?.toLong()
                    showCompletionNotification(context, completedDeadline)
                }
                if (newPhase == PHASE_BREAK_COMPLETE &&
                    previous?.get("phase") == PHASE_BREAK_RUNNING
                ) {
                    val completedDeadline =
                        (previous["deadlineEpochMilliseconds"] as? Number)?.toLong()
                    showBreakCompletionNotification(context, completedDeadline)
                }
                FocusDndManager(context).restoreAfterFocus()
                context.stopService(Intent(context, FocusTimerForegroundService::class.java))
            }
        }

        private fun syncIntent(context: Context, snapshot: Map<String, Any?>) =
            Intent(context, FocusTimerForegroundService::class.java).apply {
                action = ACTION_SYNC
                putExtra(EXTRA_PHASE, snapshot["phase"] as? String ?: PHASE_READY)
                putExtra(
                    EXTRA_DURATION_SECONDS,
                    (snapshot["durationSeconds"] as? Number)?.toInt() ?: DEFAULT_DURATION_SECONDS,
                )
                putExtra(
                    EXTRA_FOCUS_DURATION_SECONDS,
                    (((snapshot["focusDurationMinutes"] as? Number)?.toInt()
                        ?: DEFAULT_DURATION_SECONDS / 60) * 60),
                )
                putExtra(
                    EXTRA_BREAK_DURATION_SECONDS,
                    (snapshot["breakDurationSeconds"] as? Number)?.toInt()
                        ?: DEFAULT_BREAK_DURATION_SECONDS,
                )
                putExtra(
                    EXTRA_REMAINING_SECONDS,
                    (snapshot["remainingSeconds"] as? Number)?.toInt() ?: DEFAULT_DURATION_SECONDS,
                )
                putExtra(
                    EXTRA_DEADLINE,
                    (snapshot["deadlineEpochMilliseconds"] as? Number)?.toLong() ?: 0L,
                )
                putExtra(EXTRA_TASK_TITLE, snapshot["taskTitle"] as? String)
                putExtra(EXTRA_TASK_TAG, snapshot["taskTag"] as? String ?: "Focus")
                putExtra(EXTRA_AUTO_DND, snapshot["autoDndEnabled"] as? Boolean ?: false)
                putExtra(EXTRA_FOCUS_GUARD, snapshot["focusGuardEnabled"] as? Boolean ?: false)
                putStringArrayListExtra(
                    EXTRA_BLOCKED_APPS,
                    ArrayList((snapshot["blockedApps"] as? List<*>)
                        ?.filterIsInstance<String>()
                        .orEmpty()),
                )
            }

        fun restoreAfterBoot(context: Context) {
            val snapshot = FocusWidgetStateStore.readSnapshot(context) ?: return
            val phase = snapshot["phase"] as? String ?: return
            // Paused timers do not need a foreground service after boot. Starting one
            // from BOOT_COMPLETED can be rejected by Android's background-start rules.
            if (phase != PHASE_RUNNING && phase != PHASE_BREAK_RUNNING) return

            val deadline = (snapshot["deadlineEpochMilliseconds"] as? Number)?.toLong()
            if (deadline != null && deadline <= System.currentTimeMillis()) {
                completeStoredSnapshot(context, snapshot)
                return
            }

            ContextCompat.startForegroundService(context, syncIntent(context, snapshot))
        }

        fun handleCompletionAlarm(context: Context) {
            val snapshot = FocusWidgetStateStore.readSnapshot(context) ?: return
            val phase = snapshot["phase"] as? String
            val deadline = (snapshot["deadlineEpochMilliseconds"] as? Number)?.toLong()
            if ((phase != PHASE_RUNNING && phase != PHASE_BREAK_RUNNING) ||
                deadline == null || deadline > System.currentTimeMillis()
            ) {
                return
            }
            completeStoredSnapshot(context, snapshot)
        }

        private fun completeStoredSnapshot(context: Context, old: Map<String, Any?>) {
            val completedDeadline = (old["deadlineEpochMilliseconds"] as? Number)?.toLong()
            val wasBreak = old["phase"] == PHASE_BREAK_RUNNING
            val completed = old.toMutableMap().apply {
                this["phase"] = if (wasBreak) PHASE_BREAK_COMPLETE else PHASE_COMPLETE
                this["remainingSeconds"] = 0
                this["deadlineEpochMilliseconds"] = null
            }
            FocusWidgetStateStore.writeSnapshot(context, completed)
            if (wasBreak) showBreakCompletionNotification(context, completedDeadline)
            else showCompletionNotification(context, completedDeadline)
            FocusDndManager(context).restoreAfterFocus()
            context.stopService(Intent(context, FocusTimerForegroundService::class.java))
        }

        private fun showCompletionNotification(context: Context, completedDeadline: Long?) {
            createNotificationChannels(context)
            if (completedDeadline != null) {
                val preferences = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                val lastNotified = preferences.getLong(KEY_LAST_NOTIFIED_DEADLINE, 0L)
                if (lastNotified == completedDeadline) return
                // Save before posting so a simultaneous Flutter/native completion cannot
                // create a second notification for the same timer deadline.
                preferences.edit()
                    .putLong(KEY_LAST_NOTIFIED_DEADLINE, completedDeadline)
                    .commit()
            }

            val openApp = PendingIntent.getActivity(
                context,
                23,
                Intent(context, MainActivity::class.java).addFlags(
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP,
                ),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            val notification = NotificationCompat.Builder(context, CHANNEL_COMPLETION)
                .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
                .setContentTitle("Focus session complete")
                .setContentText("Your focus timer has finished.")
                .setContentIntent(openApp)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setAutoCancel(true)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .build()
            context.getSystemService(NotificationManager::class.java)
                .notify(COMPLETION_NOTIFICATION_ID, notification)
        }

        private fun showBreakCompletionNotification(context: Context, completedDeadline: Long?) {
            createNotificationChannels(context)
            if (completedDeadline != null) {
                val preferences = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                val lastNotified = preferences.getLong(KEY_LAST_NOTIFIED_BREAK_DEADLINE, 0L)
                if (lastNotified == completedDeadline) return
                preferences.edit()
                    .putLong(KEY_LAST_NOTIFIED_BREAK_DEADLINE, completedDeadline)
                    .commit()
            }

            val openApp = PendingIntent.getActivity(
                context,
                24,
                Intent(context, MainActivity::class.java).addFlags(
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP,
                ),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            val notification = NotificationCompat.Builder(context, CHANNEL_COMPLETION)
                .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
                .setContentTitle("Break complete")
                .setContentText("Ready to start another focus session?")
                .setContentIntent(openApp)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setAutoCancel(true)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .build()
            context.getSystemService(NotificationManager::class.java)
                .notify(BREAK_COMPLETION_NOTIFICATION_ID, notification)
        }

        private fun createNotificationChannels(context: Context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
            val manager = context.getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(
                NotificationChannel(CHANNEL_TIMER, "Focus timer", NotificationManager.IMPORTANCE_LOW),
            )
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_COMPLETION,
                    "Timer complete",
                    NotificationManager.IMPORTANCE_DEFAULT,
                ),
            )
        }

        private fun formatTime(totalSeconds: Int): String {
            val seconds = max(0, totalSeconds)
            val hours = seconds / 3600
            val minutes = seconds % 3600 / 60
            val remainder = seconds % 60
            return if (hours > 0) {
                "%d:%02d:%02d".format(hours, minutes, remainder)
            } else {
                "%02d:%02d".format(minutes, remainder)
            }
        }
    }
}
