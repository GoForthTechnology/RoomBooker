import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/entities/booking.dart';
import 'package:room_booker/repos/booking_repo.dart';
import 'package:room_booker/widgets/streaming_calendar.dart';
import 'package:rxdart/rxdart.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:collection/collection.dart';

List<Color> roomColors = [
  Colors.blueAccent,
  Colors.redAccent,
  Colors.greenAccent,
  Colors.purpleAccent,
  Colors.orangeAccent,
  Colors.yellowAccent,
];

class CurrentBookingsCalendar extends StatelessWidget {
  const CurrentBookingsCalendar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingRepo>(
      builder: (context, repo, child) => FutureBuilder(
        future: repo.rooms.first,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const CircularProgressIndicator();
          }
          Map<String, Color> initialValues = {};
          for (int i = 0; i < snapshot.data!.length; i++) {
            initialValues[snapshot.data![i]] = roomColors[i];
          }
          return ChangeNotifierProvider.value(
            value: RoomState(initialValues),
            child: const Column(
              children: [
                RoomCards(),
                Expanded(child: Calendar()),
              ],
            ),
          );
        },
      ),
    );
  }
}

class RoomState extends ChangeNotifier {
  final Map<String, bool> values;
  final Map<String, Color> colors;

  RoomState(this.colors) : values = colors.map((k, _) => MapEntry(k, true));

  Color color(String room) {
    return colors[room] ?? Colors.black;
  }

  Set<String> enabledValues() {
    return values.entries.where((e) => e.value).map((e) => e.key).toSet();
  }

  bool isEnabled(String room) {
    return values[room] ?? false;
  }

  void toggleRoom(String room) {
    var val = values[room] ?? false;
    values[room] = !val;
    notifyListeners();
  }
}

class RoomCards extends StatelessWidget {
  const RoomCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RoomState>(
        builder: (context, state, child) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                const Text("Active Rooms:"),
                ...state.values.keys.mapIndexed((i, e) => RoomCard(
                      color: !state.isEnabled(e) ? Colors.grey : roomColors[i],
                      room: e,
                      onClick: (room) {
                        state.toggleRoom(room);
                      },
                    )),
              ],
            ));
  }
}

class RoomCard extends StatelessWidget {
  final Color color;
  final String room;
  final Function(String) onClick;

  const RoomCard(
      {super.key,
      required this.color,
      required this.room,
      required this.onClick});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onClick(room),
      child: Card(
        color: color,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(room, style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}

class Calendar extends StatelessWidget {
  const Calendar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<BookingRepo, RoomState>(
        builder: (context, repo, roomState, child) => StreamingCalendar(
              view: CalendarView.week,
              stateStream: Rx.combineLatest2(
                  repo.bookings(roomID: roomState.enabledValues()),
                  repo.blackoutWindows.asStream(),
                  (bookings, blackoutWindows) => CalendarState(
                        bookings: bookings,
                        blackoutWindows: blackoutWindows,
                      )),
              apointmentColor: (b) => roomState.color(b.selectedRoom),
              onTapBooking: (booking) =>
                  _showBookingSummaryDialog(context, booking),
              showNavigationArrow: true,
              showDatePickerButton: true,
              showTodayButton: true,
            ));
  }
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
