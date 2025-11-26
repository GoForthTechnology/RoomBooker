import 'dart:async';
import 'package:flutter/widgets.dart';

extension TextEditingControllerStream on TextEditingController {
  /// Returns a stream of the text value.
  Stream<String> get textStream {
    late StreamController<String> controller;

    // Define the listener function
    void listener() {
      controller.add(text);
    }

    controller = StreamController<String>(
      onListen: () {
        // Emit current value immediately
        controller.add(text);
        // Start listening to the text controller when the stream is subscribed to
        addListener(listener);
      },
      onCancel: () {
        // Stop listening when the stream subscription is cancelled
        removeListener(listener);
        controller.close();
      },
    );

    return controller.stream;
  }
}
