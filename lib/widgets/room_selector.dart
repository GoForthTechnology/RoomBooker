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
                create: (_) => RoomState(initialValues),
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
