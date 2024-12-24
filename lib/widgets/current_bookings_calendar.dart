import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/repos/booking_repo.dart';
import 'package:room_booker/widgets/readonly_calendar.dart';

class CurrentBookingsCalendar extends StatelessWidget {
  const CurrentBookingsCalendar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingRepo>(
      builder: (context, repo, child) => ReadonlyCalendar(
        bookings: repo.requests,
      ),
    );
  }
}
