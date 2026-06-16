import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:roombooker_core/data/repos/room_repo.dart';
import 'package:roombooker_core/roombooker_core.dart';
import 'package:roombooker_portal/ui/widgets/heading.dart';
import 'action_button.dart';

class RoomListWidget extends StatelessWidget {
  final Organization org;
  final RoomRepo repo;

  const RoomListWidget({super.key, required this.org, required this.repo});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: repo.listRooms(org.id!),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('Error loading rooms');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          return _buildRoomList(context, snapshot.data ?? []);
        });
  }

  Widget _buildRoomList(BuildContext context, List<Room> rooms) {
    Widget content;
    if (rooms.isEmpty) {
      content = const Text('No rooms found. Please add one.');
    } else {
      content = ConstrainedBox(
        constraints: BoxConstraints.tightFor(width: 400),
        child: ReorderableListView.builder(
          shrinkWrap: true,
          itemCount: rooms.length,
          // Prevent scrolling to avoid conflicts with the parent scroll view
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorderItem: (oldIndex, newIndex) async {
            final updatedRooms = List<Room>.from(rooms);
            final room = updatedRooms.removeAt(oldIndex);
            updatedRooms.insert(newIndex, room);
            // Call repo to update order (implement this in your repo)
            await repo.reorderRooms(org.id!, updatedRooms);
          },
          itemBuilder: (context, index) {
            var room = rooms[index];
            return Row(
              key: ValueKey(room.id),
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(Icons.drag_handle),
                  ),
                ),
                Expanded(
                  child: RoomTile(
                    org: org,
                    room: room,
                    onDeleted: () async {
                      var confirmed = await confirmRoomDeletion(context);
                      if (confirmed == true) {
                        await repo.removeRoom(org.id!, room.id!);
                      }
                    },
                  ),
                ),
              ],
            );
          },
        ),
      );
    }
    return Column(
      children: [
        const Heading("Rooms"),
        content,
        ActionButton(
          isDangerous: false,
          text: 'Add Room',
          onPressed: () async {
            var roomName = await promptForRoomName(context);
            if (roomName != null) {
              await repo.addRoom(org.id!, Room(name: roomName));
            }
          },
        ),
      ],
    );
  }
}

Future<bool?> confirmRoomDeletion(BuildContext context) {
  return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
            title: const Text('Delete Room?'),
            content: const Text('Are you sure you want to delete this room?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: const Text('Delete'),
              ),
            ],
          ));
}

class RoomTile extends StatelessWidget {
  final Organization org;
  final Room room;
  final VoidCallback onDeleted;
  final VoidCallback? onUpdated;

  const RoomTile({
    super.key,
    required this.org,
    required this.room,
    required this.onDeleted,
    this.onUpdated,
  });

  @override
  Widget build(BuildContext context) {
    var orgRepo = Provider.of<RoomRepo>(context, listen: false);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: room.color,
        ),
        title: Text(room.name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _KioskStatusButton(org: org, room: room),
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Room',
              onPressed: () async {
                final updatedRoom = await showDialog<Room>(
                  context: context,
                  builder: (context) => _EditRoomDialog(room: room),
                );
                // If the user updated the room, we should save it.
                if (updatedRoom != null) {
                  await orgRepo.updateRoom(org.id!, updatedRoom);
                  if (onUpdated != null) onUpdated!();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete Room',
              onPressed: onDeleted,
            ),
          ],
        ),
      ),
    );
  }
}

class _KioskStatusButton extends StatelessWidget {
  final Organization org;
  final Room room;

  const _KioskStatusButton({required this.org, required this.room});

