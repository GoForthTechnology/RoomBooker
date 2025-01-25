import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/entities/organization.dart';
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
  Room _activeRoom;
  final Map<Room, Color> _colorMap;

  RoomState(this._activeRoom, this._colorMap);

  Color color(String roomID) {
    return _colorMap[getRoom(roomID)] ?? Colors.black;
  }

  Room? getRoom(String roomID) {
    return _colorMap.keys.firstWhereOrNull((r) => r.id == roomID);
  }

  List<Room> allRooms() {
    return _colorMap.keys.toList();
  }

  Room enabledValue() {
    return _activeRoom;
  }

  bool isEnabled(String roomID) {
    return _activeRoom.id == roomID;
  }

  void setActiveRoom(Room room) {
    if (!_colorMap.containsKey(room)) {
      throw ArgumentError("Room $room not found in ${_colorMap.keys}");
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
              Map<Room, Color> initialValues = {};
              for (int i = 0; i < rooms.length; i++) {
                initialValues[rooms[i]] = roomColors[i];
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
                      color:
                          !state.isEnabled(e.id!) ? Colors.grey : roomColors[i],
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
  final Room room;
  final Function(Room) onClick;

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
            child: Text(room.name, style: const TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
