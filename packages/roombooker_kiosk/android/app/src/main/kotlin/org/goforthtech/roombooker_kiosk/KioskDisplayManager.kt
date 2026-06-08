package org.goforthtech.roombooker_kiosk

import android.app.Presentation
import android.content.Context
import android.hardware.display.DisplayManager
import android.os.Bundle
import android.view.Display
import android.view.WindowManager
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Manages the secondary display (TV) lifecycle and content.
 */
class KioskDisplayManager(private val context: Context, private val mainEngine: FlutterEngine) {
    private val displayManager = context.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
    private var activePresentation: KioskPresentation? = null

    fun getDisplays(): List<Map<String, Any>> {
        val displays = displayManager.displays
        return displays.map { display ->
            mapOf(
                "displayId" to display.displayId,
                "name" to display.name,
                "isValid" to display.isValid
            )
        }
    }

    fun showOnDisplay(displayId: Int, engine: FlutterEngine) {
        val displays = displayManager.getDisplays(DisplayManager.DISPLAY_CATEGORY_PRESENTATION)
        val targetDisplay = displays.find { it.displayId == displayId } ?: return

        activePresentation?.dismiss()
        activePresentation = KioskPresentation(context, targetDisplay, engine)
        activePresentation?.show()
    }

    fun dismiss() {
        activePresentation?.dismiss()
        activePresentation = null
    }

    private class KioskPresentation(
        outerContext: Context,
        display: Display,
        private val engine: FlutterEngine
    ) : Presentation(outerContext, display) {

        override fun onCreate(savedInstanceState: Bundle?) {
            super.onCreate(savedInstanceState)
            
            // Create a FlutterView and attach the engine
            val flutterView = FlutterView(context)
            flutterView.attachToFlutterEngine(engine)
            
            setContentView(flutterView)
        }
    }
}
