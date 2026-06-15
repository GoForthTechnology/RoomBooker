import 'package:flutter/material.dart';
import 'package:roombooker_core/roombooker_core.dart';

/// "Quick Book" buttons for instantly booking the assigned room for a
/// fixed duration, shown only when the room is available. Each duration
/// is enabled only if it fits within the gap before the next booking.
class QuickBookPanel extends StatelessWidget {
  static const List<Duration> durations = [
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(minutes: 60),
  ];

  final List<Request> bookings;
  final DateTime now;
  final void Function(Duration duration) onBook;

  const QuickBookPanel({
    super.key,
    required this.bookings,
    required this.now,
    required this.onBook,
  });

  Request? get _nextBooking {
    final upcoming = bookings
        .where((b) => b.eventStartTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.eventStartTime.compareTo(b.eventStartTime));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  bool _fits(Duration duration) {
    final nextBooking = _nextBooking;
    if (nextBooking == null) return true;
    return !now.add(duration).isAfter(nextBooking.eventStartTime);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final duration in durations) ...[
          if (duration != durations.first) const SizedBox(width: 16),
          _QuickBookButton(
            duration: duration,
            enabled: _fits(duration),
            onPressed: () => onBook(duration),
          ),
        ],
      ],
    );
  }
}

class _QuickBookButton extends StatelessWidget {
  final Duration duration;
  final bool enabled;
  final VoidCallback onPressed;

  const _QuickBookButton({
    required this.duration,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 64,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.2),
          disabledForegroundColor: Colors.white60,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          '${duration.inMinutes}m',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
