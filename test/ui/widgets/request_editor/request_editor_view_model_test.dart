import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:room_booker/data/analytics_service.dart';
import 'package:room_booker/data/auth_service.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/data/repos/org_repo.dart';
import 'package:room_booker/ui/widgets/org_state_provider.dart';
import 'package:room_booker/ui/widgets/request_editor/request_editor_view_model.dart';

// Mock classes using mocktail
class MockBookingRepo extends Mock implements BookingRepo {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockAuthService extends Mock implements AuthService {}

class MockOrgState extends Mock implements OrgState {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(
      Request(
        eventStartTime: DateTime.now(),
        eventEndTime: DateTime.now(),
        roomID: 'fallback',
        roomName: 'fallback',
      ),
    );
    registerFallbackValue(
      PrivateRequestDetails(
        name: 'fallback',
        email: 'fallback',
        phone: 'fallback',
        eventName: 'fallback',
      ),
    );
    registerFallbackValue(RequestStatus.pending);
    registerFallbackValue(() async => RecurringBookingEditChoice.thisInstance);
  });

  group('RequestEditorViewModel', () {
    late MockBookingRepo mockBookingRepo;
    late MockAnalyticsService mockAnalyticsService;
    late MockAuthService mockAuthService;
    late MockOrgState mockOrgState;
    late Organization testOrg;
    late Room testRoom;
    late Request testRequest;
    late PrivateRequestDetails testDetails;

    setUp(() {
      mockBookingRepo = MockBookingRepo();
      mockAnalyticsService = MockAnalyticsService();
      mockAuthService = MockAuthService();
      mockOrgState = MockOrgState();

      testOrg = Organization(
        id: 'test-org',
        name: 'Test Org',
        ownerID: 'test-owner',
        acceptingAdminRequests: true,
      );

      testRoom = Room(id: 'room1', name: 'Test Room');

      testRequest = Request(
        id: 'request1',
        publicName: 'Test Event',
        eventStartTime: DateTime(2024, 1, 1, 10, 0),
        eventEndTime: DateTime(2024, 1, 1, 11, 0),
        roomID: 'room1',
        roomName: 'Test Room',
        status: RequestStatus.pending,
      );

      testDetails = PrivateRequestDetails(
        name: 'John Doe',
        email: 'john@example.com',
        phone: '123-456-7890',
        eventName: 'Test Event',
        message: 'Test message',
      );
    });

    // Now we can add actual RequestEditorViewModel tests!
    group('RequestEditorViewModel Instance Tests', () {
      late RequestEditorViewModel viewModel;

      setUp(() {
        // Setup mock behaviors
        when(
          () => mockAuthService.getCurrentUserEmail(),
        ).thenReturn('admin@test.com');
        when(
          () => mockAuthService.getCurrentUserID(),
        ).thenReturn('test-admin-id');
        when(() => mockOrgState.currentUserIsAdmin()).thenReturn(true);
        when(() => mockOrgState.org).thenReturn(testOrg);
      });

      tearDown(() {
        viewModel.dispose();
      });

      test('initializes correctly with request and details', () {
        viewModel = RequestEditorViewModel(
          false, // readOnly
          'Test Editor',
          testRequest,
          mockAnalyticsService,
          mockAuthService,
          mockBookingRepo,
          mockOrgState,
          testDetails,
          () async => RecurringBookingEditChoice.thisInstance,
        );

        expect(viewModel.editorTitle, 'Test Editor');
        expect(viewModel.readOnly, false);
        expect(viewModel.orgID, 'test-org');
      });

      test('initializes correctly in read-only mode', () {
        viewModel = RequestEditorViewModel(
          true, // readOnly
          'Read Only Editor',
          testRequest,
          mockAnalyticsService,
          mockAuthService,
          mockBookingRepo,
          mockOrgState,
          testDetails,
          () async => RecurringBookingEditChoice.thisInstance,
        );

        expect(viewModel.editorTitle, 'Read Only Editor');
        expect(viewModel.readOnly, true);
      });

      test('showIgnoreOverlapsToggle returns correct values', () {
        viewModel = RequestEditorViewModel(
          false,
          'Test Editor',
          testRequest,
          mockAnalyticsService,
          mockAuthService,
          mockBookingRepo,
          mockOrgState,
          testDetails,
          () async => RecurringBookingEditChoice.thisInstance,
        );

        // Should return true for existing request with admin user
        when(() => mockOrgState.currentUserIsAdmin()).thenReturn(true);
        expect(viewModel.showIgnoreOverlapsToggle(), true);

        // Should return false for non-admin user
        when(() => mockOrgState.currentUserIsAdmin()).thenReturn(false);
        expect(viewModel.showIgnoreOverlapsToggle(), false);
      });

      test('showEventLog returns correct values', () {
        viewModel = RequestEditorViewModel(
          false,
          'Test Editor',
          testRequest,
          mockAnalyticsService,
          mockAuthService,
          mockBookingRepo,
          mockOrgState,
          testDetails,
          () async => RecurringBookingEditChoice.thisInstance,
        );

        // Should return true for existing request with admin user
        when(() => mockOrgState.currentUserIsAdmin()).thenReturn(true);
        expect(viewModel.showEventLog(), true);

        // Should return false for non-admin user
        when(() => mockOrgState.currentUserIsAdmin()).thenReturn(false);
        expect(viewModel.showEventLog(), false);
      });

      test('showID returns correct values', () {
        viewModel = RequestEditorViewModel(
          false,
          'Test Editor',
          testRequest,
          mockAnalyticsService,
          mockAuthService,
          mockBookingRepo,
          mockOrgState,
          testDetails,
          () async => RecurringBookingEditChoice.thisInstance,
        );

        // Should return true for existing request (has ID)
        expect(viewModel.showID(), true);

        // Test with new request (no ID)
        final newRequest = Request(
          eventStartTime: DateTime(2024, 1, 1, 10, 0),
          eventEndTime: DateTime(2024, 1, 1, 11, 0),
          roomID: 'room1',
          roomName: 'Test Room',
        );

        final newViewModel = RequestEditorViewModel(
          false,
          'New Request Editor',
          newRequest,
          mockAnalyticsService,
          mockAuthService,
          mockBookingRepo,
          mockOrgState,
          testDetails,
          () async => RecurringBookingEditChoice.thisInstance,
        );

        expect(newViewModel.showID(), false);
        newViewModel.dispose();
      });

      test('text controllers are initialized with details', () {
        viewModel = RequestEditorViewModel(
          false,
          'Test Editor',
          testRequest,
          mockAnalyticsService,
          mockAuthService,
          mockBookingRepo,
          mockOrgState,
          testDetails,
          () async => RecurringBookingEditChoice.thisInstance,
        );

        expect(viewModel.contactNameController.text, 'John Doe');
        expect(viewModel.contactEmailController.text, 'john@example.com');
        expect(viewModel.phoneNumberController.text, '123-456-7890');
        expect(viewModel.eventNameContoller.text, 'Test Event');
        expect(viewModel.additionalInfoController.text, 'Test message');
        expect(viewModel.idController.text, 'request1');
      });

      test('text controllers are empty when no details provided', () {
        viewModel = RequestEditorViewModel(
          false,
          'Test Editor',
          testRequest,
          mockAnalyticsService,
          mockAuthService,
          mockBookingRepo,
          mockOrgState,
          null, // No details
          () async => RecurringBookingEditChoice.thisInstance,
        );

        expect(viewModel.contactNameController.text, '');
        expect(viewModel.contactEmailController.text, '');
        expect(viewModel.phoneNumberController.text, '');
        expect(viewModel.eventNameContoller.text, '');
        expect(viewModel.additionalInfoController.text, '');
      });

      test('toggleEditing changes readOnly state and notifies listeners', () {
        viewModel = RequestEditorViewModel(
          false,
          'Test Editor',
          testRequest,
          mockAnalyticsService,
          mockAuthService,
          mockBookingRepo,
          mockOrgState,
          testDetails,
          () async => RecurringBookingEditChoice.thisInstance,
        );

        var listenerCalled = false;
        viewModel.addListener(() {
          listenerCalled = true;
        });

        expect(viewModel.readOnly, false);

        viewModel.toggleEditing();
        expect(viewModel.readOnly, true);
        expect(listenerCalled, true);

        listenerCalled = false;
        viewModel.toggleEditing();
        expect(viewModel.readOnly, false);
        expect(listenerCalled, true);
      });

      test('updateEventStart updates the stream', () async {
        viewModel = RequestEditorViewModel(
          false,
          'Test Editor',
          testRequest,
          mockAnalyticsService,
          mockAuthService,
          mockBookingRepo,
          mockOrgState,
          testDetails,
          () async => RecurringBookingEditChoice.thisInstance,
        );

        final newStart = DateTime(2024, 2, 1, 14, 0);
        viewModel.updateEventStart(newStart);

        final start = await viewModel.eventStartStream.first;
        expect(start, newStart);
      });

      test('updateEventEnd updates the stream', () async {
        viewModel = RequestEditorViewModel(
          false,
          'Test Editor',
          testRequest,
          mockAnalyticsService,
          mockAuthService,
          mockBookingRepo,
          mockOrgState,
          testDetails,
          () async => RecurringBookingEditChoice.thisInstance,
        );

        final newEnd = DateTime(2024, 2, 1, 16, 0);
        viewModel.updateEventEnd(newEnd);

        final end = await viewModel.eventEndStream.first;
        expect(end, newEnd);
      });

      test('updateRoom updates the stream', () async {
        viewModel = RequestEditorViewModel(
          false,
          'Test Editor',
          testRequest,
          mockAnalyticsService,
          mockAuthService,
          mockBookingRepo,
          mockOrgState,
          testDetails,
          () async => RecurringBookingEditChoice.thisInstance,
        );

        final newRoom = Room(id: 'room2', name: 'New Room');
        viewModel.updateRoom(newRoom);

        final room = await viewModel.roomStream.first;
        expect(room.id, 'room2');
        expect(room.name, 'New Room');
      });

      test('updateIsPublic updates the stream', () async {
        viewModel = RequestEditorViewModel(
          false,
          'Test Editor',
          testRequest,
          mockAnalyticsService,
          mockAuthService,
          mockBookingRepo,
          mockOrgState,
          testDetails,
          () async => RecurringBookingEditChoice.thisInstance,
        );

        viewModel.updateIsPublic(false);

        final isPublic = await viewModel.isPublicStream.first;
        expect(isPublic, false);
      });

      test('updateIgnoreOverlaps updates the stream', () async {
        viewModel = RequestEditorViewModel(
          false,
          'Test Editor',
          testRequest,
          mockAnalyticsService,
          mockAuthService,
          mockBookingRepo,
          mockOrgState,
          testDetails,
          () async => RecurringBookingEditChoice.thisInstance,
        );

        viewModel.updateIgnoreOverlaps(true);

        final ignoreOverlaps = await viewModel.ignoreOverlapsStream.first;
        expect(ignoreOverlaps, true);
      });

      test('update methods update text controllers', () {
        viewModel = RequestEditorViewModel(
          false,
          'Test Editor',
          testRequest,
          mockAnalyticsService,
          mockAuthService,
          mockBookingRepo,
          mockOrgState,
          testDetails,
          () async => RecurringBookingEditChoice.thisInstance,
        );

        viewModel.updateEventName('New Event Name');
        expect(viewModel.eventNameContoller.text, 'New Event Name');

        viewModel.updateContactName('Jane Smith');
        expect(viewModel.contactNameController.text, 'Jane Smith');

        viewModel.updateContactEmail('jane@example.com');
        expect(viewModel.contactEmailController.text, 'jane@example.com');

        viewModel.updateContactPhone('555-1234');
        expect(viewModel.phoneNumberController.text, '555-1234');

        viewModel.updateAdditionalInfo('New info');
        expect(viewModel.additionalInfoController.text, 'New info');
      });

      test('useAdminContactInfo populates admin details', () {
        when(
          () => mockAuthService.getCurrentUserEmail(),
        ).thenReturn('admin@test.com');

        viewModel = RequestEditorViewModel(
          false,
          'Test Editor',
          testRequest,
          mockAnalyticsService,
          mockAuthService,
          mockBookingRepo,
          mockOrgState,
          testDetails,
          () async => RecurringBookingEditChoice.thisInstance,
        );

        viewModel.useAdminContactInfo();

        expect(viewModel.contactNameController.text, 'Org Admin');
        expect(viewModel.contactEmailController.text, 'admin@test.com');
        expect(viewModel.phoneNumberController.text, 'n/a');
      });

      test('useAdminContactInfo handles null email', () {
        when(() => mockAuthService.getCurrentUserEmail()).thenReturn(null);

        viewModel = RequestEditorViewModel(
          false,
          'Test Editor',
          testRequest,
          mockAnalyticsService,
          mockAuthService,
          mockBookingRepo,
          mockOrgState,
          testDetails,
          () async => RecurringBookingEditChoice.thisInstance,
        );

        viewModel.useAdminContactInfo();

        expect(viewModel.contactNameController.text, 'Org Admin');
        expect(viewModel.contactEmailController.text, '');
        expect(viewModel.phoneNumberController.text, 'n/a');
      });

      test(
        'getActions returns Add Booking action for admin with new request',
        () {
          when(() => mockOrgState.currentUserIsAdmin()).thenReturn(true);

          final newRequest = Request(
            eventStartTime: DateTime(2024, 1, 1, 10, 0),
            eventEndTime: DateTime(2024, 1, 1, 11, 0),
            roomID: 'room1',
            roomName: 'Test Room',
          );

          viewModel = RequestEditorViewModel(
            false,
            'New Request Editor',
            newRequest,
            mockAnalyticsService,
            mockAuthService,
            mockBookingRepo,
            mockOrgState,
            testDetails,
            () async => RecurringBookingEditChoice.thisInstance,
          );

          final actions = viewModel.getActions();
          expect(actions.length, 1);
          expect(actions.first.title, 'Add Booking');
        },
      );

      test(
        'getActions returns Submit Request action for non-admin with new request',
        () {
          when(() => mockOrgState.currentUserIsAdmin()).thenReturn(false);

          final newRequest = Request(
            eventStartTime: DateTime(2024, 1, 1, 10, 0),
            eventEndTime: DateTime(2024, 1, 1, 11, 0),
            roomID: 'room1',
            roomName: 'Test Room',
          );

          viewModel = RequestEditorViewModel(
            false,
            'New Request Editor',
            newRequest,
            mockAnalyticsService,
            mockAuthService,
            mockBookingRepo,
            mockOrgState,
            testDetails,
            () async => RecurringBookingEditChoice.thisInstance,
          );

          final actions = viewModel.getActions();
          expect(actions.length, 1);
          expect(actions.first.title, 'Submit Request');
        },
      );

      test('getActions returns Approve and Reject for pending requests', () {
        final pendingRequest = Request(
          id: 'pending_request',
          eventStartTime: DateTime(2024, 1, 1, 10, 0),
          eventEndTime: DateTime(2024, 1, 1, 11, 0),
          roomID: 'room1',
          roomName: 'Test Room',
          status: RequestStatus.pending,
        );

        viewModel = RequestEditorViewModel(
          false,
          'Pending Request Editor',
          pendingRequest,
          mockAnalyticsService,
          mockAuthService,
          mockBookingRepo,
          mockOrgState,
          testDetails,
          () async => RecurringBookingEditChoice.thisInstance,
        );

        final actions = viewModel.getActions();
        expect(actions.length, 2);
        expect(actions[0].title, 'Approve');
        expect(actions[1].title, 'Reject');
      });

      test(
        'getActions returns Edit action for confirmed request in read-only',
        () {
          final confirmedRequest = Request(
            id: 'confirmed_request',
            eventStartTime: DateTime(2024, 1, 1, 10, 0),
            eventEndTime: DateTime(2024, 1, 1, 11, 0),
            roomID: 'room1',
            roomName: 'Test Room',
            status: RequestStatus.confirmed,
          );

          viewModel = RequestEditorViewModel(
            true, // readOnly
            'Confirmed Request Editor',
            confirmedRequest,
            mockAnalyticsService,
            mockAuthService,
            mockBookingRepo,
            mockOrgState,
            testDetails,
            () async => RecurringBookingEditChoice.thisInstance,
          );

          final actions = viewModel.getActions();
          expect(actions.any((a) => a.title == 'Edit'), true);
          expect(actions.any((a) => a.title == 'Revisit'), true);
          expect(actions.any((a) => a.title == 'Delete'), true);
        },
      );

      test(
        'getActions returns Save action for confirmed request when editing',
        () {
          final confirmedRequest = Request(
            id: 'confirmed_request',
            eventStartTime: DateTime(2024, 1, 1, 10, 0),
            eventEndTime: DateTime(2024, 1, 1, 11, 0),
            roomID: 'room1',
            roomName: 'Test Room',
            status: RequestStatus.confirmed,
          );

          viewModel = RequestEditorViewModel(
            false, // not readOnly
            'Confirmed Request Editor',
            confirmedRequest,
            mockAnalyticsService,
            mockAuthService,
            mockBookingRepo,
            mockOrgState,
            testDetails,
            () async => RecurringBookingEditChoice.thisInstance,
          );

          final actions = viewModel.getActions();
          expect(actions.any((a) => a.title == 'Save'), true);
          expect(actions.any((a) => a.title == 'Revisit'), true);
          expect(actions.any((a) => a.title == 'Delete'), true);
        },
      );

      test(
        'getActions returns End action for confirmed recurring request with end date',
        () {
          final recurringRequest = Request(
            id: 'recurring_request',
            eventStartTime: DateTime(2024, 1, 1, 10, 0),
            eventEndTime: DateTime(2024, 1, 1, 11, 0),
            roomID: 'room1',
            roomName: 'Test Room',
            status: RequestStatus.confirmed,
            recurrancePattern: RecurrancePattern(
              frequency: Frequency.weekly,
              period: 1,
              end: DateTime(2024, 12, 31),
            ),
          );

          viewModel = RequestEditorViewModel(
            true,
            'Recurring Request Editor',
            recurringRequest,
            mockAnalyticsService,
            mockAuthService,
            mockBookingRepo,
            mockOrgState,
            testDetails,
            () async => RecurringBookingEditChoice.thisInstance,
          );

          final actions = viewModel.getActions();
          expect(actions.any((a) => a.title == 'End'), true);
        },
      );

      group('Action Execution', () {
        test('Approve action confirms request and logs analytics', () async {
          when(
            () => mockBookingRepo.confirmRequest(any(), any()),
          ).thenAnswer((_) async {});
          when(
            () => mockAnalyticsService.logEvent(
              name: any(named: 'name'),
              parameters: any(named: 'parameters'),
            ),
          ).thenAnswer((_) async {});

          final pendingRequest = Request(
            id: 'pending_request',
            publicName: 'Public Event',
            eventStartTime: DateTime(2024, 1, 1, 10, 0),
            eventEndTime: DateTime(2024, 1, 1, 11, 0),
            roomID: 'room1',
            roomName: 'Test Room',
            status: RequestStatus.pending,
          );

          viewModel = RequestEditorViewModel(
            false,
            'Pending Request Editor',
            pendingRequest,
            mockAnalyticsService,
            mockAuthService,
            mockBookingRepo,
            mockOrgState,
            testDetails,
            () async => RecurringBookingEditChoice.thisInstance,
          );

          final actions = viewModel.getActions();
          final approveAction = actions.firstWhere((a) => a.title == 'Approve');

          // Start the action but don't wait for closeEditor to complete
          // (it will hang waiting for streams in test environment)
          final future = approveAction.onPressed();

          // Give it a moment to execute the important parts
          await Future.delayed(Duration(milliseconds: 100));

          // Verify the booking repo was called
          verify(
            () => mockBookingRepo.confirmRequest('test-org', 'pending_request'),
          ).called(1);
          verify(
            () => mockAnalyticsService.logEvent(
              name: 'Booking Approved',
              parameters: {'orgID': 'test-org'},
            ),
          ).called(1);

          // Clean up the pending future
          future.timeout(Duration(milliseconds: 100), onTimeout: () => '');
        });

        test('Reject action denies request and logs analytics', () async {
          when(
            () => mockBookingRepo.denyRequest(any(), any()),
          ).thenAnswer((_) async {});
          when(
            () => mockAnalyticsService.logEvent(
              name: any(named: 'name'),
              parameters: any(named: 'parameters'),
            ),
          ).thenAnswer((_) async {});

          final pendingRequest = Request(
            id: 'pending_request',
            publicName: 'Public Event',
            eventStartTime: DateTime(2024, 1, 1, 10, 0),
            eventEndTime: DateTime(2024, 1, 1, 11, 0),
            roomID: 'room1',
            roomName: 'Test Room',
            status: RequestStatus.pending,
          );

          viewModel = RequestEditorViewModel(
            false,
            'Pending Request Editor',
            pendingRequest,
            mockAnalyticsService,
            mockAuthService,
            mockBookingRepo,
            mockOrgState,
            testDetails,
            () async => RecurringBookingEditChoice.thisInstance,
          );

          final actions = viewModel.getActions();
          final rejectAction = actions.firstWhere((a) => a.title == 'Reject');

          // Start the action but don't wait for closeEditor to complete
          final future = rejectAction.onPressed();
          await Future.delayed(Duration(milliseconds: 100));

          verify(
            () => mockBookingRepo.denyRequest('test-org', 'pending_request'),
          ).called(1);
          verify(
            () => mockAnalyticsService.logEvent(
              name: 'Booking Rejected',
              parameters: {'orgID': 'test-org'},
            ),
          ).called(1);

          future.timeout(Duration(milliseconds: 100), onTimeout: () => '');
        });

        test('Edit action toggles editing mode', () async {
          final confirmedRequest = Request(
            id: 'confirmed_request',
            eventStartTime: DateTime(2024, 1, 1, 10, 0),
            eventEndTime: DateTime(2024, 1, 1, 11, 0),
            roomID: 'room1',
            roomName: 'Test Room',
            status: RequestStatus.confirmed,
          );

          viewModel = RequestEditorViewModel(
            true, // readOnly
            'Confirmed Request Editor',
            confirmedRequest,
            mockAnalyticsService,
            mockAuthService,
            mockBookingRepo,
            mockOrgState,
            testDetails,
            () async => RecurringBookingEditChoice.thisInstance,
          );

          expect(viewModel.readOnly, true);

          final actions = viewModel.getActions();
          final editAction = actions.firstWhere((a) => a.title == 'Edit');

          await editAction.onPressed();

          expect(viewModel.readOnly, false);
        });

        test('Save action is available for confirmed request when editing', () {
          final confirmedRequest = Request(
            id: 'confirmed_request',
            publicName: 'Public Event',
            eventStartTime: DateTime(2024, 1, 1, 10, 0),
            eventEndTime: DateTime(2024, 1, 1, 11, 0),
            roomID: 'room1',
            roomName: 'Test Room',
            status: RequestStatus.confirmed,
          );

          viewModel = RequestEditorViewModel(
            false, // not readOnly
            'Confirmed Request Editor',
            confirmedRequest,
            mockAnalyticsService,
            mockAuthService,
            mockBookingRepo,
            mockOrgState,
            testDetails,
            () async => RecurringBookingEditChoice.thisInstance,
          );

          expect(viewModel.readOnly, false);

          final actions = viewModel.getActions();
          final saveAction = actions.firstWhere((a) => a.title == 'Save');

          expect(saveAction, isNotNull);
          expect(saveAction.title, 'Save');
          expect(saveAction.onPressed, isNotNull);
        });

        test('Delete action deletes booking and logs analytics', () async {
          when(
            () => mockBookingRepo.deleteBooking(any(), any(), any()),
          ).thenAnswer((_) async {});
          when(
            () => mockAnalyticsService.logEvent(
              name: any(named: 'name'),
              parameters: any(named: 'parameters'),
            ),
          ).thenAnswer((_) async {});

          final confirmedRequest = Request(
            id: 'confirmed_request',
            publicName: 'Public Event',
            eventStartTime: DateTime(2024, 1, 1, 10, 0),
            eventEndTime: DateTime(2024, 1, 1, 11, 0),
            roomID: 'room1',
            roomName: 'Test Room',
            status: RequestStatus.confirmed,
          );

          viewModel = RequestEditorViewModel(
            true, // readOnly
            'Confirmed Request Editor',
            confirmedRequest,
            mockAnalyticsService,
            mockAuthService,
            mockBookingRepo,
            mockOrgState,
            testDetails,
            () async => RecurringBookingEditChoice.thisInstance,
          );

          final actions = viewModel.getActions();
          final deleteAction = actions.firstWhere((a) => a.title == 'Delete');

          // Start but don't wait for completion
          final future = deleteAction.onPressed();
          await Future.delayed(Duration(milliseconds: 100));

          verify(
            () => mockBookingRepo.deleteBooking(
              'test-org',
              confirmedRequest,
              any(),
            ),
          ).called(1);
          verify(
            () => mockAnalyticsService.logEvent(
              name: 'Booking Deleted',
              parameters: {'orgID': 'test-org'},
            ),
          ).called(1);

          future.timeout(Duration(milliseconds: 100), onTimeout: () => '');
        });

        test('Revisit action revisits booking request', () async {
          when(
            () => mockBookingRepo.revisitBookingRequest(any(), any()),
          ).thenAnswer((_) async {});

          final confirmedRequest = Request(
            id: 'confirmed_request',
            eventStartTime: DateTime(2024, 1, 1, 10, 0),
            eventEndTime: DateTime(2024, 1, 1, 11, 0),
            roomID: 'room1',
            roomName: 'Test Room',
            status: RequestStatus.confirmed,
          );

          viewModel = RequestEditorViewModel(
            true, // readOnly
            'Confirmed Request Editor',
            confirmedRequest,
            mockAnalyticsService,
            mockAuthService,
            mockBookingRepo,
            mockOrgState,
            testDetails,
            () async => RecurringBookingEditChoice.thisInstance,
          );

          final actions = viewModel.getActions();
          final revisitAction = actions.firstWhere((a) => a.title == 'Revisit');

          final result = await revisitAction.onPressed();

          expect(result, contains('revisited'));
          verify(
            () => mockBookingRepo.revisitBookingRequest(
              'test-org',
              confirmedRequest,
            ),
          ).called(1);
        });

        test('End action ends recurring booking and logs analytics', () async {
          when(
            () => mockBookingRepo.endBooking(any(), any(), any()),
          ).thenAnswer((_) async {});
          when(
            () => mockAnalyticsService.logEvent(
              name: any(named: 'name'),
              parameters: any(named: 'parameters'),
            ),
          ).thenAnswer((_) async {});

          final recurringRequest = Request(
            id: 'recurring_request',
            publicName: 'Public Event',
            eventStartTime: DateTime(2024, 1, 1, 10, 0),
            eventEndTime: DateTime(2024, 1, 1, 11, 0),
            roomID: 'room1',
            roomName: 'Test Room',
            status: RequestStatus.confirmed,
            recurrancePattern: RecurrancePattern(
              frequency: Frequency.weekly,
              period: 1,
              end: DateTime(2024, 12, 31),
            ),
          );

          viewModel = RequestEditorViewModel(
            true,
            'Recurring Request Editor',
            recurringRequest,
            mockAnalyticsService,
            mockAuthService,
            mockBookingRepo,
            mockOrgState,
            testDetails,
            () async => RecurringBookingEditChoice.thisInstance,
          );

          // Initialize required stream
          viewModel.updateRoom(testRoom);

          final actions = viewModel.getActions();
          final endAction = actions.firstWhere((a) => a.title == 'End');

          // Start but don't wait for completion
          final future = endAction.onPressed();
          await Future.delayed(Duration(milliseconds: 100));

          verify(
            () => mockBookingRepo.endBooking(
              'test-org',
              'recurring_request',
              any(),
            ),
          ).called(1);
          verify(
            () => mockAnalyticsService.logEvent(
              name: 'Recurring Booking Ended',
              parameters: {'orgID': 'test-org'},
            ),
          ).called(1);

          future.timeout(Duration(milliseconds: 100), onTimeout: () => '');
        });

        test('Add Booking action is available for admin with new request', () {
          when(() => mockOrgState.currentUserIsAdmin()).thenReturn(true);

          final newRequest = Request(
            publicName: 'Public Event',
            eventStartTime: DateTime(2024, 1, 1, 10, 0),
            eventEndTime: DateTime(2024, 1, 1, 11, 0),
            roomID: 'room1',
            roomName: 'Test Room',
          );

          viewModel = RequestEditorViewModel(
            false,
            'New Request Editor',
            newRequest,
            mockAnalyticsService,
            mockAuthService,
            mockBookingRepo,
            mockOrgState,
            testDetails,
            () async => RecurringBookingEditChoice.thisInstance,
          );

          final actions = viewModel.getActions();
          expect(actions.length, 1);

          final addAction = actions.first;
          expect(addAction.title, 'Add Booking');
          expect(addAction.onPressed, isNotNull);
        });

        test(
          'Submit Request action is available for non-admin with new request',
          () {
            when(() => mockOrgState.currentUserIsAdmin()).thenReturn(false);

            final newRequest = Request(
              publicName: 'Public Event',
              eventStartTime: DateTime(2024, 1, 1, 10, 0),
              eventEndTime: DateTime(2024, 1, 1, 11, 0),
              roomID: 'room1',
              roomName: 'Test Room',
            );

            viewModel = RequestEditorViewModel(
              false,
              'New Request Editor',
              newRequest,
              mockAnalyticsService,
              mockAuthService,
              mockBookingRepo,
              mockOrgState,
              testDetails,
              () async => RecurringBookingEditChoice.thisInstance,
            );

            final actions = viewModel.getActions();
            expect(actions.length, 1);

            final submitAction = actions.first;
            expect(submitAction.title, 'Submit Request');
            expect(submitAction.onPressed, isNotNull);
          },
        );
      });

      test('closeEditor returns empty string when no changes exist', () async {
        viewModel = RequestEditorViewModel(
          false,
          'Test Editor',
          testRequest,
          mockAnalyticsService,
          mockAuthService,
          mockBookingRepo,
          mockOrgState,
          testDetails,
          () async => RecurringBookingEditChoice.thisInstance,
        );

        // Initialize streams with initial values
        viewModel.updateRoom(testRoom);

        final result = await viewModel.closeEditor();
        expect(result, isEmpty);
      });

      test('closeEditor returns warning when changes exist', () async {
        viewModel = RequestEditorViewModel(
          false,
          'Test Editor',
          testRequest,
          mockAnalyticsService,
          mockAuthService,
          mockBookingRepo,
          mockOrgState,
          testDetails,
          () async => RecurringBookingEditChoice.thisInstance,
        );

        viewModel.updateRoom(testRoom);
        viewModel.updateEventName('Changed Name');

        final result = await viewModel.closeEditor();
        expect(result, contains('Unsaved changes'));
      });

      test('requestStream handles publicName logic correctly', () async {
        viewModel = RequestEditorViewModel(
          false,
          'Test Editor',
          testRequest,
          mockAnalyticsService,
          mockAuthService,
          mockBookingRepo,
          mockOrgState,
          testDetails,
          () async => RecurringBookingEditChoice.thisInstance,
        );

        // Set event name but make it private
        viewModel.updateEventName('Secret Event');
        viewModel.updateIsPublic(false);
        // Ensure room is set for the stream to emit
        viewModel.updateRoom(testRoom);

        final request = await viewModel.requestStream().first;
        expect(request.publicName, isNull);

        // Make it public
        viewModel.updateIsPublic(true);
        final publicRequest = await viewModel.requestStream().first;
        expect(publicRequest.publicName, 'Secret Event');
      });

      test('Save action persists updated values to repo', () async {
        final confirmedRequest = Request(
          id: 'confirmed_request',
          eventStartTime: DateTime(2024, 1, 1, 10, 0),
          eventEndTime: DateTime(2024, 1, 1, 11, 0),
          roomID: 'room1',
          roomName: 'Test Room',
          status: RequestStatus.confirmed,
        );

        viewModel = RequestEditorViewModel(
          false, // not readOnly
          'Confirmed Request Editor',
          confirmedRequest,
          mockAnalyticsService,
          mockAuthService,
          mockBookingRepo,
          mockOrgState,
          testDetails,
          () async => RecurringBookingEditChoice.thisInstance,
        );

        // Mock updateBooking
        when(
          () => mockBookingRepo.updateBooking(
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
          ),
        ).thenAnswer((_) async {});

        // Change some values
        viewModel.updateEventName('Updated Name');
        viewModel.updateIsPublic(true);
        viewModel.updateRoom(testRoom); // Ensure stream has value

        final actions = viewModel.getActions();
        final saveAction = actions.firstWhere((a) => a.title == 'Save');

        await saveAction.onPressed();

        verify(
          () => mockBookingRepo.updateBooking(
            'test-org',
            confirmedRequest,
            any(
              that: predicate<Request>((r) => r.publicName == 'Updated Name'),
            ),
            any(),
            any(),
            any(),
          ),
        ).called(1);
      });
    });
  });
}
