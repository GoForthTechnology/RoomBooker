import 'dart:developer';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:roombooker_core/data/entities/log_entry.dart';
import 'package:roombooker_core/data/entities/organization.dart';
import 'package:roombooker_core/data/entities/request.dart';
import 'package:roombooker_core/data/services/booking_service.dart';
import 'package:roombooker_core/data/repos/log_repo.dart';
import 'package:roombooker_portal/router.dart';
import 'package:roombooker_portal/ui/widgets/request_logs_controller.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class RequestLogsWidget extends StatelessWidget {
  final Organization org;
  final String? requestID;
  final bool allowPagination;
  final bool showViewButton;
  final Widget Function(RequestLogEntry)? titleBuilder;
  final Widget Function(RequestLogEntry)? subtitleBuilder;

  const RequestLogsWidget({
    super.key,
    required this.org,
    this.requestID,
    required this.allowPagination,
    this.titleBuilder,
    this.subtitleBuilder,
    this.showViewButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => RequestLogsController(
        logRepo: Provider.of<LogRepo>(context, listen: false),
        bookingService: Provider.of<BookingService>(context, listen: false),
        orgID: org.id!,
        requestID: requestID,
      ),
      child: Consumer<RequestLogsController>(
        builder: (context, controller, child) {
          if (controller.error != null) {
            log("Error loading request logs: ${controller.error}");
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${controller.error}')),
              );
            });
            return const Text('Error loading request logs');
          }

          if (controller.logs.isEmpty && !controller.isLoading) {
            return const Text('No request logs found');
          }

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Column(
              key: ValueKey(controller.isLoading),
              children: [
                _logView(context, controller),
                if (allowPagination) _paginationControls(controller),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getActorEmail(DecoratedLogEntry log) {
    const requesterActions = {Action.create, Action.request};
    final action = log.entry.action;
    final adminEmail = log.entry.adminEmail;

    if (requesterActions.contains(action)) {
      return log.details.email;
    }

    if (log.request.bookedVia == BookingSource.kiosk) {
      return "Booked via Kiosk";
    }

    // For admin actions, use adminEmail if present, otherwise fallback
    return adminEmail ?? log.details.email;
  }

  Widget _logView(BuildContext context, RequestLogsController controller) {
    final logs = controller.logs;
    final isLoading = controller.isLoading;

    return Stack(
      children: [
        Opacity(
          opacity: isLoading ? 0.6 : 1.0,
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              var log = logs[index];
              Widget? trailing;
              if (showViewButton && log.entry.action != Action.delete) {
                trailing = TextButton(
                  onPressed: () {
                    AutoRouter.of(context).push(
                      ViewBookingsRoute(
                        orgID: org.id!,
                        requestID: log.entry.requestID,
                        targetDateStr: DateFormat(
                          "yyyy-MM-dd",
                        ).format(log.request.eventStartTime),
                        view: CalendarView.day.name,
                      ),
                    );
                  },
                  child: Text("VIEW"),
                );
              }
              final actorEmail = _getActorEmail(log);
              Widget title = titleBuilder != null
                  ? titleBuilder!(log.entry)
                  : Text("$actorEmail - ${log.entry.action.name}");
              Widget subtitle = subtitleBuilder != null
                  ? subtitleBuilder!(log.entry)
                  : Text(
                      "${log.details.eventName} @ ${log.entry.timestamp.toIso8601String()}",
                    );
              return Tooltip(
                message: log.entry.requestID,
                child: ListTile(
                  title: title,
                  subtitle: subtitle,
                  trailing: trailing,
                ),
              );
            },
          ),
        ),
        if (isLoading)
          Positioned.fill(
            child: Container(
              alignment: Alignment.center,
              child: const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _paginationControls(RequestLogsController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Spacer(),
        IconButton(
          onPressed: (!controller.canGoBack || controller.isLoading)
              ? null
              : controller.previousPage,
          icon: const Icon(Icons.arrow_left),
        ),
        DropdownButton<int>(
          value: controller.recordsPerPage,
          items: RequestLogsController.recordsPerPageOptions
              .map(
                (value) => DropdownMenuItem<int>(
                  value: value,
                  child: Text('$value per page'),
                ),
              )
              .toList(),
          onChanged: controller.isLoading
              ? null
              : (value) {
                  if (value != null) {
                    controller.setRecordsPerPage(value);
                  }
                },
        ),
        IconButton(
          onPressed: (controller.isLoading || controller.logs.isEmpty)
              ? null
              : controller.nextPage,
          icon: const Icon(Icons.arrow_right),
        ),
      ],
    );
  }
}
