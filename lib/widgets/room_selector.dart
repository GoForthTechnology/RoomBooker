import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/repos/org_repo.dart';

List<Color> roomColors = [
  Colors.blueAccent,
  Colors.redAccent,
  Colors.greenAccent,
  Colors.purpleAccent,
  Colors.orangeAccent,
  Colors.yellowAccent,
];

class RoomState extends ChangeNotifier {
  String _activeRoom;
  final Map<String, Color> colors;

  RoomState(this._activeRoom, this.colors);

  Color color(String room) {
    return colors[room] ?? Colors.black;
  }

  List<String> allRooms() {
    return colors.keys.toList();
  }

  String enabledValue() {
    return _activeRoom;
  }

  bool isEnabled(String room) {
    return _activeRoom == room;
  }

  void setActiveRoom(String room) {
    if (!colors.containsKey(room)) {
      throw ArgumentError("Room $room not found in ${colors.keys}");
    }
    _activeRoom = room;
    notifyListeners();
  }
}

class RoomStateProvider extends StatelessWidget {
  final String orgID;
  final Widget child;

  const RoomStateProvider(
      {super.key, required this.orgID, required this.child});

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
              return ChangeNotifierProvider(
                create: (_) =>
                    RoomState(initialValues.entries.first.key, initialValues),
                builder: (_, child) => this.child,
              );
            }));
  }
}

class RoomSelector extends StatelessWidget {
  const RoomSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RoomState>(
        builder: (context, state, child) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                const Text("Active Rooms:"),
                ...state.allRooms().mapIndexed((i, e) => RoomCard(
                      color: !state.isEnabled(e) ? Colors.grey : roomColors[i],
                      room: e,
                      onClick: (room) {
                        state.setActiveRoom(room);
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
    return Tooltip(
      message: "Show/hide this room",
      child: GestureDetector(
        onTap: () => onClick(room),
        child: Card(
          color: color,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(room, style: const TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
