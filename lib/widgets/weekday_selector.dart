// ignore_for_file: library_private_types_in_public_api

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:room_booker/entities/request.dart';

class WeekdaySelector extends StatelessWidget {
  final DateTime startTime;
  final Set<Weekday> selectedDays;
  final Function(Weekday) toggleDay;
  const WeekdaySelector(
      {super.key,
      required this.startTime,
      required this.toggleDay,
      required this.selectedDays});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: InputDecorator(
            decoration: const InputDecoration(
              labelText: "Repeats on",
              border: OutlineInputBorder(),
            ),
            child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: Weekday.values.mapIndexed(
                    (i, value) {
                      return DayButton(
                        label: _getDayLabel(i),
                        selected: selectedDays.contains(value),
                        onPressed: () => toggleDay(value),
                      );
                    },
                  ).toList(),
                ))));
  }

  String _getDayLabel(int index) {
    switch (index) {
      case 0:
        return 'S';
      case 1:
        return 'M';
      case 2:
        return 'T';
      case 3:
        return 'W';
      case 4:
        return 'T';
      case 5:
        return 'F';
      case 6:
        return 'S';
      default:
        return '';
    }
  }
}

class DayButton extends StatelessWidget {
  final String label;
  final bool selected;
  final void Function() onPressed;

  const DayButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: ConstrainedBox(
        constraints: const BoxConstraints.tightFor(width: 25, height: 25),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.blue : Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Text(label,
              style: TextStyle(color: selected ? Colors.white : Colors.blue)),
        ),
      ),
    );
  }
}
