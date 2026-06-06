package org.goforthtech.roombooker_kiosk

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import android.provider.Settings

class MainActivity: FlutterActivity() {
    private val CHANNEL = "org.goforthtech.roombooker_kiosk/automation"
    private val PERMISSION_REQUEST_CODE = 123
    private var pendingUrl: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Setup Automation Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "launchMeeting" -> {
                    val url = call.argument<String>("url")
                    if (url != null) {
                        AutomationBridge.isAuthorized = true
                        AutomationBridge.sendLog("AUTH", "Automation authorized for this session.")
                        checkPermissionAndLaunch(url)
                        result.success(true)
                    } else {
                        result.error("INVALID_URL", "Meeting URL is null", null)
                    }
                }
                "checkServiceStatus" -> {
                    result.success(AutomationBridge.isServiceRunning)
                }
                "openAccessibilitySettings" -> {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Setup Diagnostic Channel & Register with Bridge
        val diagChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "org.goforthtech.roombooker_kiosk/diagnostics")
        AutomationBridge.setChannel(diagChannel)
    }

    private fun checkPermissionAndLaunch(url: String) {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE) != PackageManager.PERMISSION_GRANTED) {
            pendingUrl = url
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.CALL_PHONE), PERMISSION_REQUEST_CODE)
        } else {
            launchMeetingIntent(url)
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                pendingUrl?.let { launchMeetingIntent(it) }
            }
            pendingUrl = null
        }
    }

    private fun launchMeetingIntent(url: String) {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        
        // Try to force package if we know it (e.g., Google Meet)
        if (url.contains("meet.google.com")) {
            // New Meet
            intent.setPackage("com.google.android.apps.meetings")
            // Add fallback to Tachyon (Old Duo/Meet) if meetings package isn't responding
        } else if (url.contains("teams.microsoft.com")) {
            intent.setPackage("com.microsoft.teams")
        } else if (url.contains("zoom.us")) {
            intent.setPackage("us.zoom.videomeetings")
        }

        try {
            startActivity(intent)
        } catch (e: Exception) {
            // Fallback for Tachyon/Old Meet if New Meet isn't installed
            if (url.contains("meet.google.com")) {
               try {
                   val tachyonIntent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                   tachyonIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                   tachyonIntent.setPackage("com.google.android.apps.tachyon")
                   startActivity(tachyonIntent)
                   return
               } catch (ex: Exception) { /* Continue to generic fallback */ }
            }

            // Fallback to generic view intent if package is missing
            val fallbackIntent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
            fallbackIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(fallbackIntent)
        }
    }
}
