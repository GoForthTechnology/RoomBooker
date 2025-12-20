import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/repos/room_repo.dart';

void main() {
  late RoomRepo roomRepo;
  late FakeFirebaseFirestore fakeFirestore;
  const orgId = 'test-org';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    roomRepo = RoomRepo(db: fakeFirestore);
  });

  group('RoomRepo', () {
    test('addRoom adds room to org', () async {
      final room = Room(name: 'Test Room', colorHex: '0xFFFFFF');

      final roomId = await roomRepo.addRoom(orgId, room);

      final roomDoc = await fakeFirestore
          .collection('orgs')
          .doc(orgId)
          .collection('rooms')
          .doc(roomId)
          .get();

      expect(roomDoc.exists, isTrue);
      expect(roomDoc.data()?['name'], 'Test Room');
    });

    test('listRooms returns sorted rooms', () async {
      // Add rooms in random order with specific order keys
      final roomsCollection = fakeFirestore
          .collection('orgs')
          .doc(orgId)
          .collection('rooms');

      await roomsCollection.add(
        Room(name: 'Second', orderKey: 2, colorHex: '0xFFFFFF').toJson(),
      );
      await roomsCollection.add(
        Room(name: 'First', orderKey: 1, colorHex: '0xFFFFFF').toJson(),
      );
      await roomsCollection.add(
        Room(name: 'Third', orderKey: 3, colorHex: '0xFFFFFF').toJson(),
      );

      final stream = roomRepo.listRooms(orgId);

      await expectLater(
        stream,
        emits(
          isA<List<Room>>().having(
            (rooms) => rooms.map((r) => r.name).toList(),
            'names',
            ['First', 'Second', 'Third'],
          ),
        ),
      );
    });

    test('removeRoom deletes room', () async {
      final roomsCollection = fakeFirestore
          .collection('orgs')
          .doc(orgId)
          .collection('rooms');

      final ref = await roomsCollection.add(
        Room(name: 'To Delete', colorHex: '0xFFFFFF').toJson(),
      );

      await roomRepo.removeRoom(orgId, ref.id);

      final doc = await ref.get();
      expect(doc.exists, isFalse);
    });

    test('updateRoom updates existing room', () async {
      final roomsCollection = fakeFirestore
          .collection('orgs')
          .doc(orgId)
          .collection('rooms');

      final ref = await roomsCollection.add(
        Room(name: 'Old Name', colorHex: '0xFFFFFF').toJson(),
      );

      final updatedRoom = Room(
        id: ref.id,
        name: 'New Name',
        colorHex: '0xFFFFFF',
      );

      await roomRepo.updateRoom(orgId, updatedRoom);

      final doc = await ref.get();
      expect(doc.data()?['name'], 'New Name');
    });

    test('reorderRooms updates orderKeys in batch', () async {
      final roomsCollection = fakeFirestore
          .collection('orgs')
          .doc(orgId)
          .collection('rooms');

      final ref1 = await roomsCollection.add(
        Room(name: 'One', orderKey: 0, colorHex: '0xFFFFFF').toJson(),
      );
      final ref2 = await roomsCollection.add(
        Room(name: 'Two', orderKey: 0, colorHex: '0xFFFFFF').toJson(),
      );

      final room1 = Room(id: ref1.id, name: 'One', colorHex: '0xFFFFFF');
      final room2 = Room(id: ref2.id, name: 'Two', colorHex: '0xFFFFFF');

      // Swap order: Two (0), One (1)
      await roomRepo.reorderRooms(orgId, [room2, room1]);

      final doc1 = await ref1.get();
      final doc2 = await ref2.get();

      expect(doc1.data()?['orderKey'], 1);
      expect(doc2.data()?['orderKey'], 0);
    });
  });
}
