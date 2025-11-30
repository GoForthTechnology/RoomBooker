import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:room_booker/data/entities/organization.dart';
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
  late MockBookingRepo mockBookingRepo;
  late MockLogRepo mockLogRepo;
  late MockRoomState mockRoomState;
  late MockBookingFilterViewModel mockFilterViewModel;
  late BookingListViewModel viewModel;

  final orgID = 'org1';
  final statusList = [RequestStatus.pending];
  final room = Room(name: 'Room A', id: 'room1');
  final request = Request(
    id: 'req1',
    roomID: 'room1',
    roomName: 'Room A',
    eventStartTime: DateTime.now(),
    eventEndTime: DateTime.now().add(Duration(hours: 1)),
    status: RequestStatus.pending,
  );
  final requestDetails = PrivateRequestDetails(
    id: 'req1',
    name: 'John Doe',
    email: 'john@example.com',
    phone: '1234567890',
    eventName: 'Meeting',
  );

  setUp(() {
    mockBookingRepo = MockBookingRepo();
    mockLogRepo = MockLogRepo();
    mockRoomState = MockRoomState();
    mockFilterViewModel = MockBookingFilterViewModel();

    when(() => mockRoomState.enabledValues()).thenReturn({room});
    when(() => mockFilterViewModel.searchQuery).thenReturn('');
    when(() => mockFilterViewModel.addListener(any())).thenReturn(null);
    when(() => mockFilterViewModel.removeListener(any())).thenReturn(null);

    // Default empty stream
    when(
      () => mockBookingRepo.listRequests(
        orgID: any(named: 'orgID'),
        startTime: any(named: 'startTime'),
        endTime: any(named: 'endTime'),
        includeRoomIDs: any(named: 'includeRoomIDs'),
        includeStatuses: any(named: 'includeStatuses'),
      ),
    ).thenAnswer((_) => Stream.value([]));
  });

  test('initializes with empty requests', () async {
    viewModel = BookingListViewModel(
      bookingRepo: mockBookingRepo,
      logRepo: mockLogRepo,
      orgID: orgID,
      statusList: statusList,
      roomState: mockRoomState,
      filterViewModel: mockFilterViewModel,
    );

    expect(await viewModel.renderedRequests.first, isEmpty);
  });

  test('loads requests and details', () async {
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
      () => mockBookingRepo.getRequestDetails(orgID, request.id!),
    ).thenAnswer((_) => Stream.value(requestDetails));

    when(
      () => mockLogRepo.getLogEntries(
        orgID,
        requestIDs: any(named: 'requestIDs'),
      ),
    ).thenAnswer((_) => Stream.value([]));

    viewModel = BookingListViewModel(
      bookingRepo: mockBookingRepo,
      logRepo: mockLogRepo,
      orgID: orgID,
      statusList: statusList,
      roomState: mockRoomState,
      filterViewModel: mockFilterViewModel,
    );

    final rendered = await viewModel.renderedRequests.first;
    expect(rendered.length, 1);
    expect(rendered.first.request, request);
    expect(rendered.first.details, requestDetails);
  });

  test('filters requests by search query', () async {
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
      () => mockBookingRepo.getRequestDetails(orgID, request.id!),
    ).thenAnswer((_) => Stream.value(requestDetails));

    when(
      () => mockLogRepo.getLogEntries(
        orgID,
        requestIDs: any(named: 'requestIDs'),
      ),
    ).thenAnswer((_) => Stream.value([]));

    when(() => mockFilterViewModel.searchQuery).thenReturn('nomatch');

    viewModel = BookingListViewModel(
      bookingRepo: mockBookingRepo,
      logRepo: mockLogRepo,
      orgID: orgID,
      statusList: statusList,
      roomState: mockRoomState,
      filterViewModel: mockFilterViewModel,
    );

    final rendered = await viewModel.renderedRequests.first;
    expect(rendered, isEmpty);
  });

  test('uses overrideRequests if provided', () async {
    viewModel = BookingListViewModel(
      bookingRepo: mockBookingRepo,
      logRepo: mockLogRepo,
      orgID: orgID,
      statusList: statusList,
      roomState: mockRoomState,
      filterViewModel: mockFilterViewModel,
      overrideRequests: [request],
    );

    when(
      () => mockBookingRepo.getRequestDetails(orgID, request.id!),
    ).thenAnswer((_) => Stream.value(requestDetails));

    when(
      () => mockLogRepo.getLogEntries(
        orgID,
        requestIDs: any(named: 'requestIDs'),
      ),
    ).thenAnswer((_) => Stream.value([]));

    final rendered = await viewModel.renderedRequests.first;
    expect(rendered.length, 1);
    expect(rendered.first.request, request);
  });
}
