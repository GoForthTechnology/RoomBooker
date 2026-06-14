import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roombooker_core/data/services/provisioning_service.dart';

void main() {
  group('ProvisioningService', () {
    late FakeFirebaseFirestore firestore;
    late ProvisioningService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = ProvisioningService(firestore: firestore);
    });

    test('createActivationCode stores a code with human-readable names', () async {
      final code = await service.createActivationCode(
        orgID: 'org-123',
        orgName: 'My Church',
        roomID: 'room-456',
        roomName: 'Sanctuary',
      );

      expect(code.length, 6);
      final doc = await firestore.collection('provisioning_codes').doc(code).get();
      expect(doc.exists, true);
      expect(doc.data()!['orgID'], 'org-123');
      expect(doc.data()!['orgName'], 'My Church');
      expect(doc.data()!['roomID'], 'room-456');
      expect(doc.data()!['roomName'], 'Sanctuary');
    });

  });
}
