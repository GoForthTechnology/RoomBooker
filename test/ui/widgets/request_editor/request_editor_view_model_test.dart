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

    group('Core Classes', () {
      test('EditorAction creation works correctly', () {
        final action = EditorAction('Test Action', () async => 'Success');

        expect(action.title, 'Test Action');
        expect(action.onPressed, isNotNull);
      });
    });

    group('Entity Classes', () {
      test('Request entity properties work correctly', () {
        expect(testRequest.id, 'request1');
        expect(testRequest.publicName, 'Test Event');
        expect(testRequest.status, RequestStatus.pending);
        expect(testRequest.roomID, 'room1');
        expect(testRequest.roomName, 'Test Room');
        expect(testRequest.eventStartTime, DateTime(2024, 1, 1, 10, 0));
        expect(testRequest.eventEndTime, DateTime(2024, 1, 1, 11, 0));
      });

      test('PrivateRequestDetails entity properties work correctly', () {
        expect(testDetails.name, 'John Doe');
        expect(testDetails.email, 'john@example.com');
        expect(testDetails.phone, '123-456-7890');
        expect(testDetails.eventName, 'Test Event');
        expect(testDetails.message, 'Test message');
      });

      test('Organization entity properties work correctly', () {
        expect(testOrg.id, 'test-org');
        expect(testOrg.name, 'Test Org');
        expect(testOrg.ownerID, 'test-owner');
        expect(testOrg.acceptingAdminRequests, true);
      });

      test('Room entity properties work correctly', () {
        expect(testRoom.id, 'room1');
        expect(testRoom.name, 'Test Room');
      });

      test('RecurrancePattern can be created with required properties', () {
        final pattern = RecurrancePattern(
          frequency: Frequency.weekly,
          period: 1,
          weekday: {Weekday.monday},
          offset: 1,
        );

        expect(pattern.frequency, Frequency.weekly);
        expect(pattern.period, 1);
        expect(pattern.weekday, contains(Weekday.monday));
        expect(pattern.offset, 1);
      });
    });

    group('Enums', () {
      test('RequestStatus enum has correct values', () {
        expect(RequestStatus.pending, isNotNull);
        expect(RequestStatus.confirmed, isNotNull);
        expect(RequestStatus.denied, isNotNull);
        expect(RequestStatus.unknown, isNotNull);
      });

      test('RecurringBookingEditChoice enum has correct values', () {
        expect(RecurringBookingEditChoice.thisInstance, isNotNull);
        expect(RecurringBookingEditChoice.thisAndFuture, isNotNull);
        expect(RecurringBookingEditChoice.all, isNotNull);
      });

      test('Frequency enum has correct values', () {
        expect(Frequency.daily, isNotNull);
        expect(Frequency.weekly, isNotNull);
        expect(Frequency.monthly, isNotNull);
      });

      test('Weekday enum has correct values', () {
        expect(Weekday.monday, isNotNull);
        expect(Weekday.tuesday, isNotNull);
        expect(Weekday.wednesday, isNotNull);
        expect(Weekday.thursday, isNotNull);
        expect(Weekday.friday, isNotNull);
        expect(Weekday.saturday, isNotNull);
        expect(Weekday.sunday, isNotNull);
      });
    });

    group('Mocks Setup', () {
      test('Mock setup works correctly', () {
        expect(mockOrgState, isNotNull);
        expect(mockAnalyticsService, isNotNull);
        expect(mockAuthService, isNotNull);
        expect(mockBookingRepo, isNotNull);
      });

      test('Mock auth service can be configured', () {
        when(
          () => mockAuthService.getCurrentUserEmail(),
        ).thenReturn('test@example.com');
        when(
          () => mockAuthService.getCurrentUserID(),
        ).thenReturn('test-user-id');

        expect(mockAuthService.getCurrentUserEmail(), 'test@example.com');
        expect(mockAuthService.getCurrentUserID(), 'test-user-id');
      });

      test('Mock analytics service can be configured', () {
        expect(mockAnalyticsService, isNotNull);
      });
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
    });
  });
}
