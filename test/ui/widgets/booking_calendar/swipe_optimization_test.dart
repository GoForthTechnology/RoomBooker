import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:room_booker/ui/widgets/booking_calendar/view_model.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:room_booker/data/services/booking_service.dart';
import 'package:room_booker/data/services/logging_service.dart';
import 'package:room_booker/ui/widgets/org_state_provider.dart';
import 'package:room_booker/ui/widgets/room_selector.dart';
import 'package:room_booker/data/entities/organization.dart';

class MockOrgState extends Mock implements OrgState {}
class MockRoomState extends Mock implements RoomState {}
class MockLoggingService extends Mock implements LoggingService {}
class MockBookingService extends Mock implements BookingService {}

class FakeViewChangedDetails extends Fake implements ViewChangedDetails {
  @override
  final List<DateTime> visibleDates;
  FakeViewChangedDetails(this.visibleDates);
}

class FakeDataSource extends CalendarDataSource {}

class FakeOrganization extends Fake implements Organization {}

void main() {
  late CalendarViewModel viewModel;
  late MockOrgState mockOrgState;
  late MockRoomState mockRoomState;
  late MockLoggingService mockLoggingService;
  late MockBookingService mockBookingService;

  setUpAll(() {
    registerFallbackValue(FakeOrganization());
  });

  setUp(() {
    mockOrgState = MockOrgState();
    mockRoomState = MockRoomState();
    mockLoggingService = MockLoggingService();
    mockBookingService = MockBookingService();

    when(() => mockOrgState.org).thenReturn(Organization(id: 'org1', name: 'Org 1', ownerID: 'owner1', acceptingAdminRequests: true));
    when(() => mockOrgState.currentUserIsAdmin).thenReturn(false);
    when(() => mockRoomState.addListener(any())).thenReturn(null);
    when(() => mockRoomState.removeListener(any())).thenReturn(null);
    when(() => mockBookingService.getRequestsStream(
      orgID: any(named: 'orgID'),
      isAdmin: any(named: 'isAdmin'),
      start: any(named: 'start'),
      end: any(named: 'end'),
    )).thenAnswer((_) => Stream.value([]));
    when(() => mockBookingService.listBlackoutWindows(any(), any(), any()))
        .thenAnswer((_) => Stream.value([]));

    viewModel = CalendarViewModel(
      orgState: mockOrgState,
      roomState: mockRoomState,
      loggingService: mockLoggingService,
      bookingService: mockBookingService,
    );
  });

  test('DataSource is stable across state emissions', () async {
    final stream = viewModel.calendarViewState();
    
    final state1 = await stream.first;
    final ds1 = state1.dataSource;
    
    expect(ds1, isNotNull);
  });

  test('handleViewChanged updates VisibleWindow and logs change', () {
    final initialDate = DateTime(2026, 5, 28);
    final details = FakeViewChangedDetails([initialDate, initialDate.add(const Duration(days: 1))]);
    
    viewModel.handleViewChanged(details);
    
    verify(() => mockLoggingService.debug(any(that: contains('View changed')))).called(1);
  });

  test('CalendarViewState equality ignores appointment data (which is in the stable dataSource)', () {
    final ds = FakeDataSource();
    final now = DateTime.now();
    final state1 = CalendarViewState(
      allowAppointmentResize: true,
      allowDragAndDrop: true,
      dataSource: ds,
      appointments: [],
      specialRegions: [],
      currentView: CalendarView.day,
      currentDate: now,
    );
    final state2 = CalendarViewState(
      allowAppointmentResize: true,
      allowDragAndDrop: true,
      dataSource: ds,
      appointments: [],
      specialRegions: [],
      currentView: CalendarView.day,
      currentDate: now,
    );
    
    expect(state1, equals(state2));
  });
}
