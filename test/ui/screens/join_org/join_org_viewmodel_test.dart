import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:room_booker/data/services/analytics_service.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/repos/org_repo.dart';
import 'package:room_booker/ui/screens/join_org/join_org_viewmodel.dart';

// Mocks
class MockOrgRepo extends Mock implements OrgRepo {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  late JoinOrgViewModel sut;
  late MockOrgRepo mockOrgRepo;
  late MockAnalyticsService mockAnalyticsService;
  const orgId = 'test-org-id';

  setUp(() {
    mockOrgRepo = MockOrgRepo();
    mockAnalyticsService = MockAnalyticsService();

    // Mock void-returning methods
    when(
      () => mockAnalyticsService.logScreenView(
        screenName: any(named: 'screenName'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) {});
    when(
      () => mockAnalyticsService.logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) {});
  });

  group('JoinOrgViewModel', () {
    test('constructor logs screen view', () {
      // Arrange
      when(
        () => mockOrgRepo.getOrg(any()),
      ).thenAnswer((_) => const Stream.empty());

      // Act
      sut = JoinOrgViewModel(
        orgRepo: mockOrgRepo,
        analyticsService: mockAnalyticsService,
        orgID: orgId,
      );

      // Assert
      verify(
        () => mockAnalyticsService.logScreenView(
          screenName: "Join Organization",
          parameters: {"orgID": orgId},
        ),
      ).called(1);
    });

    test(
      'logs accepting members when stream provides org that is accepting requests',
      () {
        // Arrange
        final org = Organization(
          id: orgId,
          name: 'Test Org',
          ownerID: 'test-owner-id',
          acceptingAdminRequests: true,
        );
        when(
          () => mockOrgRepo.getOrg(orgId),
        ).thenAnswer((_) => Stream.value(org));

        // Act
        sut = JoinOrgViewModel(
          orgRepo: mockOrgRepo,
          analyticsService: mockAnalyticsService,
          orgID: orgId,
        );

        // Assert
        sut.orgStream.listen(
          expectAsync1((_) {
            verify(
              () =>
                  mockAnalyticsService.logEvent(name: 'Org_Accepting_Members'),
            ).called(1);
          }),
        );
      },
    );

    test(
      'logs not accepting members when stream provides org that is not accepting requests',
      () {
        // Arrange
        final org = Organization(
          id: orgId,
          name: 'Test Org',
          ownerID: 'test-owner-id',
          acceptingAdminRequests: false,
        );
        when(
          () => mockOrgRepo.getOrg(orgId),
        ).thenAnswer((_) => Stream.value(org));

        // Act
        sut = JoinOrgViewModel(
          orgRepo: mockOrgRepo,
          analyticsService: mockAnalyticsService,
          orgID: orgId,
        );

        // Assert
        sut.orgStream.listen(
          expectAsync1((_) {
            verify(
              () => mockAnalyticsService.logEvent(
                name: 'Org_Not_Accepting_Members',
              ),
            ).called(1);
          }),
        );
      },
    );

    test('logs not found when stream provides null', () {
      // Arrange
      when(
        () => mockOrgRepo.getOrg(orgId),
      ).thenAnswer((_) => Stream.value(null));

      // Act
      sut = JoinOrgViewModel(
        orgRepo: mockOrgRepo,
        analyticsService: mockAnalyticsService,
        orgID: orgId,
      );

      // Assert
      sut.orgStream.listen(
        expectAsync1((_) {
          verify(
            () => mockAnalyticsService.logEvent(name: 'Org_Not_Found'),
          ).called(1);
        }),
      );
    });

    test('logs error when stream throws an error', () {
      // Arrange
      when(
        () => mockOrgRepo.getOrg(orgId),
      ).thenAnswer((_) => Stream.error(Exception('test error')));

      // Act
      sut = JoinOrgViewModel(
        orgRepo: mockOrgRepo,
        analyticsService: mockAnalyticsService,
        orgID: orgId,
      );

      // Assert
      sut.orgStream.listen(
        null,
        onError: expectAsync2((error, stackTrace) {
          verify(
            () => mockAnalyticsService.logEvent(name: 'Org_Load_Error'),
          ).called(1);
        }),
      );
    });

    test('joinOrganization calls repo and logs event', () async {
      // Arrange
      when(
        () => mockOrgRepo.getOrg(any()),
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => mockOrgRepo.addAdminRequestForCurrentUser(orgId),
      ).thenAnswer((_) async => {});

      sut = JoinOrgViewModel(
        orgRepo: mockOrgRepo,
        analyticsService: mockAnalyticsService,
        orgID: orgId,
      );

      // Act
      await sut.joinOrganization();

      // Assert
      verify(() => mockOrgRepo.addAdminRequestForCurrentUser(orgId)).called(1);
      verify(
        () => mockAnalyticsService.logEvent(name: 'Join_Request_Submitted'),
      ).called(1);
    });
  });
}
