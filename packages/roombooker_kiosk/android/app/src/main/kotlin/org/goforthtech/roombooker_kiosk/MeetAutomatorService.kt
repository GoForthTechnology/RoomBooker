package org.goforthtech.roombooker_kiosk

import android.accessibilityservice.AccessibilityService
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

class MeetAutomatorService : AccessibilityService() {

    companion object {
        private const val TAG = "MeetAutomatorService"
        private val TARGET_PACKAGES = setOf(
            "com.google.android.apps.meetings",
            "com.microsoft.teams",
            "us.zoom.videomeetings"
        )
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        val packageName = event.packageName?.toString()
        if (packageName !in TARGET_PACKAGES) return

        Log.d(TAG, "Event from $packageName: ${AccessibilityEvent.eventTypeToString(event.eventType)}")

        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED || 
            event.eventType == AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED) {
            
            val rootNode = rootInActiveWindow ?: return
            findAndClickJoinButton(rootNode, packageName!!)
        }
    }

    private fun findAndClickJoinButton(node: AccessibilityNodeInfo, packageName: String) {
        // Broad search for "Join" or "Ask to Join" buttons
        val joinTerms = listOf("Join", "Ask to join", "Join now", "Rejoin")
        
        for (term in joinTerms) {
            val nodes = node.findAccessibilityNodeInfosByText(term)
            if (nodes != null && nodes.isNotEmpty()) {
                for (foundNode in nodes) {
                    if (foundNode.isClickable && foundNode.isEnabled) {
                        Log.i(TAG, "Found Join button with text: $term. Clicking...")
                        foundNode.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                        return
                    }
                }
            }
        }

        // Recursive search for deeper nodes if needed (Teams/Zoom sometimes hide buttons)
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            findAndClickJoinButton(child, packageName)
        }
    }

    override fun onInterrupt() {
        Log.w(TAG, "Service Interrupted")
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.i(TAG, "Service Connected")
    }
}
