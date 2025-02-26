import 'package:flutter/material.dart';
import 'package:room_booker/entities/request.dart';
import 'package:room_booker/logic/recurring_bookings.dart';
import 'package:room_booker/widgets/repeat_period_selector.dart';
import 'package:room_booker/widgets/weekday_selector.dart';

class RepeatBookingsSelector extends StatelessWidget {
  final DateTime startTime;
  final Frequency frequency;
  final RecurrancePattern pattern;
  final bool isCustom;
  final bool readOnly;
  final Function(Frequency) onFrequencyChanged;
  final Function(int) onIntervalChanged;
  final Function(RecurrancePattern, bool) onPatternChanged;
  final Function(Weekday) toggleDay;

  const RepeatBookingsSelector(
      {super.key,
      required this.startTime,
      required this.onFrequencyChanged,
      required this.onPatternChanged,
      required this.frequency,
      required this.isCustom,
      required this.toggleDay,
      required this.pattern,
      required this.onIntervalChanged,
      required this.readOnly});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _frequencySelector(),
        ..._additionalWidgets(),
      ],
    );
  }

  List<Widget> _additionalWidgets() {
    if (!isCustom || pattern.frequency == Frequency.never) {
      return [];
    }
    var widgets = <Widget>[
      RepeatPeriodSelector(
        frequency: pattern.frequency,
        onFrequencyChanged: (value) => onFrequencyChanged(value),
        onIntervalChanged: (value) => onIntervalChanged(value),
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
                toggleDay: toggleDay,
              )
            ];
      case Frequency.monthly:
        return widgets + [_monthIntervalSelector()];
      case Frequency.custom:
      case Frequency.never:
        throw Exception("Invalid frequency ${pattern.frequency}");
    }
  }

  Widget _frequencySelector() {
    var patterns = getRecurringBookingOptions(startTime);
    return DropdownButtonFormField<Frequency>(
      isExpanded: true,
      value: Frequency.never,
      decoration: const InputDecoration(
        labelText: 'Repeats',
        border: OutlineInputBorder(),
      ),
      items: patterns.entries
          .map((e) => DropdownMenuItem(
                value: e.key,
                child: Text(e.value?.toString() ?? "Custom"),
              ))
          .toList(),
      onChanged: readOnly
          ? null
          : (value) {
              if (value == Frequency.custom) {
                onFrequencyChanged(value!);
                return;
              }
              var pattern = patterns[value];
              if (pattern != null) {
                onPatternChanged(pattern, false);
              }
            },
    );
  }

  Widget _monthIntervalSelector() {
    var monthlyOccurrence = getMonthlyOccurrence(startTime);
    var weekdayName = getWeekdayName(startTime);
    var options = [
      "Monthly on day ${startTime.day}",
      "Monthly on the $monthlyOccurrence $weekdayName",
    ];
    return DropdownButtonFormField<String>(
      value: options.first,
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
