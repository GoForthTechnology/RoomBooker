import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/ui/widgets/booking_calendar/view_model.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class BookingCalendar extends StatelessWidget {
  final CalendarViewModel Function() createViewModel;

  const BookingCalendar({super.key, required this.createViewModel});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => createViewModel(),
      child: BookingCalendarView(),
    );
  }
}

class BookingCalendarView extends StatelessWidget {
  const BookingCalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CalendarViewModel>();

    return StreamBuilder(
      stream: viewModel.calendarViewState(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }
        var viewState = snapshot.data!;
        return SfCalendar(
          cellEndPadding: 20,
          allowViewNavigation: viewModel.allowViewNavigation,
          controller: viewModel.controller,
          minDate: viewModel.minDate,
          showNavigationArrow: viewModel.showNavigationArrow,
          showTodayButton: viewModel.showTodayButton,
          showDatePickerButton: viewModel.showDatePickerButton,
          allowedViews: viewModel.allowedViews,
          allowDragAndDrop: viewState.allowDragAndDrop,
          allowAppointmentResize: viewState.allowAppointmentResize,
          onAppointmentResizeEnd: viewModel.handleResizeEnd,
          onDragEnd: viewModel.handleDragEnd,
          onTap: viewModel.handleTap,
          specialRegions: viewState.specialRegions,
          dataSource: viewState.dataSource,
          appointmentBuilder: (context, calendarAppointmentDetails) {
            final Appointment appointment =
                calendarAppointmentDetails.appointments.first;
            return Tooltip(
              message: appointment.notes ?? '',
              waitDuration: const Duration(milliseconds: 500),
              child: Container(
                decoration: BoxDecoration(
                  color: appointment.color,
                  borderRadius: BorderRadius.circular(3),
                ),
                padding: const EdgeInsets.all(3),
                child: Text(
                  appointment.subject,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
