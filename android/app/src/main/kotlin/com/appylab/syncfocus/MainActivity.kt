package com.appylab.syncfocus

import android.Manifest
import android.app.AppOpsManager
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import java.io.ByteArrayOutputStream
import androidx.core.content.ContextCompat
import com.appylab.syncfocus.service.FocusTimerForegroundService
import com.appylab.syncfocus.widget.FocusWidgetStateStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var widgetChannel: MethodChannel? = null
    private var pendingForegroundSnapshot: Map<String, Any?>? = null
    private var timerStateReceiverRegistered = false

    private val timerStateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            widgetChannel?.invokeMethod(
                "timerSnapshotChanged",
                FocusWidgetStateStore.readSnapshot(this@MainActivity),
            )
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ContextCompat.registerReceiver(
            this,
            timerStateReceiver,
            IntentFilter(FocusTimerForegroundService.ACTION_TIMER_STATE_CHANGED),
            ContextCompat.RECEIVER_NOT_EXPORTED,
        )
        timerStateReceiverRegistered = true
        stageWidgetAction(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        widgetChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            WIDGET_CHANNEL,
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "getTimerSnapshot" -> result.success(
                        FocusWidgetStateStore.readSnapshot(this),
                    )

                    "updateTimerSnapshot" -> {
                        val snapshot = call.arguments as? Map<*, *>
                        if (snapshot == null) {
                            result.error("invalid_snapshot", "Timer snapshot is missing", null)
                        } else {
                            val normalizedSnapshot = snapshot.entries.mapNotNull { (key, value) ->
                                (key as? String)?.let { it to value }
                            }.toMap()
                            val previousSnapshot = FocusWidgetStateStore.readSnapshot(this)
                            FocusWidgetStateStore.writeSnapshot(this, snapshot)
                            if (shouldRequestNotificationPermission(normalizedSnapshot)) {
                                pendingForegroundSnapshot = normalizedSnapshot
                                getSharedPreferences(PREFERENCES, MODE_PRIVATE).edit()
                                    .putBoolean(KEY_NOTIFICATION_PERMISSION_REQUESTED, true)
                                    .apply()
                                requestPermissions(
                                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                                    REQUEST_NOTIFICATION_PERMISSION,
                                )
                            } else {
                                FocusTimerForegroundService.syncFromFlutter(
                                    this,
                                    previousSnapshot,
                                    normalizedSnapshot,
                                )
                            }
                            result.success(null)
                        }
                    }

                    "consumePendingAction" -> result.success(
                        FocusWidgetStateStore.consumePendingAction(this),
                    )

                    else -> result.notImplemented()
                }
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SETTINGS_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasDndAccess" -> result.success(
                    getSystemService(NotificationManager::class.java)
                        .isNotificationPolicyAccessGranted,
                )

                "requestDndAccess" -> {
                    startActivity(Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS))
                    result.success(null)
                }

                "getFocusGuardAccess" -> result.success(
                    mapOf(
                        "usageAccess" to hasUsageAccess(),
                        "overlayAccess" to Settings.canDrawOverlays(this),
                    ),
                )

                "requestUsageAccess" -> {
                    startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                    result.success(null)
                }

                "requestOverlayAccess" -> {
                    startActivity(
                        Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName"),
                        ),
                    )
                    result.success(null)
                }

                "getLaunchableApps" -> result.success(loadLaunchableApps())
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (stageWidgetAction(intent)) {
            widgetChannel?.invokeMethod("widgetActionPending", null)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != REQUEST_NOTIFICATION_PERMISSION) return

        pendingForegroundSnapshot?.let { snapshot ->
            FocusTimerForegroundService.syncFromFlutter(
                this,
                null,
                snapshot,
                force = true,
            )
        }
        pendingForegroundSnapshot = null
    }

    override fun onDestroy() {
        if (timerStateReceiverRegistered) {
            unregisterReceiver(timerStateReceiver)
            timerStateReceiverRegistered = false
        }
        super.onDestroy()
    }

    private fun shouldRequestNotificationPermission(snapshot: Map<String, Any?>): Boolean {
        if ((snapshot["phase"] != "running" && snapshot["phase"] != "breakRunning") ||
            Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU
        ) {
            return false
        }
        if (ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.POST_NOTIFICATIONS,
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            return false
        }
        return !getSharedPreferences(PREFERENCES, MODE_PRIVATE)
            .getBoolean(KEY_NOTIFICATION_PERMISSION_REQUESTED, false)
    }

    private fun hasUsageAccess(): Boolean = runCatching {
        val appOps = getSystemService(APP_OPS_SERVICE) as AppOpsManager
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

    @Suppress("DEPRECATION")
    private fun loadLaunchableApps(): List<Map<String, Any?>> {
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val homeIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        val homePackage = packageManager.resolveActivity(
            homeIntent,
            PackageManager.MATCH_DEFAULT_ONLY,
        )?.activityInfo?.packageName
        return packageManager.queryIntentActivities(intent, 0)
            .asSequence()
            .filterNot {
                it.activityInfo.packageName == packageName ||
                    it.activityInfo.packageName == homePackage ||
                    it.activityInfo.packageName == "com.android.settings" ||
                    it.activityInfo.packageName == "com.android.permissioncontroller" ||
                    it.activityInfo.packageName == "com.google.android.permissioncontroller"
            }
            .distinctBy { it.activityInfo.packageName }
            .map { resolveInfo ->
                mapOf(
                    "packageName" to resolveInfo.activityInfo.packageName,
                    "label" to resolveInfo.loadLabel(packageManager).toString(),
                    "icon" to runCatching {
                        drawablePng(resolveInfo.loadIcon(packageManager))
                    }.getOrNull(),
                )
            }
            .sortedBy { it["label"].toString().lowercase() }
            .toList()
    }

    private fun drawablePng(drawable: Drawable): ByteArray {
        val width = drawable.intrinsicWidth.coerceIn(1, 96)
        val height = drawable.intrinsicHeight.coerceIn(1, 96)
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, width, height)
        drawable.draw(canvas)
        val output = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, output)
        bitmap.recycle()
        return output.toByteArray()
    }

    private fun stageWidgetAction(intent: Intent?): Boolean {
        return when (intent?.action) {
            ACTION_WIDGET_TOGGLE -> FocusWidgetStateStore.stageAction(this, "toggle")
            ACTION_WIDGET_OPEN -> FocusWidgetStateStore.stageAction(this, "open")
            else -> false
        }
    }

    companion object {
        const val WIDGET_CHANNEL = "com.appylab.syncfocus/widgets"
        const val SETTINGS_CHANNEL = "com.appylab.syncfocus/settings"
        const val ACTION_WIDGET_OPEN = "com.appylab.syncfocus.widget.OPEN"
        const val ACTION_WIDGET_TOGGLE = "com.appylab.syncfocus.widget.TOGGLE"

        private const val PREFERENCES = "sync_focus_widget_timer"
        private const val KEY_NOTIFICATION_PERMISSION_REQUESTED = "notification_permission_requested"
        private const val REQUEST_NOTIFICATION_PERMISSION = 7351
    }
}
