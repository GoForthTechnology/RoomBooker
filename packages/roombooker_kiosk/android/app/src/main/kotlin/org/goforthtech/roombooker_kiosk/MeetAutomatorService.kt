package org.goforthtech.roombooker_kiosk

import android.accessibilityservice.AccessibilityService
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import java.util.Locale

class MeetAutomatorService : AccessibilityService() {

    private val handler = Handler(Looper.getMainLooper())
    private var isScanning = false
    private var lastClickTime = 0L
    private val CLICK_COOLDOWN_MS = 3000L // Wait 3 seconds between clicks

    companion object {
        private const val TAG = "MeetAutomatorService"
        private const val SCAN_INTERVAL_MS = 1000L
        private val TARGET_PACKAGES = setOf(
            "com.google.android.apps.meetings", // New Meet
            "com.google.android.apps.tachyon",  // Legacy Meet/Duo
            "com.google.android.gms",           // Google Account Picker
            "com.google.android.gsf"            // Google Services Framework
        )
    }

    private val scanRunnable = object : Runnable {
        override fun run() {
            if (isScanning) {
                val root = rootInActiveWindow
                val activePackage = root?.packageName?.toString() ?: ""
                
                // CRITICAL: If we are back in our app, or in an UNKNOWN app (like YouTube), STOP.
                if (activePackage == "org.goforthtech.roombooker_kiosk") {
                    AutomationBridge.sendLog("STANDBY", "Returned to Kiosk. Pausing.")
                    isScanning = false
                    return
                }

                if (activePackage != "" && activePackage !in TARGET_PACKAGES && !activePackage.contains("android.settings")) {
                    AutomationBridge.sendLog("RESTRICTION", "Unauthorized app detected ($activePackage). Aborting scan.")
                    isScanning = false
                    return
                }

                val currentTime = System.currentTimeMillis()
                if (currentTime - lastClickTime > CLICK_COOLDOWN_MS) {
                    performScan()
                }
                handler.postDelayed(this, SCAN_INTERVAL_MS)
            }
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        AutomationBridge.isServiceRunning = true
        AutomationBridge.sendLog("SERVICE_CONNECTED", "Accessibility Service is now LIVE")
        startHeartbeat()
    }

    private fun startHeartbeat() {
        handler.postDelayed(object : Runnable {
            override fun run() {
                if (AutomationBridge.isServiceRunning) {
                    AutomationBridge.sendLog("HEARTBEAT", "Service active...")
                    handler.postDelayed(this, 5000L)
                }
            }
        }, 5000L)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        val packageName = event.packageName?.toString() ?: return
        
        if (packageName in TARGET_PACKAGES) {
            if (!isScanning) {
                AutomationBridge.sendLog("TARGET_DETECTED", "Focus on $packageName. Scanning started.")
                isScanning = true
                handler.post(scanRunnable)
            }
        }
    }

    private fun performScan() {
        val root = rootInActiveWindow
        if (root == null) return
        searchAndInteract(root, 0)
    }

    private fun searchAndInteract(node: AccessibilityNodeInfo, depth: Int): Boolean {
        val viewId = node.viewIdResourceName ?: ""
        val text = node.text?.toString() ?: ""
        val desc = node.contentDescription?.toString() ?: ""

        // 1. Account Picker (High Priority) - DISABLED FOR V5.7
        /*
        if (text.contains("@") || viewId.contains("account_name") || viewId.contains("email")) {
            if (node.isClickable && node.isEnabled) {
                executeClick(node, "Account Node: $text")
                return true
            } else {
                var parent = node.parent
                while (parent != null) {
                    if (parent.isClickable && parent.isEnabled) {
                        executeClick(parent, "Account Parent: $text")
                        return true
                    }
                    parent = parent.parent
                }
            }
        }
        */

        // 2. Join Buttons
        val lowerText = text.lowercase(Locale.ROOT)
        val lowerDesc = desc.lowercase(Locale.ROOT)
        val joinKeywords = listOf("join", "ask to join", "join now", "rejoin", "got it", "admit")
        
        if (joinKeywords.any { lowerText.contains(it) || lowerDesc.contains(it) } || 
            viewId.contains("join_button") || viewId.contains("confirm_button")) {
            
            if (node.isClickable && node.isEnabled) {
                executeClick(node, "Join Button: $text")
                return true
            } else {
                node.parent?.let { parent ->
                    if (parent.isClickable && parent.isEnabled) {
                        executeClick(parent, "Join Parent: $text")
                        return true
                    }
                }
            }
        }

        // 3. Recurse
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            if (searchAndInteract(child, depth + 1)) return true
        }
        return false
    }

    private fun executeClick(node: AccessibilityNodeInfo, label: String) {
        if (!AutomationBridge.isAuthorized) {
            // AutomationBridge.sendLog("STANDBY", "Ignoring $label (Not authorized)")
            return
        }
        
        AutomationBridge.sendLog("ACTION", "Clicking $label")
        node.performAction(AccessibilityNodeInfo.ACTION_CLICK)
        lastClickTime = System.currentTimeMillis()
        
        // Revoke authorization after successful Join click
        if (label.contains("Join") || label.contains("Ask to join")) {
            AutomationBridge.isAuthorized = false
            AutomationBridge.sendLog("AUTH_REVOKED", "Sequence complete. Autopilot standby.")
        }
    }

    override fun onInterrupt() {
        isScanning = false
        handler.removeCallbacks(scanRunnable)
        AutomationBridge.sendLog("SERVICE_INTERRUPTED", "Service was interrupted")
    }

    override fun onDestroy() {
        super.onDestroy()
        AutomationBridge.isServiceRunning = false
        isScanning = false
        handler.removeCallbacks(scanRunnable)
    }
}
