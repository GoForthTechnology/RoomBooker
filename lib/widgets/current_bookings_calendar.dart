import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/entities/request.dart';
import 'package:room_booker/repos/org_repo.dart';
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
  final String orgID;

  const CurrentBookingsCalendar({super.key, required this.orgID});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrgRepo>(
      builder: (context, repo, child) => FutureBuilder(
        future: repo.listRooms(orgID).first,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const CircularProgressIndicator();
          }
          var rooms = snapshot.data!;
          Map<String, Color> initialValues = {};
          for (int i = 0; i < rooms.length; i++) {
            initialValues[rooms[i].name] = roomColors[i];
          }
          return ChangeNotifierProvider.value(
            value: RoomState(initialValues),
            child: Column(
              children: [
                const RoomCards(),
                Expanded(
                    child: Calendar(
                  orgID: orgID,
                )),
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
  final String orgID;

  const Calendar({super.key, required this.orgID});

  @override
  Widget build(BuildContext context) {
    return Consumer2<OrgRepo, RoomState>(
        builder: (context, repo, roomState, child) => StreamingCalendar(
              view: CalendarView.week,
              stateStream: Rx.combineLatest3(
                  repo.listBookings(orgID,
                      includeRooms: roomState.enabledValues()),
                  repo.listRequests(orgID,
                      includeStatuses: [RequestStatus.pending]),
                  repo.listBlackoutWindows(orgID),
                  (bookings, pendingRequests, blackoutWindows) {
                var appointments = bookings
                    .map((b) => Appointment(
                          subject: "Booked",
                          startTime: b.startTime,
                          endTime: b.endTime,
                          color: roomState.color(b.roomID),
                        ))
                    .toList();
                appointments.addAll(pendingRequests.map((r) => Appointment(
                      subject: "Requested",
                      startTime: r.eventStartTime,
                      endTime: r.eventEndTime,
                      color: roomState.color(r.selectedRoom).withAlpha(125),
                    )));
                return CalendarState(
                    appointments: appointments,
                    blackoutWindows: blackoutWindows);
              }),
              showNavigationArrow: true,
              showDatePickerButton: true,
              showTodayButton: true,
            ));
  }
}

class SelectedRoom extends ChangeNotifier {
  String _room = 'Room 1';

  String get room => _room;

  set room(String room) {
    _room = room;
    notifyListeners();
  }
}
