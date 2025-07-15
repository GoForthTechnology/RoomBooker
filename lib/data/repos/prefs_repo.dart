import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class PreferencesRepo extends ChangeNotifier {
  CalendarView _defaultCalendarView = CalendarView.month;
  static const String _defaultCalendarViewKey = 'default_calendar_view';

  CalendarView get defaultCalendarView => _defaultCalendarView;

  PreferencesRepo() {
    _loadDefaultCalendarView();
  }

  void _loadDefaultCalendarView() async {
    final prefs = await SharedPreferences.getInstance();
    final viewName = prefs.getString(_defaultCalendarViewKey);
    if (viewName != null) {
      try {
        _defaultCalendarView = CalendarView.values.firstWhere(
          (view) => view.name == viewName,
          orElse: () => CalendarView.month,
        );
        notifyListeners();
      } catch (e) {
        // If there's an error, stick with the default
        _defaultCalendarView = CalendarView.month;
      }
    }
  }

  void setDefaultCalendarView(CalendarView view) async {
    _defaultCalendarView = view;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultCalendarViewKey, view.name);
  }
}
