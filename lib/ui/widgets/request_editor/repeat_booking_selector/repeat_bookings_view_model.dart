import 'package:flutter/material.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/logic/recurring_bookings.dart';
import 'package:rxdart/rxdart.dart';

class RepeatBookingsViewModel extends ChangeNotifier {
  final _patternSubject =
      BehaviorSubject<RecurrancePattern>.seeded(RecurrancePattern.never());
  final _isCustomSubject = BehaviorSubject<bool>.seeded(false);
  final _startTimeSubject = BehaviorSubject<DateTime>();
  final _readOnlySubject = BehaviorSubject<bool>.seeded(false);

  Stream<RecurrancePattern> get patternStream => _patternSubject.stream;
  Stream<bool> get isCustomStream => _isCustomSubject.stream;
  Stream<DateTime> get startTimeStream => _startTimeSubject.stream;
  Stream<bool> get readOnlyStream => _readOnlySubject.stream;

  RecurrancePattern get pattern => _patternSubject.value;
  bool get isCustom => _isCustomSubject.value;
  DateTime get startTime => _startTimeSubject.value;

  RepeatBookingsViewModel({
    required DateTime startTime,
    RecurrancePattern? initialPattern,
    bool readOnly = false,
  }) {
    _startTimeSubject.add(startTime);
    if (initialPattern != null) {
      _patternSubject.add(initialPattern);
      // If the pattern is complex or has an interval > 1, it's likely custom.
      // But for now, we default to false unless we have logic to detect it.
      // We can check if it matches any of the standard options.
      _isCustomSubject.add(_detectIfCustom(initialPattern, startTime));
    }
    _readOnlySubject.add(readOnly);
  }

  bool _detectIfCustom(RecurrancePattern pattern, DateTime startTime) {
    if (pattern.frequency == Frequency.never) return false;
    var options = getRecurringBookingOptions(startTime);
    // If the pattern exactly matches one of the standard options (Daily, Weekly, Monthly, Annually), it's not custom.
    // Note: This is a simple check. `getRecurringBookingOptions` returns default patterns.
    // If the user has a weekly pattern but interval is 2, it won't match the default weekly (interval 1).
    
    // We iterate through options to see if any match.
    for (var entry in options.entries) {
      if (entry.key == Frequency.custom) continue;
      if (entry.value == pattern) return false;
    }
    return true;
  }

  void updateStartTime(DateTime startTime) {
    _startTimeSubject.add(startTime);
  }

  void setReadOnly(bool readOnly) {
    _readOnlySubject.add(readOnly);
  }

  void onFrequencyChanged(Frequency frequency) {
    if (frequency == Frequency.custom) {
      // Switch to custom mode. Default to weekly if not already compatible?
      // Logic from RequestEditorPanel:
      // state.updateFrequency(Frequency.weekly, true);
      _updateFrequencyInternal(Frequency.weekly, true);
    } else {
       // Standard option selected.
       var options = getRecurringBookingOptions(_startTimeSubject.value);
       var newPattern = options[frequency];
       if (newPattern != null) {
         _patternSubject.add(newPattern);
         _isCustomSubject.add(false);
       }
    }
  }

  void _updateFrequencyInternal(Frequency frequency, bool isCustom) {
    var currentPattern = _patternSubject.value;
    var weekday = getWeekday(_startTimeSubject.value);
    var interval = currentPattern.period;
    if (frequency != Frequency.never && interval == 0) {
      interval = 1;
    }
    
    // Construct new pattern
    // Note: RequestEditorState logic resets weekdays to just the current day.
    var newPattern = currentPattern.copyWith(
      frequency: frequency,
      weekday: {weekday},
      period: interval,
    );
    
    _patternSubject.add(newPattern);
    _isCustomSubject.add(isCustom);
  }

  void onIntervalChanged(int interval) {
    var current = _patternSubject.value;
    _patternSubject.add(current.copyWith(period: interval));
  }

  void toggleWeekday(Weekday weekday) {
    var current = _patternSubject.value;
    var newWeekdays = Set<Weekday>.from(current.weekday ?? {});
    if (newWeekdays.contains(weekday)) {
      newWeekdays.remove(weekday);
    } else {
      newWeekdays.add(weekday);
    }
    _patternSubject.add(current.copyWith(weekday: newWeekdays));
  }

  void updateEndDate(DateTime? endDate) {
    var current = _patternSubject.value;
    _patternSubject.add(current.copyWith(end: endDate));
  }

  @override
  void dispose() {
    _patternSubject.close();
    _isCustomSubject.close();
    _startTimeSubject.close();
    _readOnlySubject.close();
    super.dispose();
  }
}