  @override
  Widget build(BuildContext context) {
    final provisioningService =
        Provider.of<ProvisioningService>(context, listen: false);
    return StreamBuilder<List<KioskGrantRecord>>(
      stream: provisioningService.listKioskGrants(
        orgID: org.id!,
        roomID: room.id!,
      ),
      builder: (context, snapshot) {
        final grants = snapshot.data ?? [];
        if (grants.isEmpty) {
          return IconButton(
            icon: const Icon(Icons.screenshot_monitor),
            tooltip: 'Link Kiosk',
            onPressed: () => _provisionKiosk(context, provisioningService),
          );
        }
        if (grants.length > 1) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Tooltip(
                message: 'Multiple Kiosk devices linked',
                child: Icon(Icons.warning_amber, color: Colors.orange,
                    size: 20),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.link_off, color: Colors.red),
                tooltip: 'Revoke All Kiosks',
                onPressed: () => _confirmRevoke(
                    context, provisioningService, multiple: true),
              ),
            ],
          );
        }
        final grant = grants.first;
        final shortID = (grant.deviceID ?? 'unknown').length > 8
            ? '${(grant.deviceID ?? 'unknown').substring(0, 8)}…'
            : (grant.deviceID ?? 'unknown');
        final dateStr = grant.createdAt != null
            ? DateFormat('MMM d, y').format(grant.createdAt!)
            : '—';
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: 'Kiosk linked: ${grant.deviceID ?? "unknown"}'
                  '\nSince: $dateStr',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.screenshot_monitor,
                      size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(shortID,
                      style: const TextStyle(fontSize: 11,
                          color: Colors.green)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.link_off, color: Colors.red),
              tooltip: 'Revoke Kiosk',
              onPressed: () =>
                  _confirmRevoke(context, provisioningService),
            ),
          ],
        );
      },
    );
  }

  Future<void> _provisionKiosk(
      BuildContext context, ProvisioningService svc) async {
    try {
      final code = await svc.createActivationCode(
        orgID: org.id!,
        orgName: org.name,
        roomID: room.id!,
        roomName: room.name,
      );
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Provision Kiosk'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter this 6-digit code on the Kiosk terminal'
                ' to link it to this room:',
              ),
              const SizedBox(height: 16),
              Text(
                code,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Valid for 10 minutes',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to generate code: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _confirmRevoke(
      BuildContext context, ProvisioningService svc,
      {bool multiple = false}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(multiple ? 'Revoke All Kiosks?' : 'Revoke Kiosk?'),
        content: const Text(
          'This will disconnect the Kiosk from this room. '
          'The device will lose access on its next interaction.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await svc.adminRevokeKioskGrant(orgID: org.id!, roomID: room.id!);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to revoke Kiosk: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }
}

class _EditRoomDialog extends StatefulWidget {
  final Room room;

  const _EditRoomDialog({required this.room});

  @override
  State<_EditRoomDialog> createState() => _EditRoomDialogState();
}

class _EditRoomDialogState extends State<_EditRoomDialog> {
  late TextEditingController _nameController;
  Color? _selectedColor;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.room.name);
    _selectedColor = widget.room.color;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Room'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Room Name'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Color:'),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  final color = await showDialog<Color>(
                    context: context,
                    builder: (context) => _ColorPickerDialog(
                      initialColor: _selectedColor ?? Colors.black,
                    ),
                  );
                  if (color != null) {
                    setState(() {
                      _selectedColor = color;
                    });
                  }
                },
                child: CircleAvatar(
                  backgroundColor: _selectedColor,
                  radius: 16,
                  child: Icon(Icons.edit, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(widget.room.copyWith(
              name: _nameController.text,
              colorHex: toHex(_selectedColor),
            ));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _ColorPickerDialog extends StatelessWidget {
  final Color initialColor;

  const _ColorPickerDialog({required this.initialColor});

  @override
  Widget build(BuildContext context) {
    // Simple color choices for demonstration
    return AlertDialog(
      title: const Text('Pick a color'),
      content: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: colors
            .map(
              (color) => GestureDetector(
                onTap: () => Navigator.of(context).pop(color),
                child: CircleAvatar(
                  backgroundColor: color,
                  radius: 18,
                  child: initialColor == color
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

Future<String?> promptForRoomName(BuildContext context) {
  var controller = TextEditingController();
  return showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: const Text('Add Room'),
            content: TextFormField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Room Name'),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(null);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(controller.text);
                },
                child: const Text('Add'),
              ),
            ],
          ));
}
