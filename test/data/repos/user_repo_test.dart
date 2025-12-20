import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:room_booker/data/repos/user_repo.dart';
import 'package:room_booker/data/entities/user_profile.dart';

class MockUser extends Mock implements User {}

void main() {
  late UserRepo userRepo;
  late FakeFirebaseFirestore fakeFirestore;
  late MockUser mockUser;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    userRepo = UserRepo(db: fakeFirestore);
    mockUser = MockUser();
    when(() => mockUser.uid).thenReturn('test-user-id');
  });

  group('UserRepo', () {
    test('addUser creates user profile with empty orgs', () async {
      await userRepo.addUser(mockUser);

      final userDoc = await fakeFirestore
          .collection('users')
          .doc('test-user-id')
          .get();

      expect(userDoc.exists, isTrue);
      final profile = UserProfile.fromJson(userDoc.data()!);
      expect(profile.orgIDs, isEmpty);
    });

    test('addOrg adds orgID to user profile (new profile)', () async {
      const orgId = 'org-1';

      await fakeFirestore.runTransaction((t) async {
        userRepo.addOrg(t, 'test-user-id', orgId);
      });

      final userDoc = await fakeFirestore
          .collection('users')
          .doc('test-user-id')
          .get();

      expect(userDoc.exists, isTrue);
      final profile = UserProfile.fromJson(userDoc.data()!);
      expect(profile.orgIDs, contains(orgId));
    });

    test('addOrg adds orgID to existing profile', () async {
      const orgId1 = 'org-1';
      const orgId2 = 'org-2';

      // Setup existing profile
      await fakeFirestore
          .collection('users')
          .doc('test-user-id')
          .set(UserProfile(orgIDs: [orgId1]).toJson());

      await fakeFirestore.runTransaction((t) async {
        userRepo.addOrg(t, 'test-user-id', orgId2);
      });

      final userDoc = await fakeFirestore
          .collection('users')
          .doc('test-user-id')
          .get();

      final profile = UserProfile.fromJson(userDoc.data()!);
      expect(profile.orgIDs, containsAll([orgId1, orgId2]));
    });

    test('addOrg ignores duplicate orgID', () async {
      const orgId = 'org-1';

      // Setup existing profile with orgId
      await fakeFirestore
          .collection('users')
          .doc('test-user-id')
          .set(UserProfile(orgIDs: [orgId]).toJson());

      await fakeFirestore.runTransaction((t) async {
        userRepo.addOrg(t, 'test-user-id', orgId);
      });

      final userDoc = await fakeFirestore
          .collection('users')
          .doc('test-user-id')
          .get();

      final profile = UserProfile.fromJson(userDoc.data()!);
      expect(profile.orgIDs.length, 1);
      expect(profile.orgIDs.first, orgId);
    });

    test('removeOrg removes orgID from profile', () async {
      const orgId1 = 'org-1';
      const orgId2 = 'org-2';

      await fakeFirestore
          .collection('users')
          .doc('test-user-id')
          .set(UserProfile(orgIDs: [orgId1, orgId2]).toJson());

      await fakeFirestore.runTransaction((t) async {
        userRepo.removeOrg(t, 'test-user-id', orgId1);
      });

      final userDoc = await fakeFirestore
          .collection('users')
          .doc('test-user-id')
          .get();

      final profile = UserProfile.fromJson(userDoc.data()!);
      expect(profile.orgIDs, equals([orgId2]));
    });

    test('getUser returns profile if exists', () async {
      await fakeFirestore
          .collection('users')
          .doc('test-user-id')
          .set(UserProfile(orgIDs: []).toJson());

      final profile = await userRepo.getUser('test-user-id');
      expect(profile, isNotNull);
      expect(profile!.orgIDs, isEmpty);
    });

    test('getUser returns null if not exists', () async {
      final profile = await userRepo.getUser('non-existent-id');
      expect(profile, isNull);
    });

    test('streamUser emits profile updates', () async {
      await fakeFirestore
          .collection('users')
          .doc('test-user-id')
          .set(UserProfile(orgIDs: []).toJson());

      final stream = userRepo.streamUser('test-user-id');

      expect(stream, emits(isA<UserProfile?>()));

      // Update
      await fakeFirestore.collection('users').doc('test-user-id').update({
        'orgIDs': ['new-org'],
      });

      // We could add more specific expectations here, but basic emission check is good for now
    });
  });
}
