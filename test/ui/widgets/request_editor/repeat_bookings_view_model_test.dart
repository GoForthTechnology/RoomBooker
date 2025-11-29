import 'package:flutter_test/flutter_test.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/ui/widgets/request_editor/repeat_booking_selector/repeat_bookings_view_model.dart';

void main() {
  group('RepeatBookingsViewModel', () {
    late DateTime startTime;

    setUp(() {
      startTime = DateTime(2023, 10, 27, 10, 0); // A Friday
    });

    test('initializes with default values', () {
      final viewModel = RepeatBookingsViewModel(startTime: startTime);

      expect(viewModel.pattern.frequency, Frequency.never);
      expect(viewModel.isCustom, false);
      expect(viewModel.startTime, startTime);
      expect(viewModel.readOnlyStream, emits(false));
    });

    test('initializes with existing pattern', () {
      final pattern = RecurrancePattern.daily();
      final viewModel = RepeatBookingsViewModel(
        startTime: startTime,
        initialPattern: pattern,
      );

      expect(viewModel.pattern, pattern);
      expect(viewModel.isCustom, false);
    });

    test('detects custom pattern correctly', () {
      // Weekly on Friday is standard for this start date
      final standardPattern = RecurrancePattern.weekly(on: Weekday.friday);
      final viewModelStandard = RepeatBookingsViewModel(
        startTime: startTime,
        initialPattern: standardPattern,
      );
      expect(viewModelStandard.isCustom, false);

      // Weekly on Monday is custom for this start date (Friday)
      final customPattern = RecurrancePattern.weekly(on: Weekday.monday);
      final viewModelCustom = RepeatBookingsViewModel(
        startTime: startTime,
        initialPattern: customPattern,
      );
      expect(viewModelCustom.isCustom, true);
    });

    test('updates frequency to standard option', () {
      final viewModel = RepeatBookingsViewModel(startTime: startTime);

      viewModel.onFrequencyChanged(Frequency.daily);

      expect(viewModel.pattern.frequency, Frequency.daily);
      expect(viewModel.isCustom, false);
    });

    test('updates frequency to custom', () {
      final viewModel = RepeatBookingsViewModel(startTime: startTime);

      viewModel.onFrequencyChanged(Frequency.custom);

      expect(viewModel.pattern.frequency, Frequency.weekly);
      expect(viewModel.isCustom, true);
    });

    test('updates interval', () {
      final viewModel = RepeatBookingsViewModel(
        startTime: startTime,
        initialPattern: RecurrancePattern.daily(),
      );

      viewModel.onIntervalChanged(5);

      expect(viewModel.pattern.period, 5);
    });

    test('toggles weekday', () {
      final viewModel = RepeatBookingsViewModel(
        startTime: startTime,
        initialPattern: RecurrancePattern.weekly(on: Weekday.friday),
      );

      // Remove Friday
      viewModel.toggleWeekday(Weekday.friday);
      expect(viewModel.pattern.weekday, isEmpty);

      // Add Monday
      viewModel.toggleWeekday(Weekday.monday);
      expect(viewModel.pattern.weekday, contains(Weekday.monday));
    });

    test('updates end date', () {
      final viewModel = RepeatBookingsViewModel(startTime: startTime);
      final endDate = DateTime(2023, 12, 31);

      viewModel.updateEndDate(endDate);

      expect(viewModel.pattern.end, endDate);
    });

    test('updates start time', () {
      final viewModel = RepeatBookingsViewModel(startTime: startTime);
      final newStartTime = DateTime(2023, 11, 1);

      viewModel.updateStartTime(newStartTime);

      expect(viewModel.startTime, newStartTime);
    });

    test('updates read only status', () {
      final viewModel = RepeatBookingsViewModel(startTime: startTime);

      expect(viewModel.readOnlyStream, emitsInOrder([false, true, false]));

      viewModel.setReadOnly(true);
      viewModel.setReadOnly(false);
    });
    
    test('switching from custom to standard resets isCustom', () {
       final viewModel = RepeatBookingsViewModel(startTime: startTime);
       
       // Set to custom
       viewModel.onFrequencyChanged(Frequency.custom);
       expect(viewModel.isCustom, true);
       
       // Set to daily (standard)
       viewModel.onFrequencyChanged(Frequency.daily);
       expect(viewModel.isCustom, false);
       expect(viewModel.pattern.frequency, Frequency.daily);
    });
  });
}
