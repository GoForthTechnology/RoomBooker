import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roombooker_core/data/entities/provisioning_handshake.dart';
import 'package:roombooker_core/data/entities/kiosk_identity.dart';

class ProvisioningService {
  final FirebaseFirestore _firestore;

  ProvisioningService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Generates a 6-digit activation code and stores it in Firestore.
  Future<String> createActivationCode({
    required String orgID,
    required String orgName,
    required String roomID,
    required String roomName,
  }) async {
    final code = _generateRandomCode();
    final expiresAt = DateTime.now().add(const Duration(minutes: 10));

    final handshake = ProvisioningHandshake(
      code: code,
      orgID: orgID,
      orgName: orgName,
      roomID: roomID,
      roomName: roomName,
      expiresAt: expiresAt,
    );

    await _firestore
        .collection('provisioning_codes')
        .doc(code)
        .set(handshake.toJson());

    return code;
  }

  /// Verifies a code and returns the associated Room and Org IDs.
  /// Throws an exception if the code is invalid or expired.
  Future<ProvisioningHandshake?> consumeActivationCode(String code) async {
    final doc = await _firestore.collection('provisioning_codes').doc(code).get();

    if (!doc.exists) {
      throw Exception('Invalid activation code');
    }

    final handshake = ProvisioningHandshake.fromJson(doc.data()!);
    if (handshake.isExpired) {
      await _firestore.collection('provisioning_codes').doc(code).delete();
      throw Exception('Activation code expired');
    }

    // Delete the code immediately upon consumption
    await _firestore.collection('provisioning_codes').doc(code).delete();

    return handshake;
  }

  /// Registers a kiosk device identity.
  Future<void> registerKiosk(KioskIdentity identity) async {
    await _firestore
        .collection('orgs')
        .doc(identity.orgID)
        .collection('kiosks')
        .doc(identity.deviceId)
        .set(identity.toJson());
  }

  String _generateRandomCode() {
    final rnd = Random();
    final code = rnd.nextInt(900000) + 100000; // 100,000 to 999,999
    return code.toString();
  }
}
