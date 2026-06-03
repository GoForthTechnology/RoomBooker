package org.goforthtech.roombooker_kiosk

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "org.goforthtech.roombooker_kiosk/automation"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "launchMeeting" -> {
                    val url = call.argument<String>("url")
                    if (url != null) {
                        launchMeetingIntent(url)
                        result.success(true)
                    } else {
                        result.error("INVALID_URL", "Meeting URL is null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun launchMeetingIntent(url: String) {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        
        // Try to force package if we know it (e.g., Google Meet)
        if (url.contains("meet.google.com")) {
            intent.setPackage("com.google.android.apps.meetings")
        } else if (url.contains("teams.microsoft.com")) {
            intent.setPackage("com.microsoft.teams")
        } else if (url.contains("zoom.us")) {
            intent.setPackage("us.zoom.videomeetings")
        }

        try {
            startActivity(intent)
        } catch (e: Exception) {
            // Fallback to generic view intent if package is missing
            val fallbackIntent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
            fallbackIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(fallbackIntent)
        }
    }
}
