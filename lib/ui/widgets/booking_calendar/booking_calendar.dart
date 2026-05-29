import 'dart:math' as math;

import 'package:flutter/foundation.dart';
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
      stream: viewModel.calendarViewState().distinct((prev, curr) {
        // We want to avoid rebuilding SfCalendar when the user is just swiping
        // within the same view, because SfCalendar handles its own scrolling
        // and we have pre-filled the data source with padded data.
        
        // Rebuild ONLY if:
        return prev.allowAppointmentResize == curr.allowAppointmentResize &&
            prev.allowDragAndDrop == curr.allowDragAndDrop &&
            prev.dataSource == curr.dataSource &&
            // Note: appointments change is handled by DataSource.notifyListeners,
            // so we don't need to rebuild SfCalendar when only appointments change.
            // listEquals(prev.appointments, curr.appointments) && 
            listEquals(prev.specialRegions, curr.specialRegions) &&
            prev.currentView == curr.currentView &&
            prev.activeRequestID == curr.activeRequestID;
            // currentDate change is handled by CalendarController, no need to rebuild.
      }),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        var viewState = snapshot.data!;
        return SfCalendar(
          onViewChanged: viewModel.handleViewChanged,
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
        maxLines: math.max(1, (bounds.height / 15).floor()),
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
