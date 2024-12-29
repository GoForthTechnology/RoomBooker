import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/entities/booking.dart';
import 'package:room_booker/repos/booking_repo.dart';
import 'package:room_booker/router.dart';
import 'package:room_booker/widgets/streaming_calendar.dart';
import 'package:rxdart/rxdart.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CurrentBookingsCalendar extends StatelessWidget {
  const CurrentBookingsCalendar({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
        value: SelectedRoom(),
        child: Consumer<BookingRepo>(
            builder: (context, repo, child) => const Column(
                  children: [
                    Padding(padding: EdgeInsets.all(8), child: RoomSelector()),
                    Expanded(child: Calendar()),
                  ],
                )));
  }
}

class Calendar extends StatelessWidget {
  const Calendar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<BookingRepo, SelectedRoom>(
        builder: (context, repo, selectedRoom, child) => StreamingCalendar(
              view: CalendarView.week,
              stateStream: Rx.combineLatest3(
                  repo.bookings,
                  repo.pendingRequests,
                  repo.blackoutWindows.asStream(),
                  (bookings, requests, blackoutWindows) => CalendarState(
                        bookings: bookings + requests,
                        blackoutWindows: blackoutWindows,
                      )),
              onTapBooking: (booking) =>
                  _showBookingSummaryDialog(context, booking),
              onTap: (details) =>
                  _showRequestConfirmationDialog(context, details),
              showNavigationArrow: true,
              showDatePickerButton: true,
              showTodayButton: true,
            ));
  }
}

void _showRequestConfirmationDialog(
    BuildContext context, CalendarTapDetails details) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Request Event'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Would you like to request an event at this time slot?'),
            const Text(""),
            Text(details.date.toString()),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('Request'),
            onPressed: () {
              AutoRouter.of(context).push(NewBookingRoute(
                startTime: details.date,
              ));
              // Handle event request logic here
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

void _showBookingSummaryDialog(BuildContext context, Booking booking) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Booking Summary'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('Name: ${booking.name}'),
              Text('Email: ${booking.email}'),
              Text('Phone: ${booking.phone}'),
              Text('Event Name: ${booking.eventName}'),
              Text('Event Start Time: ${booking.eventStartTime}'),
              Text('Event End Time: ${booking.eventEndTime}'),
              Text('Event Attendance: ${booking.attendance}'),
              Text('Event Location: ${booking.selectedRoom}'),
              Text('Notes: ${booking.message}'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Close'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

class SelectedRoom extends ChangeNotifier {
  String _room = 'Room 1';

  String get room => _room;

  set room(String room) {
    _room = room;
    notifyListeners();
  }
}

class RoomSelector extends StatelessWidget {
  const RoomSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SelectedRoom, BookingRepo>(
        builder: (context, selectedRoom, repo, child) => StreamBuilder(
              stream: repo.rooms,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                return DropdownButtonFormField<String>(
                  value: selectedRoom.room,
                  decoration: const InputDecoration(
                    labelText: 'Event Location',
                    border: OutlineInputBorder(),
                  ),
                  items: snapshot.data!
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (val) => selectedRoom.room = val!,
                );
              },
            ));
  }
}
