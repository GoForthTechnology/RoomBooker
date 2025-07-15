import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart' hide Action;
import 'package:room_booker/data/entities/log_entry.dart';

class LogRepo extends ChangeNotifier {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Future<void> addLogEntry({
    required String orgID,
    required String requestID,
    required DateTime timestamp,
    required Action action,
  }) async {
    RequestLogEntry entry = RequestLogEntry(
      requestID: requestID,
      timestamp: timestamp,
      action: action,
      adminEmail: FirebaseAuth.instance.currentUser?.email,
    );
    db
        .collection("orgs")
        .doc(orgID)
        .collection("request-logs")
        .add(entry.toJson())
        .catchError((error) {
      throw Exception("Failed to add log entry: $error");
    });
  }

  Stream<List<RequestLogEntry>> getLogEntries(String orgID, {int? limit}) {
    var query = db
        .collection("orgs")
        .doc(orgID)
        .collection("request-logs")
        .orderBy("timestamp", descending: true);
    if (limit != null) {
      query = query.limit(limit);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => RequestLogEntry.fromJson(doc.data()))
          .toList();
    });
  }
}
