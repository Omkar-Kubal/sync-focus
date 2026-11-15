package com.focusfirst.service

import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.provider.Settings
import android.view.Gravity
import android.view.WindowManager
import android.widget.Button
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import com.focusfirst.MainActivity

/** Full-screen, touchable overlay shown over an app selected in Focus Guard. */
internal class FocusGuardOverlay(private val context: Context) {
    private val windowManager =
        context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private var root: FrameLayout? = null

    fun show() {
        if (root != null || !Settings.canDrawOverlays(context)) return

        val overlay = FrameLayout(context).apply {
            setBackgroundColor(0xED101216.toInt())
            isClickable = true
            isFocusable = false
        }
        val content = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(28), dp(24), dp(28), dp(24))
        }
        val mark = TextView(context).apply {
            text = "✦"
            textSize = 46f
            gravity = Gravity.CENTER
            setTextColor(0xFF83B7FF.toInt())
        }
        val title = TextView(context).apply {
            text = "Stay with your focus"
            textSize = 24f
            typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
            gravity = Gravity.CENTER
            setTextColor(0xFFFFFFFF.toInt())
            setPadding(0, dp(20), 0, dp(8))
        }
        val message = TextView(context).apply {
            text = "This app is paused until your focus session ends."
            textSize = 16f
            gravity = Gravity.CENTER
            setTextColor(0xFFB8BDC5.toInt())
        }
        val returnButton = Button(context).apply {
            text = "Return to focus"
            setOnClickListener {
                hide()
                context.startActivity(
                    Intent(context, MainActivity::class.java).addFlags(
                        Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_CLEAR_TOP or
                            Intent.FLAG_ACTIVITY_SINGLE_TOP,
                    ),
                )
            }
        }
        content.addView(mark, LinearLayout.LayoutParams(-1, -2))
        content.addView(title, LinearLayout.LayoutParams(-1, -2))
        content.addView(message, LinearLayout.LayoutParams(-1, -2))
        content.addView(returnButton, LinearLayout.LayoutParams(-1, -2).apply {
            topMargin = dp(24)
        })
        overlay.addView(
            content,
            FrameLayout.LayoutParams(-1, -2, Gravity.CENTER),
        )

        val windowType = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            windowType,
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.START
        }

        try {
            windowManager.addView(overlay, params)
            root = overlay
        } catch (_: Exception) {
            root = null
        }
    }

    fun hide() {
        val current = root ?: return
        root = null
        runCatching { windowManager.removeView(current) }
    }

    private fun dp(value: Int): Int =
        (value * context.resources.displayMetrics.density).toInt()
}
