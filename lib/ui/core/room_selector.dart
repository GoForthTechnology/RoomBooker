import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/repos/room_repo.dart';
import 'package:room_booker/ui/core/room_colors.dart';

List<Color> lightColors = [];

class RoomState extends ChangeNotifier {
  final String? globalRoomID;
  final Map<String, Room> _rooms;
  final Set<String> _activeIDs;

  RoomState(List<Room> rooms, Set<Room> activeRooms, this.globalRoomID)
      : _rooms = Map.fromEntries(rooms.map((r) => MapEntry(r.id!, r))),
        _activeIDs = activeRooms.map((r) => r.id!).toSet();

  Color color(String roomID) {
    if (roomID == globalRoomID) {
      return Colors.black; // Global room color
    }
    var room = _rooms[roomID];
    if (room == null) {
      throw ArgumentError("Room with ID $roomID not found");
    }
    return fromHex(room.colorHex) ?? Colors.grey;
  }

  Room? getRoom(String roomID) {
    return _rooms[roomID];
  }

  List<Room> allRooms({bool includeGlobalRoom = true}) {
    var rooms = _rooms.values.toList();
    if (!includeGlobalRoom && globalRoomID != null) {
      rooms.removeWhere((room) => room.id == globalRoomID);
    }
    return rooms;
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

  void toggleSolorRoom(Room room) {
    if (_activeIDs.length == 1) {
      _activeIDs.clear();
      activateAll();
    } else {
      setActiveRoom(room);
    }
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
  final Organization org;
  final bool enableAllRooms;
  final Widget Function(BuildContext, RoomState) builder;

  const RoomStateProvider(
      {super.key,
      required this.org,
      required this.builder,
      this.enableAllRooms = false});

  @override
  Widget build(BuildContext context) {
    var roomRepo = Provider.of<RoomRepo>(context, listen: false);
    return FutureBuilder(
        future: roomRepo.listRooms(org.id!).first,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const CircularProgressIndicator();
          }
          var rooms = snapshot.data!;
          var activeRooms = enableAllRooms ? rooms.toSet() : {rooms.first};
          var roomState = RoomState(rooms, activeRooms, org.globalRoomID);
          return builder(context, roomState);
        });
  }
}

class RoomCardSelector extends StatelessWidget {
  const RoomCardSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RoomState>(
        builder: (context, state, child) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                const Text("Active Rooms:"),
                ...state
                    .allRooms(includeGlobalRoom: true)
                    .mapIndexed((i, e) => RoomCard(
                          color: !state.isEnabled(e.id!)
                              ? Colors.grey
                              : state.color(e.id!),
                          room: e,
                          onClick: (room) {
                            state.toggleRoom(room);
                          },
                          onDoubleTap: (room) {
                            state.toggleSolorRoom(room);
                          },
                        )),
              ],
            )));
  }
}

class RoomCard extends StatelessWidget {
  final Color color;
  final Room room;
  final Function(Room) onClick;
  final Function(Room) onDoubleTap;

  const RoomCard(
      {super.key,
      required this.color,
      required this.room,
      required this.onClick,
      required this.onDoubleTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: "Show/hide this room",
      child: GestureDetector(
        onTap: () => onClick(room),
        onDoubleTap: () => onDoubleTap(room),
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
