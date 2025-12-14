import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class PreferencesRepo extends ChangeNotifier {
  final SharedPreferences _prefs;
  CalendarView _defaultCalendarView = CalendarView.month;
  static const String _defaultCalendarViewKey = 'default_calendar_view';
  String? _lastOpenedOrgId;
  static const String _lastOpenedOrgIdKey = 'last_opened_org_id';

  CalendarView get defaultCalendarView => _defaultCalendarView;
  String? get lastOpenedOrgId => _lastOpenedOrgId;

  bool get isLoaded => true;

  PreferencesRepo(this._prefs) {
    _loadPreferences();
  }

  void _loadPreferences() {
    final viewName = _prefs.getString(_defaultCalendarViewKey);
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
    _lastOpenedOrgId = _prefs.getString(_lastOpenedOrgIdKey);
  }

  void setDefaultCalendarView(CalendarView view) async {
    _defaultCalendarView = view;
    notifyListeners();

    await _prefs.setString(_defaultCalendarViewKey, view.name);
  }

  void setLastOpenedOrgId(String? orgId) async {
    _lastOpenedOrgId = orgId;
    notifyListeners();
    if (orgId == null) {
      await _prefs.remove(_lastOpenedOrgIdKey);
    } else {
      await _prefs.setString(_lastOpenedOrgIdKey, orgId);
    }
  }
}
