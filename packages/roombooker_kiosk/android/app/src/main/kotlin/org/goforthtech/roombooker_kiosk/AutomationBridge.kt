package org.goforthtech.roombooker_kiosk

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodChannel

/**
 * Singleton bridge to handle communication between the background AccessibilityService
 * and the foreground Flutter UI.
 */
object AutomationBridge {
    private var channel: MethodChannel? = null
    private val handler = Handler(Looper.getMainLooper())
    var isServiceRunning = false
    var isAuthorized = false

    fun setChannel(newChannel: MethodChannel) {
        channel = newChannel
    }

    fun sendLog(type: String, message: String) {
        handler.post {
            channel?.invokeMethod("log", mapOf("type" to type, "message" to message))
        }
    }
}
