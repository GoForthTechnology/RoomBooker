import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class PreferencesRepo extends ChangeNotifier {
  CalendarView _defaultCalendarView = CalendarView.month;
  static const String _defaultCalendarViewKey = 'default_calendar_view';
  String? _lastOpenedOrgId;
  static const String _lastOpenedOrgIdKey = 'last_opened_org_id';

  CalendarView get defaultCalendarView => _defaultCalendarView;
  String? get lastOpenedOrgId => _lastOpenedOrgId;

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  PreferencesRepo() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final viewName = prefs.getString(_defaultCalendarViewKey);
    if (viewName != null) {
      try {
        _defaultCalendarView = CalendarView.values.firstWhere(
          (view) => view.name == viewName,
          orElse: () => CalendarView.month,
        );
      } catch (e) {
        // If there's an error, stick with the default
        _defaultCalendarView = CalendarView.month;
      }
    }
    _lastOpenedOrgId = prefs.getString(_lastOpenedOrgIdKey);
    _isLoaded = true;
    notifyListeners();
  }

  void setDefaultCalendarView(CalendarView view) async {
    _defaultCalendarView = view;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultCalendarViewKey, view.name);
  }

  void setLastOpenedOrgId(String? orgId) async {
    _lastOpenedOrgId = orgId;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (orgId == null) {
      await prefs.remove(_lastOpenedOrgIdKey);
    } else {
      await prefs.setString(_lastOpenedOrgIdKey, orgId);
    }
  }
}
