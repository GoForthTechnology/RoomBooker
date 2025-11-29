import 'package:flutter/material.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/logic/recurring_bookings.dart';
import 'package:rxdart/rxdart.dart';

import 'repeat_bookings_view_model.dart';
import 'repeat_period_selector.dart';
import 'weekday_selector.dart';

class RepeatBookingsSelector extends StatelessWidget {
  final RepeatBookingsViewModel viewModel;

  const RepeatBookingsSelector({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Rx.combineLatest4(
        viewModel.patternStream,
        viewModel.isCustomStream,
        viewModel.startTimeStream,
        viewModel.readOnlyStream,
        (pattern, isCustom, startTime, readOnly) =>
            (pattern, isCustom, startTime, readOnly),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        var (pattern, isCustom, startTime, readOnly) = snapshot.data!;

        return Column(
          children: [
            _frequencySelector(startTime, pattern.frequency, readOnly),
            ..._additionalWidgets(pattern, isCustom, startTime, readOnly),
          ],
        );
      },
    );
  }

  List<Widget> _additionalWidgets(
    RecurrancePattern pattern,
    bool isCustom,
    DateTime startTime,
    bool readOnly,
  ) {
    if (!isCustom || pattern.frequency == Frequency.never) {
      return [];
    }
    var widgets = <Widget>[
      RepeatPeriodSelector(
        frequency: pattern.frequency,
        interval: pattern.period,
        onFrequencyChanged: (value) => viewModel.onFrequencyChanged(value),
        onIntervalChanged: (value) => viewModel.onIntervalChanged(value),
        readOnly: readOnly,
      ),
    ];

    switch (pattern.frequency) {
      case Frequency.daily:
      case Frequency.annually:
        return widgets;
      case Frequency.weekly:
        return widgets +
            [
              WeekdaySelector(
                selectedDays: pattern.weekday ?? {},
                startTime: startTime,
                toggleDay: (day) => viewModel.toggleWeekday(day),
              ),
            ];
      case Frequency.monthly:
        return widgets + [_monthIntervalSelector(startTime)];
      case Frequency.custom:
      case Frequency.never:
        throw Exception("Invalid frequency ${pattern.frequency}");
    }
  }

  Widget _frequencySelector(
    DateTime startTime,
    Frequency frequency,
    bool readOnly,
  ) {
    var patterns = getRecurringBookingOptions(startTime);
    return DropdownButtonFormField<Frequency>(
      key: ValueKey(frequency),
      isExpanded: true,
      initialValue: frequency,
      decoration: const InputDecoration(
        labelText: 'Repeats',
        border: OutlineInputBorder(),
      ),
      items: patterns.entries
          .map(
            (e) => DropdownMenuItem(
              value: e.key,
              child: Text(e.value?.toString() ?? "Custom"),
            ),
          )
          .toList(),
      onChanged: readOnly
          ? null
          : (value) {
              if (value != null) {
                viewModel.onFrequencyChanged(value);
              }
            },
    );
  }

  Widget _monthIntervalSelector(DateTime startTime) {
    var monthlyOccurrence = getMonthlyOccurrence(startTime);
    var weekdayName = getWeekdayName(startTime);
    var options = [
      "Monthly on day ${startTime.day}",
      "Monthly on the $monthlyOccurrence $weekdayName",
    ];
    return DropdownButtonFormField<String>(
      initialValue: options.first,
      decoration: const InputDecoration(
        labelText: 'Repeats',
        border: OutlineInputBorder(),
      ),
      items: options
          .map((o) => DropdownMenuItem(value: o, child: Text(o)))
          .toList(),
      onChanged: (value) {},
    );
  }
}
