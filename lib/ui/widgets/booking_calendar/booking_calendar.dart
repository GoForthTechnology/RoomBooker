import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/ui/utils/traced_stream_builder.dart';
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

    return TracedStreamBuilder(
      "render_booking_calendar",
      context.read(),
      stream: viewModel.calendarViewState(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
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
          appointmentBuilder: _appointmentBuilder(
            viewState.currentView,
            viewState.activeRequestID,
          ),
        );
      },
    );
  }

  Widget Function(BuildContext, CalendarAppointmentDetails)?
  _appointmentBuilder(CalendarView view, String? activeRequestID) {
    if (view == CalendarView.schedule) {
      return null;
    }
    return (context, calendarAppointmentDetails) {
      final Appointment appointment =
          calendarAppointmentDetails.appointments.first;
      final bounds = calendarAppointmentDetails.bounds;

      final appointmentID = appointment.resourceIds?.first.toString();
      final isActive =
          activeRequestID != null && appointmentID == activeRequestID;

      Widget content = Text(
        appointment.subject,
        style: const TextStyle(color: Colors.white, fontSize: 10),
        overflow: TextOverflow.ellipsis,
        maxLines: (bounds.height / 15).floor(),
        softWrap: true,
      );

      final tooltipMessage =
          appointment.notes != null && appointment.notes!.isNotEmpty
          ? "${appointment.subject}\n${appointment.notes}"
          : appointment.subject;

      final container = Container(
        decoration: BoxDecoration(
          color: appointment.color,
          borderRadius: BorderRadius.circular(3),
          border: isActive ? Border.all(color: Colors.black, width: 2) : null,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(3),
        alignment: Alignment.topLeft,
        child: content,
      );

      if (isActive) {
        return container;
      }

      return Tooltip(
        message: tooltipMessage,
        waitDuration: const Duration(milliseconds: 500),
        child: container,
      );
    };
  }
}
