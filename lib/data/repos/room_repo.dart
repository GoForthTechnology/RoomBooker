import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:room_booker/data/entities/organization.dart';

class RoomRepo extends ChangeNotifier {
  final FirebaseFirestore _db;

  RoomRepo({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  Stream<List<Room>> listRooms(String orgID) {
    return _roomsRef(orgID).snapshots().map((s) {
      var rooms = s.docs.map((d) => d.data()).toList();
      rooms.sort((a, b) => a.orderKey?.compareTo(b.orderKey ?? 1) ?? 1);
      return rooms;
    });
  }

  Future<String> addRoom(String orgID, Room room) {
    return _roomsRef(orgID).add(room).then((ref) => ref.id);
  }

  Future<void> removeRoom(String orgID, String roomID) async {
    await _roomRef(orgID, roomID).delete();
  }

  Future<void> updateRoom(String orgID, Room room) async {
    await _roomRef(orgID, room.id!).set(room);
  }

  Future<void> reorderRooms(String orgID, List<Room> rooms) async {
    var batch = _db.batch();
    for (var i = 0; i < rooms.length; i++) {
      var room = rooms[i];
      var roomRef = _roomRef(orgID, room.id!);
      batch.update(roomRef, {'orderKey': i});
    }
    await batch.commit();
  }

  DocumentReference<Room> _roomRef(String orgID, String bookingID) {
    return _roomsRef(orgID).doc(bookingID);
  }

  CollectionReference<Room> _roomsRef(String orgID) {
    return _db.collection("orgs").doc(orgID).collection("rooms").withConverter(
          fromFirestore: (snapshot, _) =>
              Room.fromJson(snapshot.data()!).copyWith(id: snapshot.id),
          toFirestore: (request, _) => request.toJson(),
        );
  }
}
