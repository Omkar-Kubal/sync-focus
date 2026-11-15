package com.focusfirst.widget

import android.app.PendingIntent
import android.app.AlarmManager
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RadialGradient
import android.graphics.RectF
import android.graphics.Shader
import android.os.Build
import android.os.SystemClock
import android.widget.RemoteViews
import com.focusfirst.MainActivity
import com.focusfirst.R
import kotlin.math.ceil
import kotlin.math.cos
import kotlin.math.roundToInt
import kotlin.math.sin

private const val SNAPSHOT_PREFS = "sync_focus_widget_timer"
private const val SNAPSHOT_EXISTS = "snapshot_exists"
private const val PHASE = "phase"
private const val DURATION_SECONDS = "duration_seconds"
private const val REMAINING_SECONDS = "remaining_seconds"
private const val DEADLINE_EPOCH_MS = "deadline_epoch_ms"
private const val TASK_TITLE = "task_title"
private const val TASK_TAG = "task_tag"
private const val FOCUS_DURATION_MINUTES = "focus_duration_minutes"
private const val BREAK_DURATION_SECONDS = "break_duration_seconds"
private const val AUTO_DND_ENABLED = "auto_dnd_enabled"
private const val FOCUS_GUARD_ENABLED = "focus_guard_enabled"
private const val BLOCKED_APPS = "blocked_apps"
private const val AMBIENT_SOUND = "ambient_sound"
private const val PENDING_ACTION = "pending_action"
private const val ACTION_REFRESH_COMPLETED_TIMER = "com.focusfirst.widget.REFRESH_COMPLETED"

/** Small, dedicated storage shared by the launcher widgets and Flutter. */
object FocusWidgetStateStore {
    private fun preferences(context: Context) =
        context.getSharedPreferences(SNAPSHOT_PREFS, Context.MODE_PRIVATE)

    fun readSnapshot(context: Context): Map<String, Any?>? {
        val prefs = preferences(context)
        if (!prefs.getBoolean(SNAPSHOT_EXISTS, false)) return null
        return mapOf(
            "phase" to prefs.getString(PHASE, "ready"),
            "durationSeconds" to prefs.getInt(DURATION_SECONDS, 25 * 60),
            "remainingSeconds" to prefs.getInt(REMAINING_SECONDS, 25 * 60),
            "deadlineEpochMilliseconds" to if (prefs.contains(DEADLINE_EPOCH_MS)) {
                prefs.getLong(DEADLINE_EPOCH_MS, 0L)
            } else {
                null
            },
            "taskTitle" to prefs.getString(TASK_TITLE, null),
            "taskTag" to prefs.getString(TASK_TAG, "Focus"),
            "focusDurationMinutes" to prefs.getInt(
                FOCUS_DURATION_MINUTES,
                prefs.getInt(DURATION_SECONDS, 25 * 60) / 60,
            ),
            "breakDurationSeconds" to prefs.getInt(BREAK_DURATION_SECONDS, 5 * 60),
            "autoDndEnabled" to prefs.getBoolean(AUTO_DND_ENABLED, false),
            "focusGuardEnabled" to prefs.getBoolean(FOCUS_GUARD_ENABLED, false),
            "blockedApps" to prefs.getStringSet(BLOCKED_APPS, emptySet())?.toList().orEmpty(),
            "ambientSound" to prefs.getString(AMBIENT_SOUND, "rain"),
        )
    }

