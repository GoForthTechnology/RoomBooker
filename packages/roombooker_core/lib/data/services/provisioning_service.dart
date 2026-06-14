import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:roombooker_core/data/entities/kiosk_grant.dart';
import 'package:roombooker_core/data/entities/provisioning_handshake.dart';

class ProvisioningService {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions? _functions;

  ProvisioningService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions;

  FirebaseFunctions get _functionsInstance =>
      _functions ?? FirebaseFunctions.instance;

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

  /// Claims a Kiosk grant for the calling (anonymously authenticated) user
  /// by redeeming an activation code. Returns the org/room this device is
  /// now authorized to access.
  Future<KioskGrant> claimKioskGrant({
    required String code,
    required String deviceID,
  }) async {
    final callable = _functionsInstance.httpsCallable('claimKioskGrant');
    final result = await callable.call<Map<String, dynamic>>({
      'code': code,
      'deviceID': deviceID,
    });
    return KioskGrant.fromJson(Map<String, dynamic>.from(result.data));
  }

  /// Revokes the calling user's Kiosk grant for the given org/room.
  Future<void> revokeKioskGrant({
    required String orgID,
    required String roomID,
  }) async {
    final callable = _functionsInstance.httpsCallable('revokeKioskGrant');
    await callable.call<Map<String, dynamic>>({
      'orgID': orgID,
      'roomID': roomID,
    });
  }

  String _generateRandomCode() {
    final rnd = Random();
    final code = rnd.nextInt(900000) + 100000; // 100,000 to 999,999
    return code.toString();
  }
}
