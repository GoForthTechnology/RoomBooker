import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:roombooker_core/data/services/provisioning_service.dart';

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class MockHttpsCallable extends Mock implements HttpsCallable {}

class MockHttpsCallableResult<T> extends Mock
    implements HttpsCallableResult<T> {}

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

    test('claimKioskGrant calls the callable and returns a KioskGrant', () async {
      final functions = MockFirebaseFunctions();
      final callable = MockHttpsCallable();
      final result = MockHttpsCallableResult<Map<String, dynamic>>();

      when(() => functions.httpsCallable('claimKioskGrant')).thenReturn(callable);
      when(() => callable.call<Map<String, dynamic>>(any()))
          .thenAnswer((_) async => result);
      when(() => result.data).thenReturn({
        'orgID': 'org-1',
        'orgName': 'My Church',
        'roomID': 'room-1',
        'roomName': 'Sanctuary',
      });

      service = ProvisioningService(firestore: firestore, functions: functions);

      final grant = await service.claimKioskGrant(code: '123456', deviceID: 'device-1');

      expect(grant.orgID, 'org-1');
      expect(grant.orgName, 'My Church');
      expect(grant.roomID, 'room-1');
      expect(grant.roomName, 'Sanctuary');
      verify(() => callable.call<Map<String, dynamic>>({
            'code': '123456',
            'deviceID': 'device-1',
          })).called(1);
    });

    test('revokeKioskGrant calls the callable with orgID and roomID', () async {
      final functions = MockFirebaseFunctions();
      final callable = MockHttpsCallable();
      final result = MockHttpsCallableResult<Map<String, dynamic>>();

      when(() => functions.httpsCallable('revokeKioskGrant')).thenReturn(callable);
      when(() => callable.call<Map<String, dynamic>>(any()))
          .thenAnswer((_) async => result);
      when(() => result.data).thenReturn({'success': true});

      service = ProvisioningService(firestore: firestore, functions: functions);

      await service.revokeKioskGrant(orgID: 'org-1', roomID: 'room-1');

      verify(() => callable.call<Map<String, dynamic>>({
            'orgID': 'org-1',
            'roomID': 'room-1',
          })).called(1);
    });
  });
}
