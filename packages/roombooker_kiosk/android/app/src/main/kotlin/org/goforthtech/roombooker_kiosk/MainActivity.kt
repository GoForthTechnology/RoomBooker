package org.goforthtech.roombooker_kiosk

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "org.goforthtech.roombooker_kiosk/automation"
    private val DISPLAY_CHANNEL = "org.goforthtech.roombooker_kiosk/display"
    private val PERMISSION_REQUEST_CODE = 123
    private var pendingUrl: String? = null
    
    private var displayManager: KioskDisplayManager? = null
    private var secondaryEngine: FlutterEngine? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        displayManager = KioskDisplayManager(this, flutterEngine)

        // Setup Automation Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "launchMeeting" -> {
                    val url = call.argument<String>("url")
                    val displayId = call.argument<Int>("displayId")
                    if (url != null) {
                        AutomationBridge.isAuthorized = true
                        AutomationBridge.sendLog("AUTH", "Automation authorized for this session.")
                        checkPermissionAndLaunch(url, displayId)
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

        // Setup Display Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DISPLAY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getDisplays" -> {
                    result.success(displayManager?.getDisplays())
                }
                "showOnDisplay" -> {
                    val displayId = call.argument<Int>("displayId")
                    if (displayId != null) {
                        ensureSecondaryEngine()
                        displayManager?.showOnDisplay(displayId, secondaryEngine!!)
                        result.success(true)
                    } else {
                        result.error("INVALID_ID", "Display ID is null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Setup Diagnostic Channel & Register with Bridge
        val diagChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "org.goforthtech.roombooker_kiosk/diagnostics")
        AutomationBridge.setChannel(diagChannel)
    }

    override fun onDestroy() {
        displayManager?.dismiss()
        secondaryEngine?.destroy()
        super.onDestroy()
    }

    private fun ensureSecondaryEngine() {
        if (secondaryEngine == null) {
            secondaryEngine = FlutterEngine(this)
            
            val loader = io.flutter.FlutterInjector.instance().flutterLoader()
            secondaryEngine?.dartExecutor?.executeDartEntrypoint(
                DartExecutor.DartEntrypoint(
                    loader.findAppBundlePath(),
                    "secondaryDisplayMain"
                )
            )
            FlutterEngineCache.getInstance().put("secondary_engine", secondaryEngine)
        }
    }

    private fun checkPermissionAndLaunch(url: String, displayId: Int?) {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE) != PackageManager.PERMISSION_GRANTED) {
            pendingUrl = url
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.CALL_PHONE), PERMISSION_REQUEST_CODE)
        } else {
            launchMeetingIntent(url, displayId)
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                pendingUrl?.let { launchMeetingIntent(it, null) }
            }
            pendingUrl = null
        }
    }

    private fun launchMeetingIntent(url: String, displayId: Int?) {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

        if (displayId != null && android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            val options = android.app.ActivityOptions.makeBasic()
            try {
                options.setLaunchDisplayId(displayId)
                AutomationBridge.sendLog("ROUTING", "Launching on Display: $displayId")
                startActivity(intent, options.toBundle())
                return
            } catch (e: Exception) {
                AutomationBridge.sendLog("ROUTING_ERROR", "Failed to route: ${e.message}")
            }
        }
        
        // Fallback logic
        if (url.contains("meet.google.com")) {
            intent.setPackage("com.google.android.apps.meetings")
        }

        try {
            startActivity(intent)
        } catch (e: Exception) {
            val fallbackIntent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
            fallbackIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(fallbackIntent)
        }
    }
}
