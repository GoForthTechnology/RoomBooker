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
import 'package:room_booker/ui/widgets/room_selector.dart';

// Mock classes using mocktail
class MockBookingRepo extends Mock implements BookingRepo {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockAuthService extends Mock implements AuthService {}

class MockOrgState extends Mock implements OrgState {}

class MockRoomState extends Mock implements RoomState {}

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
    late RoomState mockRoom;

    setUp(() {
      mockBookingRepo = MockBookingRepo();
      mockAnalyticsService = MockAnalyticsService();
      mockAuthService = MockAuthService();
      mockOrgState = MockOrgState();
      mockRoom = MockRoomState();

      testOrg = Organization(
        id: 'test-org',
        name: 'Test Org',
        ownerID: 'test-owner',
        acceptingAdminRequests: true,
      );

      testRoom = Room(id: 'room1', name: 'Test Room');

      when(() => mockRoom.enabledValues()).thenAnswer((_) => {testRoom});

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

      RequestEditorViewModel createViewModel({String title = 'Test Editor'}) {
        return RequestEditorViewModel(
          editorTitle: title,
          roomState: mockRoom,
          analyticsService: mockAnalyticsService,
          authService: mockAuthService,
          bookingRepo: mockBookingRepo,
          orgState: mockOrgState,
          choiceProvider: () async => RecurringBookingEditChoice.thisInstance,
        );
      }

      test('initializes correctly with request and details', () async {
        viewModel = createViewModel();
        viewModel.initializeFromExistingRequest(testRequest, testDetails);

        expect(viewModel.editorTitle, 'Test Editor');
        expect(viewModel.orgID, 'test-org');

        final viewState = await viewModel.viewStateStream.first;
        // Defaults to readOnly (true) because editingEnabled is seeded false
        expect(viewState.readOnly, true);
      });

      test('initializes correctly in new request mode', () async {
        viewModel = createViewModel();
        viewModel.initializeNewRequest(DateTime.now());

        expect(viewModel.editorTitle, 'Test Editor');
        final viewState = await viewModel.viewStateStream.first;
        // initializeNewRequest sets editingEnabled to true
        expect(viewState.readOnly, false);
      });

      test('showIgnoreOverlapsToggle returns correct values', () async {
        // Case 1: Admin
        when(() => mockOrgState.currentUserIsAdmin()).thenReturn(true);
        viewModel = createViewModel();
        viewModel.initializeFromExistingRequest(testRequest, testDetails);
        var viewState = await viewModel.viewStateStream.first;
        expect(viewState.showIgnoreOverlapsToggle, true);

        // Case 2: Non-admin
        when(() => mockOrgState.currentUserIsAdmin()).thenReturn(false);
        viewModel = createViewModel();
        viewModel.initializeFromExistingRequest(testRequest, testDetails);
        viewState = await viewModel.viewStateStream.first;
        expect(viewState.showIgnoreOverlapsToggle, false);
      });

      test('showEventLog returns correct values', () async {
        // Case 1: Admin
        when(() => mockOrgState.currentUserIsAdmin()).thenReturn(true);
        viewModel = createViewModel();
        viewModel.initializeFromExistingRequest(testRequest, testDetails);
        var viewState = await viewModel.viewStateStream.first;
        expect(viewState.showEventLog, true);

        // Case 2: Non-admin
        when(() => mockOrgState.currentUserIsAdmin()).thenReturn(false);
        viewModel = createViewModel();
        viewModel.initializeFromExistingRequest(testRequest, testDetails);
        viewState = await viewModel.viewStateStream.first;
        expect(viewState.showEventLog, false);
      });

      test('showID returns correct values', () async {
        // Existing request (has ID)
        viewModel = createViewModel();
        viewModel.initializeFromExistingRequest(testRequest, testDetails);
        var viewState = await viewModel.viewStateStream.first;
        expect(viewState.showID, true);

        // New request (no ID)
        final newViewModel = createViewModel();
        newViewModel.initializeNewRequest(DateTime.now());
        var newViewState = await newViewModel.viewStateStream.first;
        expect(newViewState.showID, false);
        newViewModel.dispose();
      });

      test('text controllers are initialized with details', () async {
        viewModel = createViewModel();
        viewModel.initializeFromExistingRequest(testRequest, testDetails);

        // Allow subjects to propagate
        await Future.delayed(Duration.zero);

        expect(viewModel.contactNameController.text, 'John Doe');
        expect(viewModel.contactEmailController.text, 'john@example.com');
        expect(viewModel.phoneNumberController.text, '123-456-7890');
        expect(viewModel.eventNameContoller.text, 'Test Event');
        expect(viewModel.additionalInfoController.text, 'Test message');
        expect(viewModel.idController.text, 'request1');
      });

      test('text controllers are empty for new request', () async {
        viewModel = createViewModel();
        viewModel.initializeNewRequest(DateTime.now());

        await Future.delayed(Duration.zero);

        expect(viewModel.contactNameController.text, '');
        expect(viewModel.contactEmailController.text, '');
        expect(viewModel.phoneNumberController.text, '');
        expect(viewModel.eventNameContoller.text, '');
        expect(viewModel.additionalInfoController.text, '');
      });

      test('updateEventStart updates the stream', () async {
        viewModel = createViewModel();
        viewModel.initializeFromExistingRequest(testRequest, testDetails);

        final newStart = DateTime(2024, 2, 1, 14, 0);
        viewModel.updateEventStart(newStart);

        final start = await viewModel.eventStartStream.first;
        expect(start, newStart);
      });

      test('updateEventEnd updates the stream', () async {
        viewModel = createViewModel();
        viewModel.initializeFromExistingRequest(testRequest, testDetails);

        final newEnd = DateTime(2024, 2, 1, 16, 0);
        viewModel.updateEventEnd(newEnd);

        final end = await viewModel.eventEndStream.first;
        expect(end, newEnd);
      });

      test('updateRoom updates the stream', () async {
        viewModel = createViewModel();
        viewModel.initializeFromExistingRequest(testRequest, testDetails);
        await Future.delayed(Duration.zero);

        final newRoom = Room(id: 'room2', name: 'New Room');
        viewModel.updateRoom(newRoom);

        final roomID = await viewModel.roomIDStream.first;
        final roomName = await viewModel.roomNameStream.first;
        expect(roomID, 'room2');
        expect(roomName, 'New Room');
      });

      test('updateIsPublic updates the stream', () async {
        viewModel = createViewModel();
        viewModel.initializeFromExistingRequest(testRequest, testDetails);

        viewModel.updateIsPublic(false);
        final isPublic = await viewModel.isPublicStream.first;
        expect(isPublic, false);
      });

      test('updateIgnoreOverlaps updates the stream', () async {
        viewModel = createViewModel();
        viewModel.initializeFromExistingRequest(testRequest, testDetails);

        viewModel.updateIgnoreOverlaps(true);
        final ignoreOverlaps = await viewModel.ignoreOverlapsStream.first;
        expect(ignoreOverlaps, true);
      });

      test('update methods update text controllers', () {
        viewModel = createViewModel();
        viewModel.initializeFromExistingRequest(testRequest, testDetails);

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

        viewModel = createViewModel();
        viewModel.initializeFromExistingRequest(testRequest, testDetails);
        viewModel.useAdminContactInfo();

        expect(viewModel.contactNameController.text, 'Org Admin');
        expect(viewModel.contactEmailController.text, 'admin@test.com');
        expect(viewModel.phoneNumberController.text, 'n/a');
      });

      test('useAdminContactInfo handles null email', () {
        when(() => mockAuthService.getCurrentUserEmail()).thenReturn(null);

        viewModel = createViewModel();
        viewModel.initializeFromExistingRequest(testRequest, testDetails);
        viewModel.useAdminContactInfo();

        expect(viewModel.contactNameController.text, 'Org Admin');
        expect(viewModel.contactEmailController.text, '');
        expect(viewModel.phoneNumberController.text, 'n/a');
      });

      test('Actions contains Add Booking for admin with new request', () async {
        when(() => mockOrgState.currentUserIsAdmin()).thenReturn(true);
        viewModel = createViewModel();
        viewModel.initializeNewRequest(DateTime.now());

        final viewState = await viewModel.viewStateStream.first;
        expect(viewState.actions.any((a) => a.title == 'Add Booking'), true);
      });

      test(
        'Actions contains Submit Request for non-admin with new request',
        () async {
          when(() => mockOrgState.currentUserIsAdmin()).thenReturn(false);
          viewModel = createViewModel();
          viewModel.initializeNewRequest(DateTime.now());

          final viewState = await viewModel.viewStateStream.first;
          expect(
            viewState.actions.any((a) => a.title == 'Submit Request'),
            true,
          );
        },
      );

      test(
        'Actions contains Approve and Reject for pending requests',
        () async {
          final pendingRequest = Request(
            id: 'pending_request',
            eventStartTime: DateTime(2024, 1, 1, 10, 0),
            eventEndTime: DateTime(2024, 1, 1, 11, 0),
            roomID: 'room1',
            roomName: 'Test Room',
            status: RequestStatus.pending,
          );

          viewModel = createViewModel();
          viewModel.initializeFromExistingRequest(pendingRequest, testDetails);

          final viewState = await viewModel.viewStateStream.first;
          final actions = viewState.actions;
          expect(actions.any((a) => a.title == 'Approve'), true);
          expect(actions.any((a) => a.title == 'Reject'), true);
        },
      );

      test(
        'Actions contains Edit for confirmed request in read-only',
        () async {
          final confirmedRequest = Request(
            id: 'confirmed_request',
            eventStartTime: DateTime(2024, 1, 1, 10, 0),
            eventEndTime: DateTime(2024, 1, 1, 11, 0),
            roomID: 'room1',
            roomName: 'Test Room',
            status: RequestStatus.confirmed,
          );

          viewModel = createViewModel();
          viewModel.initializeFromExistingRequest(
            confirmedRequest,
            testDetails,
          );

          final viewState = await viewModel.viewStateStream.first;
          expect(viewState.readOnly, true);
          final actions = viewState.actions;
          expect(actions.any((a) => a.title == 'Edit'), true);
          expect(actions.any((a) => a.title == 'Revisit'), true);
          expect(actions.any((a) => a.title == 'Delete'), true);
        },
      );

      test(
        'Actions contains Save for confirmed request when editing',
        () async {
          final confirmedRequest = Request(
            id: 'confirmed_request',
            eventStartTime: DateTime(2024, 1, 1, 10, 0),
            eventEndTime: DateTime(2024, 1, 1, 11, 0),
            roomID: 'room1',
            roomName: 'Test Room',
            status: RequestStatus.confirmed,
          );

          viewModel = createViewModel();
          viewModel.initializeFromExistingRequest(
            confirmedRequest,
            testDetails,
          );

          // Trigger Edit to switch mode
          var viewState = await viewModel.viewStateStream.first;
          final editAction = viewState.actions.firstWhere(
            (a) => a.title == 'Edit',
          );
          await editAction.onPressed();

          viewState = await viewModel.viewStateStream.first;
          expect(viewState.readOnly, false);
          final actions = viewState.actions;

          expect(actions.any((a) => a.title == 'Save'), true);
          expect(actions.any((a) => a.title == 'Revisit'), true);
          expect(actions.any((a) => a.title == 'Delete'), true);
        },
      );

      test(
        'Actions contains End for confirmed recurring request with end date',
        () async {
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

          viewModel = createViewModel();
          viewModel.initializeFromExistingRequest(
            recurringRequest,
            testDetails,
          );

          final viewState = await viewModel.viewStateStream.first;
          expect(viewState.actions.any((a) => a.title == 'End'), true);
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

          viewModel = createViewModel();
          viewModel.initializeFromExistingRequest(pendingRequest, testDetails);

          final viewState = await viewModel.viewStateStream.first;
          final approveAction = viewState.actions.firstWhere(
            (a) => a.title == 'Approve',
          );

          // Trigger
          await approveAction.onPressed();

          verify(
            () => mockBookingRepo.confirmRequest('test-org', 'pending_request'),
          ).called(1);
          verify(
            () => mockAnalyticsService.logEvent(
              name: 'Booking Approved',
              parameters: {'orgID': 'test-org'},
            ),
          ).called(1);
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

          viewModel = createViewModel();
          viewModel.initializeFromExistingRequest(pendingRequest, testDetails);

          final viewState = await viewModel.viewStateStream.first;
          final rejectAction = viewState.actions.firstWhere(
            (a) => a.title == 'Reject',
          );

          await rejectAction.onPressed();

          verify(
            () => mockBookingRepo.denyRequest('test-org', 'pending_request'),
          ).called(1);
          verify(
            () => mockAnalyticsService.logEvent(
              name: 'Booking Rejected',
              parameters: {'orgID': 'test-org'},
            ),
          ).called(1);
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

          viewModel = createViewModel();
          viewModel.initializeFromExistingRequest(
            confirmedRequest,
            testDetails,
          );

          final viewState = await viewModel.viewStateStream.first;
          final deleteAction = viewState.actions.firstWhere(
            (a) => a.title == 'Delete',
          );

          await deleteAction.onPressed();

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

          viewModel = createViewModel();
          viewModel.initializeFromExistingRequest(
            confirmedRequest,
            testDetails,
          );

          final viewState = await viewModel.viewStateStream.first;
          final revisitAction = viewState.actions.firstWhere(
            (a) => a.title == 'Revisit',
          );

          final result = await revisitAction.onPressed();

          expect(result.message, contains('revisited'));
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

          viewModel = createViewModel();
          viewModel.initializeFromExistingRequest(
            recurringRequest,
            testDetails,
          );
          // Ensure room/start time is available for stream
          viewModel.updateRoom(testRoom);
          await Future.delayed(Duration.zero);

          final viewState = await viewModel.viewStateStream.first;
          final endAction = viewState.actions.firstWhere(
            (a) => a.title == 'End',
          );

          await endAction.onPressed();

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
        });
      });

      test('closeEditor returns empty string', () async {
        viewModel = createViewModel();
        viewModel.initializeFromExistingRequest(testRequest, testDetails);

        final result = await viewModel.closeEditor();
        expect(result, isEmpty);
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

        viewModel = createViewModel();
        viewModel.initializeFromExistingRequest(confirmedRequest, testDetails);

        // Toggle Edit
        var viewState = await viewModel.viewStateStream.first;
        var editAction = viewState.actions.firstWhere((a) => a.title == 'Edit');
        await editAction.onPressed();

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

        viewState = await viewModel.viewStateStream.first;
        final saveAction = viewState.actions.firstWhere(
          (a) => a.title == 'Save',
        );

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

      test('EditorViewState properties for new request (no ID)', () async {
        // Even if user is admin
        when(() => mockOrgState.currentUserIsAdmin()).thenReturn(true);

        viewModel = createViewModel();
        viewModel.initializeNewRequest(DateTime.now());

        final viewState = await viewModel.viewStateStream.first;

        // Should be editable
        expect(viewState.readOnly, false);

        // Should not show ID related fields even if admin
        expect(viewState.showID, false);
        expect(viewState.showIgnoreOverlapsToggle, false);
        expect(viewState.showEventLog, false);
      });
    });
  });
}
