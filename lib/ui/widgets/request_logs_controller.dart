import 'dart:async';

import 'package:flutter/material.dart';
import 'package:room_booker/data/entities/log_entry.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/data/repos/log_repo.dart';

class RequestLogsController extends ChangeNotifier {
  final LogRepo _logRepo;
  final BookingRepo _bookingRepo;
  final String _orgID;
  final String? _requestID;

  static const recordsPerPageOptions = [5, 10, 20];
  int _recordsPerPage = 5;
  final List<RequestLogEntry> _lastEntries = [];
  List<DecoratedLogEntry>? _cachedLogs;
  StreamSubscription<List<DecoratedLogEntry>>? _subscription;
  bool _isLoading = true;
  String? _error;

  RequestLogsController({
    required LogRepo logRepo,
    required BookingRepo bookingRepo,
    required String orgID,
    String? requestID,
  }) : _logRepo = logRepo,
       _bookingRepo = bookingRepo,
       _orgID = orgID,
       _requestID = requestID {
    _loadLogs();
  }

  int get recordsPerPage => _recordsPerPage;
  List<DecoratedLogEntry> get logs => _cachedLogs ?? [];
  bool get isLoading => _isLoading;
  String? get error => _error;
  RequestLogEntry? get _lastEntry =>
      _lastEntries.isNotEmpty ? _lastEntries.last : null;
  bool get canGoBack => _lastEntries.isNotEmpty;
  bool get canGoForward => !isLoading && logs.isNotEmpty;

  void setRecordsPerPage(int value) {
    if (_recordsPerPage == value) return;
    _recordsPerPage = value;
    _cachedLogs = null;
    _lastEntries.clear();
    _loadLogs();
  }

  void nextPage() {
    if (_cachedLogs == null || _cachedLogs!.isEmpty) return;
    _lastEntries.add(_cachedLogs!.last.entry);
    _loadLogs();
  }

  void previousPage() {
    if (_lastEntries.isEmpty) return;
    _lastEntries.removeLast();
    _loadLogs();
  }

  void _loadLogs() {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _subscription?.cancel();

    Set<String>? requestIDs;
    final reqID = _requestID;
    if (reqID != null) {
      requestIDs = {reqID};
    }

    final stream = _bookingRepo.decorateLogs(
      _orgID,
      _logRepo.getLogEntries(
        _orgID,
        limit: _recordsPerPage,
        startAfter: _lastEntry,
        requestIDs: requestIDs,
      ),
    );

    _subscription = stream.listen(
      (data) {
        _cachedLogs = data;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
