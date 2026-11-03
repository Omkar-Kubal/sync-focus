package com.appylab.syncfocus.receiver

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.appylab.syncfocus.service.FocusTimerForegroundService

/** Restores a running or paused focus timer after Android finishes booting. */
class FocusTimerBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        FocusTimerForegroundService.restoreAfterBoot(context)
    }
}
