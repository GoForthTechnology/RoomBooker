import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class IntegratedWebViewStage extends StatefulWidget {
  final String url;
  const IntegratedWebViewStage({super.key, required this.url});

  @override
  State<IntegratedWebViewStage> createState() => _IntegratedWebViewStageState();
}

class _IntegratedWebViewStageState extends State<IntegratedWebViewStage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(widget.url)),
        initialSettings: InAppWebViewSettings(
          // Spoof as Desktop Chrome on Windows
          userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
          mediaPlaybackRequiresUserGesture: false,
          javaScriptEnabled: true,
          allowsInlineMediaPlayback: true,
          useShouldOverrideUrlLoading: true,
        ),
        onLoadStop: (controller, url) async {
          // Inject automation script
          await controller.evaluateJavascript(source: """
            (function() {
              console.log("Kiosk Autopilot: WebView Loaded. Watching for Join buttons...");
              
              const JOIN_KEYWORDS = ["Join", "Ask to join", "Join now", "Got it"];
              
              const attemptJoin = () => {
                const buttons = document.querySelectorAll('button, [role="button"]');
                for (const btn of buttons) {
                  const text = btn.innerText || btn.textContent || "";
                  if (JOIN_KEYWORDS.some(k => text.includes(k))) {
                    console.log("Kiosk Autopilot: Clicking " + text);
                    btn.click();
                    return true;
                  }
                }
                return false;
              };

              // Poll every 1s for 30s
              let attempts = 0;
              const interval = setInterval(() => {
                if (attemptJoin() || attempts++ > 30) {
                  clearInterval(interval);
                }
              }, 1000);
            })();
          """);
        },
        onPermissionRequest: (controller, permissionRequest) async {
          return PermissionResponse(
            resources: permissionRequest.resources,
            action: PermissionResponseAction.GRANT,
          );
        },
      ),
    );
  }
}