    fun writeSnapshot(context: Context, snapshot: Map<*, *>) {
        val editor = preferences(context).edit()
            .putBoolean(SNAPSHOT_EXISTS, true)
            .putString(PHASE, snapshot["phase"] as? String ?: "ready")
            .putInt(DURATION_SECONDS, (snapshot["durationSeconds"] as? Number)?.toInt() ?: 25 * 60)
            .putInt(REMAINING_SECONDS, (snapshot["remainingSeconds"] as? Number)?.toInt() ?: 25 * 60)
            .putString(TASK_TAG, snapshot["taskTag"] as? String ?: "Focus")
            .putInt(
                FOCUS_DURATION_MINUTES,
                (snapshot["focusDurationMinutes"] as? Number)?.toInt()
                    ?: ((snapshot["durationSeconds"] as? Number)?.toInt() ?: 25 * 60) / 60,
            )
            .putInt(BREAK_DURATION_SECONDS, (snapshot["breakDurationSeconds"] as? Number)?.toInt() ?: 5 * 60)
            .putBoolean(AUTO_DND_ENABLED, snapshot["autoDndEnabled"] as? Boolean ?: false)
            .putBoolean(FOCUS_GUARD_ENABLED, snapshot["focusGuardEnabled"] as? Boolean ?: false)
            .putString(
                AMBIENT_SOUND,
                snapshot["ambientSound"] as? String
                    ?: preferences(context).getString(AMBIENT_SOUND, "rain"),
            )

        val blockedApps = (snapshot["blockedApps"] as? List<*>)
            ?.filterIsInstance<String>()
            ?.filterNot { it == context.packageName || it.startsWith("com.android.settings") }
            ?.toSet()
            ?: emptySet()
        editor.putStringSet(BLOCKED_APPS, blockedApps)

        val deadline = (snapshot["deadlineEpochMilliseconds"] as? Number)?.toLong()
        if (deadline == null) editor.remove(DEADLINE_EPOCH_MS)
        else editor.putLong(DEADLINE_EPOCH_MS, deadline)

        val taskTitle = snapshot["taskTitle"] as? String
        if (taskTitle == null) editor.remove(TASK_TITLE)
        else editor.putString(TASK_TITLE, taskTitle)

        editor.apply()
        ensureCompletionRefresh(context)
        updateAllWidgets(context)
    }

    fun stageAction(context: Context, action: String): Boolean {
        preferences(context).edit().putString(PENDING_ACTION, action).apply()
        return true
    }

    fun consumePendingAction(context: Context): String? {
        val prefs = preferences(context)
        val action = prefs.getString(PENDING_ACTION, null)
        prefs.edit().remove(PENDING_ACTION).apply()
        return action
    }

    fun updateAllWidgets(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val square = ComponentName(context, FocusSquareWidgetProvider::class.java)
        val wide = ComponentName(context, FocusWideWidgetProvider::class.java)
        manager.getAppWidgetIds(square).takeIf { it.isNotEmpty() }?.let {
            FocusSquareWidgetProvider().onUpdate(context, manager, it)
        }
        manager.getAppWidgetIds(wide).takeIf { it.isNotEmpty() }?.let {
            FocusWideWidgetProvider().onUpdate(context, manager, it)
        }
    }

    fun ensureCompletionRefresh(context: Context) {
        val prefs = preferences(context)
        val phase = prefs.getString(PHASE, "ready")
        val deadline = if (prefs.contains(DEADLINE_EPOCH_MS)) {
            prefs.getLong(DEADLINE_EPOCH_MS, 0L)
        } else {
            null
        }
        if ((phase == "running" || phase == "breakRunning") &&
            deadline != null && hasWidgets(context)
        ) {
            scheduleCompletionRefresh(context, deadline)
        } else {
            cancelCompletionRefresh(context)
        }
    }

    private fun scheduleCompletionRefresh(context: Context, deadlineEpochMilliseconds: Long) {
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = completionPendingIntent(context)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarms.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                deadlineEpochMilliseconds,
                pendingIntent,
            )
        } else {
            alarms.set(AlarmManager.RTC_WAKEUP, deadlineEpochMilliseconds, pendingIntent)
        }
    }

    private fun cancelCompletionRefresh(context: Context) {
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarms.cancel(completionPendingIntent(context))
    }

    private fun completionPendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, FocusWidgetCompletionReceiver::class.java).apply {
            action = ACTION_REFRESH_COMPLETED_TIMER
        }
        return PendingIntent.getBroadcast(
            context,
            20,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun hasWidgets(context: Context): Boolean {
        val manager = AppWidgetManager.getInstance(context)
        return manager.getAppWidgetIds(
            ComponentName(context, FocusSquareWidgetProvider::class.java),
        ).isNotEmpty() || manager.getAppWidgetIds(
            ComponentName(context, FocusWideWidgetProvider::class.java),
        ).isNotEmpty()
    }
}

class FocusWidgetCompletionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        FocusWidgetStateStore.updateAllWidgets(context)
    }
}

class FocusSquareWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        FocusWidgetStateStore.ensureCompletionRefresh(context)
        val views = FocusWidgetRenderer.render(context, square = true)
        appWidgetIds.forEach { appWidgetManager.updateAppWidget(it, views) }
    }
}

class FocusWideWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        FocusWidgetStateStore.ensureCompletionRefresh(context)
        val views = FocusWidgetRenderer.render(context, square = false)
        appWidgetIds.forEach { appWidgetManager.updateAppWidget(it, views) }
    }
}

private object FocusWidgetRenderer {
    private data class TimerUi(
        val phase: String,
        val durationSeconds: Int,
        val remainingSeconds: Int,
        val deadlineEpochMilliseconds: Long?,
    ) {
        val running: Boolean get() =
            (phase == "running" || phase == "breakRunning") && remainingSeconds > 0

        val progressFraction: Float
            get() = if (phase == "ready") {
                durationFraction(durationSeconds / 60)
            } else {
                (remainingSeconds.toFloat() / durationSeconds.coerceAtLeast(1))
                    .coerceIn(0f, 1f)
            }

        val phaseLabel: String
            get() = when (phase) {
                "running" -> "FOCUSING"
                "paused" -> "PAUSED"
                "complete" -> "SESSION COMPLETE"
                "breakRunning" -> "BREAK TIME"
                "breakPaused" -> "BREAK PAUSED"
                "breakComplete" -> "BREAK COMPLETE"
                else -> "FOCUS READY"
            }

        val actionLabel: String
            get() = when (phase) {
                "running" -> "Pause"
                "paused" -> "Resume"
                "breakRunning" -> "Pause"
                "breakPaused" -> "Resume"
                else -> "Focus"
            }
    }

    fun render(context: Context, square: Boolean): RemoteViews {
        val layout = if (square) R.layout.widget_focus_square else R.layout.widget_focus_wide
        val views = RemoteViews(context.packageName, layout)
        val state = readTimerUi(context)

        views.setTextViewText(R.id.widget_status, state.phaseLabel)
        views.setTextViewText(R.id.widget_action_label, state.actionLabel)
        views.setContentDescription(R.id.widget_action, "${state.actionLabel} focus timer")
        views.setImageViewResource(
            R.id.widget_action_icon,
            if (state.running) R.drawable.widget_focus_pause_icon
            else R.drawable.widget_focus_play_icon,
        )
        if (square) {
            views.setImageViewBitmap(
                R.id.widget_ring,
                createRingBitmap(context, state.progressFraction),
            )
        } else {
            views.setProgressBar(
                R.id.widget_progress,
                100,
                (state.progressFraction * 100).roundToInt(),
                false,
            )
        }

        setTimerReadout(views, state)
        views.setOnClickPendingIntent(
            R.id.widget_root,
            appIntent(context, MainActivity.ACTION_WIDGET_OPEN, 10),
        )
        views.setOnClickPendingIntent(
            R.id.widget_action,
            appIntent(context, MainActivity.ACTION_WIDGET_TOGGLE, 11),
        )
        return views
    }

