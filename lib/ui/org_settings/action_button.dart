import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  final String text;
  final bool isDangerous;
  final VoidCallback onPressed;
  final String? tooltip;

  const ActionButton({
    super.key,
    this.tooltip,
    required this.text,
    required this.onPressed,
    required this.isDangerous,
  });

  @override
  Widget build(BuildContext context) {
    Widget widget = Padding(
      padding: const EdgeInsets.all(8),
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: isDangerous
              ? WidgetStateProperty.all(Colors.red)
              : WidgetStateProperty.all(Colors.blue),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
    if (tooltip != null) {
      widget = Tooltip(message: tooltip!, child: widget);
    }
    return widget;
  }
}
