import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class PrintService {
  Future<void> printCalendar({
    required List<Request> requests,
    required DateTime targetDate,
    required CalendarView view,
    required String orgName,
    Map<String, String> roomColors = const {},
  }) async {
    final doc = generateDocument(
      requests: requests,
      targetDate: targetDate,
      view: view,
      orgName: orgName,
      roomColors: roomColors,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Calendar_${DateFormat('yyyy-MM-dd').format(targetDate)}',
    );
  }

  pw.Document generateDocument({
    required List<Request> requests,
    required DateTime targetDate,
    required CalendarView view,
    required String orgName,
    Map<String, String> roomColors = const {},
  }) {
    final doc = pw.Document();

    // Filter requests based on the view range
    final visibleRequests = _filterRequestsForView(requests, targetDate, view);

    // Debug logging
    // ignore: avoid_print
    print(
      'PrintService: Received ${requests.length} requests. Visible in view ($view): ${visibleRequests.length}',
    );

    if (view == CalendarView.month ||
        view == CalendarView.schedule ||
        view == CalendarView.week) {
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.letter,
          build: (pw.Context context) {
            return _buildAgendaLayout(visibleRequests, targetDate, orgName);
          },
        ),
      );
    } else {
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.letter,
          build: (pw.Context context) {
            return _buildGridLayout(
              visibleRequests,
              targetDate,
              view,
              orgName,
              roomColors,
            );
          },
        ),
      );
    }
    return doc;
  }

  List<Request> _filterRequestsForView(
    List<Request> requests,
    DateTime targetDate,
    CalendarView view,
  ) {
    DateTime start;
    DateTime end;

    if (view == CalendarView.day) {
      start = DateTime(targetDate.year, targetDate.month, targetDate.day);
      end = start.add(const Duration(days: 1));
    } else if (view == CalendarView.week) {
      // Assuming week starts on Sunday? Syncfusion defaults usually.
      // Let's approximate finding the start of the week.
      // Syncfusion default firstDayOfWeek is Sunday = 7 in Dart? No, DateTime.sunday = 7.
      // Let's assume standard behavior: targetDate might be middle of week.
      // Actually, ViewBookingsViewModel usually passes the "focused date".
      // Let's assume we want to show the week containing targetDate.
      final currentWeekDay = targetDate.weekday; // Mon=1, Sun=7
      // If we want Sunday start:
      final daysToSubtract = currentWeekDay == 7 ? 0 : currentWeekDay;
      start = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
      ).subtract(Duration(days: daysToSubtract));
      end = start.add(const Duration(days: 7));
    } else if (view == CalendarView.month) {
      start = DateTime(targetDate.year, targetDate.month, 1);
      final nextMonth = DateTime(targetDate.year, targetDate.month + 1, 1);
      end = nextMonth;
    } else {
      // Schedule view - treating similar to Month for now based on user plan
      start = DateTime(targetDate.year, targetDate.month, 1);
      final nextMonth = DateTime(targetDate.year, targetDate.month + 1, 1);
      end = nextMonth;
    }

    final expandedRequests = <Request>[];
    for (final r in requests) {
      if (r.isRepeating()) {
        expandedRequests.addAll(r.expand(start, end));
      } else {
        // Simple overlap check for non-repeating
        if (r.eventStartTime.isBefore(end) && r.eventEndTime.isAfter(start)) {
          expandedRequests.add(r);
        }
      }
    }

    return expandedRequests;
  }

  List<pw.Widget> _buildAgendaLayout(
    List<Request> requests,
    DateTime targetDate,
    String orgName,
  ) {
    final dateFormat = DateFormat('EEE, MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    requests.sort((a, b) => a.eventStartTime.compareTo(b.eventStartTime));

    if (requests.isEmpty) {
      return [
        pw.Text(
          'Schedule: ${DateFormat('MMMM yyyy').format(targetDate)}',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          orgName,
          style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'No events to display',
          style: const pw.TextStyle(fontSize: 12),
        ),
      ];
    }

    return [
      pw.Text(
        'Schedule: ${DateFormat('MMMM yyyy').format(targetDate)}',
        style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
      ),
      pw.Text(
        orgName,
        style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
      ),
      pw.SizedBox(height: 20),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300),
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: [
              _tableCell('Date', isHeader: true),
              _tableCell('Time', isHeader: true),
              _tableCell('Event', isHeader: true),
              _tableCell('Room', isHeader: true),
            ],
          ),
          ...requests.map(
            (r) => pw.TableRow(
              children: [
                _tableCell(dateFormat.format(r.eventStartTime)),
                _tableCell(
                  '${timeFormat.format(r.eventStartTime)} - ${timeFormat.format(r.eventEndTime)}',
                ),
                _tableCell(r.publicName ?? 'Private Event'),
                _tableCell(r.roomName),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  pw.Widget _tableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: isHeader ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null,
      ),
    );
  }

  pw.Widget _buildGridLayout(
    List<Request> requests,
    DateTime targetDate,
    CalendarView view,
    String orgName,
    Map<String, String> roomColors,
  ) {
    // This is a simplified "week/day" grid.
    // We assume 8am to 6pm or similar, or 24h?
    // Let's use 8am - 8pm for now or adapt dynamically?
    // For simplicity, let's just do a 24h grid for now or 6am-10pm to fit paper.

    final startHour = 6;
    final endHour = 22;
    final totalHours = endHour - startHour;

    final days = view == CalendarView.day ? 1 : 7;

    // Header dates
    DateTime gridStart;
    if (view == CalendarView.day) {
      gridStart = targetDate;
    } else {
      final currentWeekDay = targetDate.weekday;
      final daysToSubtract = currentWeekDay == 7 ? 0 : currentWeekDay;
      gridStart = targetDate.subtract(Duration(days: daysToSubtract));
    }

    final headers = List.generate(days, (index) {
      final date = gridStart.add(Duration(days: index));
      return DateFormat('EEE d').format(date);
    });

    return pw.Column(
      children: [
        pw.Text(
          '${view == CalendarView.day ? 'Day' : 'Week'} View',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          orgName,
          style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 10),

        // Headers
        pw.Row(
          children: [
            pw.SizedBox(width: 40), // Time labels width
            ...headers.map(
              (h) => pw.Expanded(
                child: pw.Container(
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.only(bottom: 5),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide()),
                  ),
                  child: pw.Text(
                    h,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Grid
        pw.Expanded(
          child: pw.Stack(
            fit: pw.StackFit.expand,
            children: [
              if (requests.isEmpty)
                pw.Center(child: pw.Text("No events to display")),
              // Let's re-think grid.
              // Background Lines
              pw.Column(
                children: List.generate(
                  totalHours,
                  (index) => pw.Expanded(
                    child: pw.Container(
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(
                            color: PdfColors.grey300,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: pw.Row(
                        children: [
                          pw.SizedBox(
                            width: 40,
                            child: pw.Text(
                              '${index + startHour}:00',
                              style: const pw.TextStyle(
                                fontSize: 8,
                                color: PdfColors.grey,
                              ),
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Container(
                              decoration: const pw.BoxDecoration(
                                border: pw.Border(
                                  left: pw.BorderSide(
                                    color: PdfColors.grey300,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Events
              pw.LayoutBuilder(
                builder: (context, constraints) {
                  final height = constraints?.maxHeight ?? 500;
                  final width = constraints?.maxWidth ?? 500;
                  final timeColumnWidth = 40.0;
                  final dayWidth = (width - timeColumnWidth) / days;

                  final dayWidgets = <pw.Widget>[];

                  for (int day = 0; day < days; day++) {
                    final currentDayStart = gridStart.add(Duration(days: day));
                    // Determine the day range for filtering
                    final dayRecStart = DateTime(
                      currentDayStart.year,
                      currentDayStart.month,
                      currentDayStart.day,
                    );
                    final dayRecEnd = dayRecStart.add(const Duration(days: 1));

                    // 1. Filter and sort events for this day
                    final dayRequests =
                        requests.where((r) {
                          return r.eventStartTime.isBefore(dayRecEnd) &&
                              r.eventEndTime.isAfter(dayRecStart);
                        }).toList()..sort(
                          (a, b) =>
                              a.eventStartTime.compareTo(b.eventStartTime),
                        );

                    if (dayRequests.isEmpty) continue;

                    // 2. Cluster overlapping events
                    // A cluster is a group of events that transitively overlap.
                    List<List<Request>> clusters = [];
                    if (dayRequests.isNotEmpty) {
                      List<Request> currentCluster = [dayRequests.first];
                      DateTime clusterEnd = dayRequests.first.eventEndTime;

                      for (int i = 1; i < dayRequests.length; i++) {
                        final req = dayRequests[i];
                        if (req.eventStartTime.isBefore(clusterEnd)) {
                          currentCluster.add(req);
                          if (req.eventEndTime.isAfter(clusterEnd)) {
                            clusterEnd = req.eventEndTime;
                          }
                        } else {
                          clusters.add(currentCluster);
                          currentCluster = [req];
                          clusterEnd = req.eventEndTime;
                        }
                      }
                      clusters.add(currentCluster);
                    }

                    // 3. Layout each cluster
                    for (final cluster in clusters) {
                      // "Pack" events into columns
                      // columns store the end time of the last event in that column
                      List<DateTime> columns = [];
                      Map<Request, int> assignments = {};

                      for (final req in cluster) {
                        int assignedCol = -1;
                        for (int c = 0; c < columns.length; c++) {
                          if (!columns[c].isAfter(req.eventStartTime)) {
                            assignedCol = c;
                            columns[c] = req.eventEndTime;
                            break;
                          }
                        }
                        if (assignedCol == -1) {
                          columns.add(req.eventEndTime);
                          assignedCol = columns.length - 1;
                        }
                        assignments[req] = assignedCol;
                      }

                      final maxCols = columns.length;
                      final colWidthFactor = 1.0 / maxCols;

                      for (final req in cluster) {
                        final colIndex = assignments[req]!;

                        // Calculate geometry
                        final rSta = req.eventStartTime;

                        // Handles events spanning midnight slightly by clamping or purely based on hour
                        // (Simple assumption: event is mostly on this day)

                        final double startMetric =
                            (rSta.hour + rSta.minute / 60.0) - startHour;
                        final double endMetric =
                            (req.eventEndTime.hour +
                                req.eventEndTime.minute / 60.0) -
                            startHour;

                        final effectiveStart = startMetric < 0
                            ? 0
                            : startMetric;
                        var effectiveEnd = endMetric > totalHours
                            ? totalHours
                            : endMetric;

                        if (effectiveEnd <= effectiveStart) {
                          // Minimal height for visibility?
                          effectiveEnd = effectiveStart + 0.25;
                        }

                        final top = (effectiveStart / totalHours) * height;
                        final bottom = (effectiveEnd / totalHours) * height;
                        final itemHeight = bottom - top;

                        // base Left for the day
                        final dayLeft = timeColumnWidth + (day * dayWidth);
                        // offset within day
                        final subLeft = colIndex * colWidthFactor * dayWidth;

                        final finalLeft = dayLeft + subLeft;
                        final finalWidth = dayWidth * colWidthFactor;

                        dayWidgets.add(
                          pw.Positioned(
                            left: finalLeft,
                            top: top,
                            child: pw.Container(
                              width: finalWidth,
                              height: itemHeight,
                              margin: const pw.EdgeInsets.all(1),
                              padding: const pw.EdgeInsets.all(2),
                              decoration: pw.BoxDecoration(
                                color: _colorFromHex(
                                  roomColors[req.roomID] ?? "#ADD8E6",
                                ),
                                borderRadius: pw.BorderRadius.circular(2),
                              ),
                              child: pw.Stack(
                                children: [
                                  pw.Align(
                                    alignment: pw.Alignment.topLeft,
                                    child: pw.Text(
                                      req.publicName ?? 'Private',
                                      style: const pw.TextStyle(
                                        fontSize: 8,
                                        color: PdfColors.white,
                                      ),
                                      overflow: pw.TextOverflow.clip,
                                    ),
                                  ),
                                  if (itemHeight > 15 &&
                                      finalWidth >
                                          30) // Only show if space permits
                                    pw.Align(
                                      alignment: pw.Alignment.bottomRight,
                                      child: pw.Text(
                                        req.roomName,
                                        style: const pw.TextStyle(
                                          fontSize: 6,
                                          color: PdfColors.white,
                                        ),
                                        overflow: pw.TextOverflow.clip,
                                        textAlign: pw.TextAlign.right,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                    }
                  }

                  return pw.Stack(children: dayWidgets);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  PdfColor _colorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    if (hexColor.length == 8) {
      return PdfColor.fromInt(int.parse(hexColor, radix: 16));
    }
    return PdfColors.blue100; // Fallback
  }
}