    private fun readTimerUi(context: Context): TimerUi {
        val prefs = context.getSharedPreferences(SNAPSHOT_PREFS, Context.MODE_PRIVATE)
        val durationSeconds = prefs.getInt(DURATION_SECONDS, 25 * 60).coerceAtLeast(1)
        val phase = prefs.getString(PHASE, "ready") ?: "ready"
        var remaining = prefs.getInt(REMAINING_SECONDS, durationSeconds).coerceAtLeast(0)
        val deadline = if (prefs.contains(DEADLINE_EPOCH_MS)) {
            prefs.getLong(DEADLINE_EPOCH_MS, 0L)
        } else {
            null
        }
        if ((phase == "running" || phase == "breakRunning") && deadline != null) {
            remaining = ceil((deadline - System.currentTimeMillis()).coerceAtLeast(0L) / 1000.0).toInt()
        }
        return TimerUi(
            phase = if (phase == "running" && remaining == 0) {
                "complete"
            } else if (phase == "breakRunning" && remaining == 0) {
                "breakComplete"
            } else {
                phase
            },
            durationSeconds = durationSeconds,
            remainingSeconds = remaining,
            deadlineEpochMilliseconds = deadline,
        )
    }

    private fun setTimerReadout(views: RemoteViews, state: TimerUi) {
        val timeText = if (state.phase == "complete" || state.phase == "breakComplete") {
            "00:00"
        } else {
            formatTime(state.remainingSeconds)
        }
        if (state.running && Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val remaining = state.deadlineEpochMilliseconds?.let {
                ceil((it - System.currentTimeMillis()).coerceAtLeast(0L) / 1000.0).toLong()
            } ?: state.remainingSeconds.toLong()
            val base = SystemClock.elapsedRealtime() + remaining * 1000L
            views.setChronometerCountDown(R.id.widget_chronometer, true)
            views.setChronometer(R.id.widget_chronometer, base, "%s", true)
            views.setViewVisibility(R.id.widget_time, android.view.View.GONE)
            views.setViewVisibility(R.id.widget_chronometer, android.view.View.VISIBLE)
        } else {
            views.setTextViewText(R.id.widget_time, timeText)
            views.setViewVisibility(R.id.widget_time, android.view.View.VISIBLE)
            views.setViewVisibility(R.id.widget_chronometer, android.view.View.GONE)
        }
    }

    private fun appIntent(context: Context, action: String, requestCode: Int): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            this.action = action
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun createRingBitmap(context: Context, fraction: Float): Bitmap {
        val density = context.resources.displayMetrics.density
        val size = (78f * density).roundToInt().coerceAtLeast(1)
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val stroke = 4f * density
        val inset = stroke / 2f + density
        val bounds = RectF(inset, inset, size - inset, size - inset)
        val center = size / 2f
        val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = RadialGradient(
                center,
                center,
                size * 0.42f,
                intArrayOf(0xFFEAF5FF.toInt(), 0x00FFFFFF),
                null,
                Shader.TileMode.CLAMP,
            )
        }
        canvas.drawCircle(center, center, size * 0.42f, fillPaint)
        val trackPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = 0xFFDCEBFA.toInt()
            style = Paint.Style.STROKE
            strokeWidth = stroke
            strokeCap = Paint.Cap.ROUND
        }
        val progressPaint = Paint(trackPaint).apply { color = 0xFF70A9F7.toInt() }
        canvas.drawArc(bounds, -90f, 360f, false, trackPaint)
        val sweep = fraction.coerceIn(0f, 1f) * 360f
        if (sweep > 0f) {
            canvas.drawArc(bounds, -90f, sweep, false, progressPaint)
            val angle = Math.toRadians((-90f + sweep).toDouble())
            val centerX = bounds.centerX() + bounds.width() / 2f * cos(angle).toFloat()
            val centerY = bounds.centerY() + bounds.height() / 2f * sin(angle).toFloat()
            canvas.drawCircle(centerX, centerY, stroke * 0.9f, progressPaint)
        }
        return bitmap
    }

    private fun durationFraction(minutes: Int): Float = when {
        minutes <= 25 -> 0.25f * (minutes - 5).coerceAtLeast(0) / 20f
        minutes <= 60 -> 0.25f + 0.35f * (minutes - 25) / 35f
        else -> 0.60f + 0.40f * (minutes - 60) / 180f
    }.coerceIn(0f, 1f)

    private fun formatTime(seconds: Int): String {
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
