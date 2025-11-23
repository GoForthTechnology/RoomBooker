import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/data/repos/log_repo.dart';
import 'package:room_booker/ui/widgets/booking_list/booking_filter_view_model.dart';
import 'package:room_booker/ui/widgets/booking_list/booking_list_view_model.dart';
import 'package:room_booker/ui/widgets/room_selector.dart';

class MockBookingRepo extends Mock implements BookingRepo {}

class MockLogRepo extends Mock implements LogRepo {}

class MockRoomState extends Mock implements RoomState {}

class MockBookingFilterViewModel extends Mock
    implements BookingFilterViewModel {}

void main() {
  late BookingListViewModel viewModel;
  late MockBookingRepo mockBookingRepo;
  late MockLogRepo mockLogRepo;
  late MockRoomState mockRoomState;
  late MockBookingFilterViewModel mockBookingFilterViewModel;

  setUp(() {
    mockBookingRepo = MockBookingRepo();
    mockLogRepo = MockLogRepo();
    mockRoomState = MockRoomState();
    mockBookingFilterViewModel = MockBookingFilterViewModel();

    when(() => mockBookingFilterViewModel.searchQuery).thenReturn('');
    when(
      () => mockBookingFilterViewModel.addListener(any()),
    ).thenAnswer((_) {});
  });

  group('BookingListViewModel', () {
    test('initializes with empty list of requests', () {
      // Arrange
      when(
        () => mockBookingRepo.listRequests(
          orgID: any(named: 'orgID'),
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
          includeRoomIDs: any(named: 'includeRoomIDs'),
          includeStatuses: any(named: 'includeStatuses'),
        ),
      ).thenAnswer((_) => Stream.value([]));
      when(() => mockRoomState.enabledValues()).thenReturn({});

      // Act
      viewModel = BookingListViewModel(
        bookingRepo: mockBookingRepo,
        logRepo: mockLogRepo,
        orgID: 'org_id',
        statusList: [RequestStatus.pending],
        roomState: mockRoomState,
        filterViewModel: mockBookingFilterViewModel,
      );

      // Assert
      expect(viewModel.renderedRequests, emits([]));
    });

    test('emits rendered requests', () {
      // Arrange
      final request = Request(
        id: 'req_1',
        roomID: 'room_1',
        eventStartTime: DateTime.now(),
        eventEndTime: DateTime.now().add(const Duration(hours: 1)),
        status: RequestStatus.confirmed,
        roomName: 'Test Room',
      );
      final details = PrivateRequestDetails(
        id: 'req_1',
        eventName: 'Test Event',
        name: 'Test User',
        email: 'test@test.com',
        phone: '12345',
      );

      when(
        () => mockBookingRepo.listRequests(
          orgID: any(named: 'orgID'),
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
          includeRoomIDs: any(named: 'includeRoomIDs'),
          includeStatuses: any(named: 'includeStatuses'),
        ),
      ).thenAnswer((_) => Stream.value([request]));
      when(
        () => mockBookingRepo.getRequestDetails('org_id', 'req_1'),
      ).thenAnswer((_) => Stream.value(details));
      when(
        () => mockLogRepo.getLogEntries('org_id', requestIDs: {'req_1'}),
      ).thenAnswer((_) => Stream.value([]));
      when(() => mockRoomState.enabledValues()).thenReturn({});

      // Act
      viewModel = BookingListViewModel(
        bookingRepo: mockBookingRepo,
        logRepo: mockLogRepo,
        orgID: 'org_id',
        statusList: [RequestStatus.confirmed],
        roomState: mockRoomState,
        filterViewModel: mockBookingFilterViewModel,
      );

      // Assert
      expect(
        viewModel.renderedRequests,
        emits(
          isA<List<RenderedRequest>>().having((p0) => p0.length, 'length', 1),
        ),
      );
    });

    test('filters requests by eventName', () async {
      // Arrange
      final request1 = Request(
        id: 'req_1',
        roomID: 'room_1',
        eventStartTime: DateTime.now(),
        eventEndTime: DateTime.now().add(const Duration(hours: 1)),
        status: RequestStatus.confirmed,
        roomName: 'Room A',
      );
      final request2 = Request(
        id: 'req_2',
        roomID: 'room_2',
        eventStartTime: DateTime.now(),
        eventEndTime: DateTime.now().add(const Duration(hours: 1)),
        status: RequestStatus.confirmed,
        roomName: 'Room B',
      );
      final details1 = PrivateRequestDetails(
        id: 'req_1',
        eventName: 'Meeting with John',
        name: 'Test User',
        email: 'test@test.com',
        phone: '12345',
      );
      final details2 = PrivateRequestDetails(
        id: 'req_2',
        eventName: 'Team Sync',
        name: 'Test User',
        email: 'test@test.com',
        phone: '12345',
      );

      when(
        () => mockBookingRepo.listRequests(
          orgID: any(named: 'orgID'),
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
          includeRoomIDs: any(named: 'includeRoomIDs'),
          includeStatuses: any(named: 'includeStatuses'),
        ),
      ).thenAnswer((_) => Stream.value([request1, request2]));
      when(
        () => mockBookingRepo.getRequestDetails('org_id', 'req_1'),
      ).thenAnswer((_) => Stream.value(details1));
      when(
        () => mockBookingRepo.getRequestDetails('org_id', 'req_2'),
      ).thenAnswer((_) => Stream.value(details2));
      when(
        () => mockLogRepo.getLogEntries('org_id', requestIDs: {'req_1'}),
      ).thenAnswer((_) => Stream.value([]));
      when(
        () => mockLogRepo.getLogEntries('org_id', requestIDs: {'req_2'}),
      ).thenAnswer((_) => Stream.value([]));
      when(() => mockRoomState.enabledValues()).thenReturn({});
      when(() => mockBookingFilterViewModel.searchQuery).thenReturn('john');

      // Act
      viewModel = BookingListViewModel(
        bookingRepo: mockBookingRepo,
        logRepo: mockLogRepo,
        orgID: 'org_id',
        statusList: [RequestStatus.confirmed],
        roomState: mockRoomState,
        filterViewModel: mockBookingFilterViewModel,
      );

      // Assert
      await expectLater(
        viewModel.renderedRequests,
        emits(
          isA<List<RenderedRequest>>()
              .having((p0) => p0.length, 'length', 1)
              .having((p0) => p0.first.request.id, 'first request id', 'req_1'),
        ),
      );
    });

    test('filters requests by roomName', () async {
      // Arrange
      final request1 = Request(
        id: 'req_1',
        roomID: 'room_1',
        eventStartTime: DateTime.now(),
        eventEndTime: DateTime.now().add(const Duration(hours: 1)),
        status: RequestStatus.confirmed,
        roomName: 'Room A',
      );
      final request2 = Request(
        id: 'req_2',
        roomID: 'room_2',
        eventStartTime: DateTime.now(),
        eventEndTime: DateTime.now().add(const Duration(hours: 1)),
        status: RequestStatus.confirmed,
        roomName: 'Room B',
      );
      final details1 = PrivateRequestDetails(
        id: 'req_1',
        eventName: 'Meeting with John',
        name: 'Test User',
        email: 'test@test.com',
        phone: '12345',
      );
      final details2 = PrivateRequestDetails(
        id: 'req_2',
        eventName: 'Team Sync',
        name: 'Test User',
        email: 'test@test.com',
        phone: '12345',
      );

      when(
        () => mockBookingRepo.listRequests(
          orgID: any(named: 'orgID'),
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
          includeRoomIDs: any(named: 'includeRoomIDs'),
          includeStatuses: any(named: 'includeStatuses'),
        ),
      ).thenAnswer((_) => Stream.value([request1, request2]));
      when(
        () => mockBookingRepo.getRequestDetails('org_id', 'req_1'),
      ).thenAnswer((_) => Stream.value(details1));
      when(
        () => mockBookingRepo.getRequestDetails('org_id', 'req_2'),
      ).thenAnswer((_) => Stream.value(details2));
      when(
        () => mockLogRepo.getLogEntries('org_id', requestIDs: {'req_1'}),
      ).thenAnswer((_) => Stream.value([]));
      when(
        () => mockLogRepo.getLogEntries('org_id', requestIDs: {'req_2'}),
      ).thenAnswer((_) => Stream.value([]));
      when(() => mockRoomState.enabledValues()).thenReturn({});
      when(() => mockBookingFilterViewModel.searchQuery).thenReturn('room a');

      // Act
      viewModel = BookingListViewModel(
        bookingRepo: mockBookingRepo,
        logRepo: mockLogRepo,
        orgID: 'org_id',
        statusList: [RequestStatus.confirmed],
        roomState: mockRoomState,
        filterViewModel: mockBookingFilterViewModel,
      );

      // Assert
      await expectLater(
        viewModel.renderedRequests,
        emits(
          isA<List<RenderedRequest>>()
              .having((p0) => p0.length, 'length', 1)
              .having((p0) => p0.first.request.id, 'first request id', 'req_1'),
        ),
      );
    });

    test('uses override requests', () {
      // Arrange
      final request1 = Request(
        id: 'req_1',
        roomID: 'room_1',
        eventStartTime: DateTime.now(),
        eventEndTime: DateTime.now().add(const Duration(hours: 1)),
        status: RequestStatus.confirmed,
        roomName: 'Test Room',
      );
      final details1 = PrivateRequestDetails(
        id: 'req_1',
        eventName: 'Test Event 1',
        name: 'Test User',
        email: 'test@test.com',
        phone: '12345',
      );

      when(
        () => mockBookingRepo.getRequestDetails('org_id', 'req_1'),
      ).thenAnswer((_) => Stream.value(details1));
      when(
        () => mockLogRepo.getLogEntries('org_id', requestIDs: {'req_1'}),
      ).thenAnswer((_) => Stream.value([]));
      when(() => mockRoomState.enabledValues()).thenReturn({});

      // Act
      viewModel = BookingListViewModel(
        bookingRepo: mockBookingRepo,
        logRepo: mockLogRepo,
        orgID: 'org_id',
        statusList: [RequestStatus.confirmed],
        roomState: mockRoomState,
        overrideRequests: [request1],
        filterViewModel: mockBookingFilterViewModel,
      );

      // Assert
      expect(
        viewModel.renderedRequests,
        emits(
          isA<List<RenderedRequest>>().having((p0) => p0.length, 'length', 1),
        ),
      );
      verifyNever(
        () => mockBookingRepo.listRequests(
          orgID: any(named: 'orgID'),
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
          includeRoomIDs: any(named: 'includeRoomIDs'),
          includeStatuses: any(named: 'includeStatuses'),
        ),
      );
    });

    test('sorts requests by event start time', () {
      // Arrange
      final request1 = Request(
        id: 'req_1',
        roomID: 'room_1',
        eventStartTime: DateTime.now().add(const Duration(hours: 1)),
        eventEndTime: DateTime.now().add(const Duration(hours: 2)),
        status: RequestStatus.confirmed,
        roomName: 'Test Room',
      );
      final request2 = Request(
        id: 'req_2',
        roomID: 'room_2',
        eventStartTime: DateTime.now(),
        eventEndTime: DateTime.now().add(const Duration(hours: 1)),
        status: RequestStatus.confirmed,
        roomName: 'Test Room',
      );
      final details1 = PrivateRequestDetails(
        id: 'req_1',
        eventName: 'Test Event 1',
        name: 'Test User',
        email: 'test@test.com',
        phone: '12345',
      );
      final details2 = PrivateRequestDetails(
        id: 'req_2',
        eventName: 'Test Event 2',
        name: 'Test User',
        email: 'test@test.com',
        phone: '12345',
      );

      when(
        () => mockBookingRepo.listRequests(
          orgID: any(named: 'orgID'),
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
          includeRoomIDs: any(named: 'includeRoomIDs'),
          includeStatuses: any(named: 'includeStatuses'),
        ),
      ).thenAnswer((_) => Stream.value([request1, request2]));
      when(
        () => mockBookingRepo.getRequestDetails('org_id', 'req_1'),
      ).thenAnswer((_) => Stream.value(details1));
      when(
        () => mockBookingRepo.getRequestDetails('org_id', 'req_2'),
      ).thenAnswer((_) => Stream.value(details2));
      when(
        () => mockLogRepo.getLogEntries('org_id', requestIDs: {'req_1'}),
      ).thenAnswer((_) => Stream.value([]));
      when(
        () => mockLogRepo.getLogEntries('org_id', requestIDs: {'req_2'}),
      ).thenAnswer((_) => Stream.value([]));
      when(() => mockRoomState.enabledValues()).thenReturn({});

      // Act
      viewModel = BookingListViewModel(
        bookingRepo: mockBookingRepo,
        logRepo: mockLogRepo,
        orgID: 'org_id',
        statusList: [RequestStatus.confirmed],
        roomState: mockRoomState,
        filterViewModel: mockBookingFilterViewModel,
      );

      // Assert
      expect(
        viewModel.renderedRequests,
        emits(
          isA<List<RenderedRequest>>()
              .having((p0) => p0.length, 'length', 2)
              .having((p0) => p0[0].request.id, 'first request id', 'req_2')
              .having((p0) => p0[1].request.id, 'second request id', 'req_1'),
        ),
      );
    });
  });
}
