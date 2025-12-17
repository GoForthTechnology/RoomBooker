import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/repos/org_repo.dart';
import 'package:room_booker/data/repos/room_repo.dart';
import 'package:room_booker/data/repos/user_repo.dart';

class MockUserRepo extends Mock implements UserRepo {}

class MockRoomRepo extends Mock implements RoomRepo {}

class MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class FakeTransaction extends Fake implements Transaction {}

class FakeRoom extends Fake implements Room {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeTransaction());
    registerFallbackValue(FakeRoom());
  });

  late OrgRepo orgRepo;
  late MockUserRepo mockUserRepo;
  late MockRoomRepo mockRoomRepo;
  late MockFirebaseAnalytics mockAnalytics;
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore fakeFirestore;
  late MockUser mockUser;

  setUp(() {
    mockUserRepo = MockUserRepo();
    mockRoomRepo = MockRoomRepo();
    mockAnalytics = MockFirebaseAnalytics();
    mockAuth = MockFirebaseAuth();
    fakeFirestore = FakeFirebaseFirestore();
    mockUser = MockUser();

    orgRepo = OrgRepo(
      userRepo: mockUserRepo,
      roomRepo: mockRoomRepo,
      firestore: fakeFirestore,
      analytics: mockAnalytics,
      auth: mockAuth,
    );

    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.uid).thenReturn('test-user-id');
    when(() => mockUser.email).thenReturn('test@example.com');
    when(
      () => mockAnalytics.logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) async {});
  });

  group('OrgRepo', () {
    test('addOrgForCurrentUser creates org, room, and updates user', () async {
      when(
        () => mockUserRepo.addOrg(any(), any(), any()),
      ).thenAnswer((_) async {});

      when(
        () => mockRoomRepo.addRoom(any(), any()),
      ).thenAnswer((_) async => 'room-id');

      final orgId = await orgRepo.addOrgForCurrentUser('Test Org', 'First Room');

      expect(orgId, isNotEmpty);

      final orgDoc = await fakeFirestore.collection('orgs').doc(orgId).get();
      expect(orgDoc.exists, isTrue);
      expect(orgDoc.data()?['name'], 'Test Org');
      expect(orgDoc.data()?['ownerID'], 'test-user-id');

      verify(() => mockUserRepo.addOrg(any(), 'test-user-id', orgId)).called(1);
      verify(() => mockRoomRepo.addRoom(
        orgId,
        any(that: isA<Room>().having((r) => r.name, 'name', 'First Room')),
      )).called(1);
      verify(
        () => mockAnalytics.logEvent(
          name: 'AddOrg',
          parameters: {'orgID': orgId},
        ),
      ).called(1);
    });

    test('addOrgForCurrentUser throws if user not logged in', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      expect(
        () => orgRepo.addOrgForCurrentUser('Test Org', 'First Room'),
        throwsA(isA<String>()),
      );
    });

    test('enableGlobalBookings creates room and updates org', () async {
      const orgId = 'test-org-id';
      const roomId = 'test-room-id';
      await fakeFirestore.collection('orgs').doc(orgId).set({
        'name': 'Test Org',
      });

      when(
        () => mockRoomRepo.addRoom(orgId, any()),
      ).thenAnswer((_) async => roomId);

      await orgRepo.enableGlobalBookings(orgId);

      final orgDoc = await fakeFirestore.collection('orgs').doc(orgId).get();
      expect(orgDoc.data()?['globalRoomID'], roomId);

      verify(
        () => mockRoomRepo.addRoom(
          orgId,
          any(that: isA<Room>().having((r) => r.name, 'name', 'All Rooms')),
        ),
      ).called(1);
    });

    test('updateNotificationSettings updates org settings', () async {
      const orgId = 'test-org-id';
      await fakeFirestore.collection('orgs').doc(orgId).set({
        'name': 'Test Org',
      });

      final settings = NotificationSettings(
        notificationTargets: {
          NotificationEvent.bookingCreated: 'test@example.com',
        },
      );

      await orgRepo.updateNotificationSettings(orgId, settings);

      final orgDoc = await fakeFirestore.collection('orgs').doc(orgId).get();
      final savedSettings = NotificationSettings.fromJson(
        orgDoc.data()?['notificationSettings'],
      );

      expect(
        savedSettings.notificationTargets[NotificationEvent.bookingCreated],
        'test@example.com',
      );

      verify(
        () => mockAnalytics.logEvent(
          name: 'UpdateNotificationSettings',
          parameters: {'orgID': orgId, 'settings': settings.toJson()},
        ),
      ).called(1);
    });

    test('addAdminRequestForCurrentUser adds request', () async {
      const orgId = 'test-org-id';
      when(
        () => mockUserRepo.addOrg(any(), any(), any()),
      ).thenAnswer((_) async {});

      await orgRepo.addAdminRequestForCurrentUser(orgId);

      final requestDoc = await fakeFirestore
          .collection('orgs')
          .doc(orgId)
          .collection('admin-requests')
          .doc('test-user-id')
          .get();

      expect(requestDoc.exists, isTrue);
      expect(requestDoc.data()?['email'], 'test@example.com');

      verify(() => mockUserRepo.addOrg(any(), 'test-user-id', orgId)).called(1);
      verify(
        () => mockAnalytics.logEvent(
          name: 'AddAdminRequest',
          parameters: {'orgID': orgId, 'userID': 'test-user-id'},
        ),
      ).called(1);
    });

    test('approveAdminRequest moves request to active admins', () async {
      const orgId = 'test-org-id';
      const userId = 'requesting-user-id';
      final requestData = {
        'email': 'requesting@example.com',
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      await fakeFirestore
          .collection('orgs')
          .doc(orgId)
          .collection('admin-requests')
          .doc(userId)
          .set(requestData);

      await orgRepo.approveAdminRequest(orgId, userId);

      final requestDoc = await fakeFirestore
          .collection('orgs')
          .doc(orgId)
          .collection('admin-requests')
          .doc(userId)
          .get();
      expect(requestDoc.exists, isFalse);

      final adminDoc = await fakeFirestore
          .collection('orgs')
          .doc(orgId)
          .collection('active-admins')
          .doc(userId)
          .get();
      expect(adminDoc.exists, isTrue);
      expect(adminDoc.data()?['email'], 'requesting@example.com');

      verify(
        () => mockAnalytics.logEvent(
          name: 'ApproveAdminRequest',
          parameters: {'orgID': orgId, 'userID': userId},
        ),
      ).called(1);
    });

    test('denyAdminRequest deletes request', () async {
      const orgId = 'test-org-id';
      const userId = 'requesting-user-id';

      await fakeFirestore
          .collection('orgs')
          .doc(orgId)
          .collection('admin-requests')
          .doc(userId)
          .set({'email': 'test@example.com'});

      await orgRepo.denyAdminRequest(orgId, userId);

      final requestDoc = await fakeFirestore
          .collection('orgs')
          .doc(orgId)
          .collection('admin-requests')
          .doc(userId)
          .get();
      expect(requestDoc.exists, isFalse);

      verify(
        () => mockAnalytics.logEvent(
          name: 'DenyAdminRequest',
          parameters: {'orgID': orgId, 'userID': userId},
        ),
      ).called(1);
    });

    test('removeAdmin deletes admin', () async {
      const orgId = 'test-org-id';
      const userId = 'admin-user-id';

      await fakeFirestore
          .collection('orgs')
          .doc(orgId)
          .collection('active-admins')
          .doc(userId)
          .set({'email': 'test@example.com'});

      await orgRepo.removeAdmin(orgId, userId);

      final adminDoc = await fakeFirestore
          .collection('orgs')
          .doc(orgId)
          .collection('active-admins')
          .doc(userId)
          .get();
      expect(adminDoc.exists, isFalse);

      verify(
        () => mockAnalytics.logEvent(
          name: 'RemoveAdmin',
          parameters: {'orgID': orgId, 'userID': userId},
        ),
      ).called(1);
    });

    test('enable/disable AdminRequests updates org', () async {
      const orgId = 'test-org-id';
      await fakeFirestore.collection('orgs').doc(orgId).set({});

      await orgRepo.enableAdminRequests(orgId);
      var orgDoc = await fakeFirestore.collection('orgs').doc(orgId).get();
      expect(orgDoc.data()?['acceptingAdminRequests'], isTrue);

      await orgRepo.disableAdminRequests(orgId);
      orgDoc = await fakeFirestore.collection('orgs').doc(orgId).get();
      expect(orgDoc.data()?['acceptingAdminRequests'], isFalse);
    });

    test('publish/hide Org updates org', () async {
      const orgId = 'test-org-id';
      await fakeFirestore.collection('orgs').doc(orgId).set({});

      await orgRepo.publishOrg(orgId);
      var orgDoc = await fakeFirestore.collection('orgs').doc(orgId).get();
      expect(orgDoc.data()?['publiclyVisible'], isTrue);

      await orgRepo.hideOrg(orgId);
      orgDoc = await fakeFirestore.collection('orgs').doc(orgId).get();
      expect(orgDoc.data()?['publiclyVisible'], isFalse);
    });

    test('removeOrg deletes org and updates user', () async {
      const orgId = 'test-org-id';
      await fakeFirestore.collection('orgs').doc(orgId).set({
        'name': 'Test Org',
      });

      when(
        () => mockUserRepo.removeOrg(any(), any(), any()),
      ).thenAnswer((_) async {});

      await orgRepo.removeOrg(orgId);

      final orgDoc = await fakeFirestore.collection('orgs').doc(orgId).get();
      expect(orgDoc.exists, isFalse);

      verify(
        () => mockUserRepo.removeOrg(any(), 'test-user-id', orgId),
      ).called(1);
      verify(
        () => mockAnalytics.logEvent(
          name: 'RemoveOrg',
          parameters: {'orgID': orgId},
        ),
      ).called(1);
    });
  });
}
