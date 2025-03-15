import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/entities/organization.dart';
import 'package:room_booker/repos/org_repo.dart';

List<Color> lightColors = [];

List<Color> roomColors = [
  Color.fromRGBO(131, 45, 164, 1),
  Color.fromRGBO(123, 134, 198, 1),
  Color.fromRGBO(67, 80, 175, 1),
  Color.fromRGBO(69, 153, 223, 1),
  Color.fromRGBO(57, 126, 73, 1),
  Color.fromRGBO(93, 179, 126, 1),
  Color.fromRGBO(237, 193, 75, 1),
  Color.fromRGBO(226, 93, 51, 1),
  Color.fromRGBO(216, 129, 119, 1),
  Color.fromRGBO(195, 41, 28, 1),
  Color.fromRGBO(97, 97, 97, 1),
];

class RoomState extends ChangeNotifier {
  final Map<String, Room> _rooms;
  final Set<String> _activeIDs;
  final Map<String, Color> _colorMap;

  RoomState(List<Room> rooms, Set<Room> activeRooms)
      : _rooms = Map.fromEntries(rooms.map((r) => MapEntry(r.id!, r))),
        _activeIDs = activeRooms.map((r) => r.id!).toSet(),
        _colorMap =
            Map.fromEntries(rooms.map((r) => MapEntry(r.id!, Colors.black))) {
    for (int i = 0; i < rooms.length; i++) {
      var room = rooms[i];
      _colorMap[room.id!] = roomColors[i];
    }
  }

  Color color(String roomID) {
    var color = _colorMap[roomID];
    return color ?? Colors.black;
  }

  Room? getRoom(String roomID) {
    return _rooms[roomID];
  }

  List<Room> allRooms() {
    return _rooms.values.toList();
  }

  Room? enabledValue() {
    return _activeIDs.map((id) => _rooms[id]).first;
  }

  Set<Room> enabledValues() {
    return _activeIDs.map((id) => _rooms[id]!).toSet();
  }

  bool isEnabled(String roomID) {
    return _activeIDs.contains(roomID);
  }

  void toggleRoom(Room room) {
    if (_activeIDs.contains(room.id!)) {
      if (_activeIDs.length == 1) {
        return;
      }
      _activeIDs.remove(room.id!);
    } else {
      _activeIDs.add(room.id!);
    }
    notifyListeners();
  }

  void setActiveRoom(Room? room) {
    _activeIDs.clear();
    if (room != null) {
      _activeIDs.add(room.id!);
    }
    notifyListeners();
  }

  void activateAll() {
    _activeIDs.addAll(_rooms.keys);
    notifyListeners();
  }
}

class RoomStateProvider extends StatelessWidget {
  final String orgID;
  final bool enableAllRooms;
  final Widget Function(BuildContext, RoomState) builder;

  const RoomStateProvider(
      {super.key,
      required this.orgID,
      required this.builder,
      this.enableAllRooms = false});

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
              var activeRooms = enableAllRooms ? rooms.toSet() : {rooms.first};
              var roomState = RoomState(rooms, activeRooms);
              return builder(context, roomState);
            }));
  }
}

class RoomCardSelector extends StatelessWidget {
  const RoomCardSelector({super.key});

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
                        state.toggleRoom(room);
                      },
                    )),
              ],
            ));
  }
}

class RoomDropdownSelector extends StatelessWidget {
  final bool readOnly;

  const RoomDropdownSelector({super.key, required this.readOnly});

  @override
  Widget build(BuildContext context) {
    var field = Consumer<RoomState>(
      builder: (context, state, child) => DropdownButtonFormField<Room>(
        value: state.enabledValue(),
        decoration: const InputDecoration(
          labelText: 'Room',
          border: OutlineInputBorder(),
        ),
        items: state
            .allRooms()
            .map((r) => DropdownMenuItem(
                  value: r,
                  child: Text(r.name),
                ))
            .toList(),
        onChanged: readOnly
            ? null
            : (room) {
                state.setActiveRoom(room!);
              },
      ),
    );
    return ConstrainedBox(
      constraints: const BoxConstraints.tightFor(width: 400),
      child: field,
    );
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
