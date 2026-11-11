package com.example.task_chat

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import android.view.Display
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.example.task_chat/display_mode"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
        enableHighRefreshRate()
    }

    override fun onResume() {
        super.onResume()
        enableHighRefreshRate()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "high_importance_channel"
            val channelName = "High Importance Notifications"
            val channelDescription = "This channel is used for important Fitmate notifications."
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(channelId, channelName, importance).apply {
                description = channelDescription
                enableLights(true)
                enableVibration(true)
                setShowBadge(true)
            }
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager?.createNotificationChannel(channel)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            if (call.method == "enableHighRefreshRate") {
                val maxRate = enableHighRefreshRate()
                result.success(maxRate.toDouble())
            } else {
                result.notImplemented()
            }
        }
    }

    private fun enableHighRefreshRate(): Float {
        var highestRate = 60f
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val currentDisplay = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                display
            } else {
                @Suppress("DEPRECATION")
                windowManager.defaultDisplay
            }

            val modes: Array<Display.Mode> = currentDisplay?.supportedModes ?: emptyArray()
            var bestModeId = 0

            for (mode in modes) {
                if (mode.refreshRate > highestRate) {
                    highestRate = mode.refreshRate
                    bestModeId = mode.modeId
                }
            }

            if (bestModeId != 0) {
                val params = window.attributes
                params.preferredDisplayModeId = bestModeId

                // On Android 14+ (API 34), also set preferred min/max display refresh rate via reflection
                if (Build.VERSION.SDK_INT >= 34) {
                    try {
                        val minField = params.javaClass.getField("preferredMinDisplayRefreshRate")
                        minField.setFloat(params, highestRate)
                        val maxField = params.javaClass.getField("preferredMaxDisplayRefreshRate")
                        maxField.setFloat(params, highestRate)
                    } catch (_: Exception) {}
                }

                window.attributes = params
            }
        }
        return highestRate
    }
}
