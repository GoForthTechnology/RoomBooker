import 'package:flutter/material.dart';

class BookingFilterViewModel extends ChangeNotifier {
  String _searchQuery = "";
  String get searchQuery => _searchQuery;

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
}
