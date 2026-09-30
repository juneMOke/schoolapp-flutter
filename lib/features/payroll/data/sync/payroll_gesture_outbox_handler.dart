import 'package:school_app_flutter/features/payroll/data/local/payroll_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_gesture_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_outbox.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_fingerprint_json.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_outbox_handler.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_sync_api.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_write_requests.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_gesture.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_push_failure.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

/// `PAYROLL_GESTURE` — soumettre, renvoyer, valider, rouvrir.
///
/// **Attend** ce qui a été posé avant lui sur le même mois — éléments
/// variables, avances qui commencent ce mois-là, gestes aînés : l'empreinte
/// envoyée a été calculée avec eux, le serveur doit les avoir.
///
/// Un refus `PAYROLL_STALE` garde les chiffres du serveur pour l'écran de
/// confrontation.
class PayrollGestureOutboxHandler
    extends PayrollOutboxHandler<PayrollGestureRequestDto> {
  final PayrollSyncApi _api;
  final PayrollGestureDao _gestures;
  final PayrollDao _payrolls;
  final int Function() _now;

  PayrollGestureOutboxHandler({
    required PayrollSyncApi api,
    required PayrollGestureDao gestures,
    required PayrollDao payrolls,
    required super.outbox,
    required super.currentUser,
    required super.extras,
    int Function()? now,
  }) : _api = api,
       _gestures = gestures,
       _payrolls = payrolls,
       _now = now ?? (() => DateTime.now().millisecondsSinceEpoch);

  @override
  String get aggregateType => PayrollOutbox.gesture;

  @override
  Set<String> get waitsFor => const {
    PayrollOutbox.variables,
    PayrollOutbox.gesture,
    PayrollOutbox.advance,
  };

  @override
  PayrollGestureRequestDto? parse(Object? raw) =>
      PayrollGestureRequestDto.tryParse(raw);

  @override
  Future<void> send(PayrollGestureRequestDto request, String schoolId) async {
    final payroll = await _api.submitGesture(extras, request.toJson());
    await _payrolls.apply([payroll], schoolId: schoolId, nowMs: _now());
    await _gestures.mark(request.gestureId, StaffSyncState.synced);
  }

  @override
  Future<bool> reject(
    PayrollGestureRequestDto request,
    StaffPushFailure failure,
    String schoolId,
  ) async {
    final body = failure.body;
    await _gestures.mark(
      request.gestureId,
      StaffSyncState.failed,
      code: failure.storedCode,
      reason: failure.reason,
      serverState: failure.detailCode == PayrollGesture.staleCode && body is Map
          ? PayrollFingerprintJson.tryParse(body['server'])
          : null,
    );
    return true;
  }
}
