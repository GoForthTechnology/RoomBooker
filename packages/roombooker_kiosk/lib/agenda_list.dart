import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roombooker_core/roombooker_core.dart';

/// Scrollable list of today's confirmed bookings for the assigned room,
/// ordered chronologically, with the in-progress booking highlighted.
class AgendaListView extends StatelessWidget {
  final List<Request> bookings;
  final DateTime now;

  const AgendaListView({
    super.key,
    required this.bookings,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return const Center(
        child: Text(
          'No meetings scheduled',
          style: TextStyle(fontSize: 20, color: Colors.white70),
        ),
      );
    }

    final sorted = [...bookings]
      ..sort((a, b) => a.eventStartTime.compareTo(b.eventStartTime));
    final timeFormat = DateFormat('h:mm a');

    return ListView.builder(
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final booking = sorted[index];
        final isCurrent = !booking.eventStartTime.isAfter(now) &&
            booking.eventEndTime.isAfter(now);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isCurrent
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: isCurrent
                ? Border.all(color: Colors.white, width: 2)
                : null,
          ),
          child: Row(
            children: [
              Text(
                '${timeFormat.format(booking.eventStartTime)} - '
                '${timeFormat.format(booking.eventEndTime)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  booking.publicName ?? 'Private Meeting',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
