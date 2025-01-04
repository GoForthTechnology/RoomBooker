import 'package:flutter/material.dart';

class Org {
  final String name;

  Org({required this.name});
}

class OrgRepo extends ChangeNotifier {
  final List<Org> _orgs = [];

  Future<void> addOrg(String name) async {
    _orgs.add(Org(name: name));
    notifyListeners();
  }

  Stream<List<Org>> get orgs => Stream.value(_orgs);
}
