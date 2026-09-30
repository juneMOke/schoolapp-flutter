import 'package:school_app_flutter/features/payroll/data/local/payroll_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_gesture_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_outbox.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_fingerprint_json.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_outbox_handler.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_sync_api.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_write_requests.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_gesture.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_contract_write_dao.dart';
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

  /// Soumettre et valider portent l'empreinte d'un calcul qui lit aussi les
  /// contrats, les profils, les réglages et **toutes** les avances (une avance
  /// commencée plus tôt a encore des échéances ce mois-ci) : ce qui en a été écrit avant sur
  /// la tablette part d'abord, sinon le serveur trouverait d'autres chiffres.
  @override
  Set<String> waitsForAnyOf(PayrollGestureRequestDto request) =>
      PayrollGestureKind.fromWire(request.kind)?.carriesFingerprint ?? false
      ? _calculationInputs
      : const {};

  static const Set<String> _calculationInputs = {
    PayrollOutbox.advance,
    PayrollOutbox.advanceCancellation,
    StaffContractWriteDao.contractAggregateType,
    StaffContractWriteDao.correctionAggregateType,
    PayrollOutbox.settings,
    PayrollOutbox.profile,
  };

  @override
  PayrollGestureRequestDto? parse(Object? raw) =>
      PayrollGestureRequestDto.tryParse(raw);

  @override
  Future<void> send(PayrollGestureRequestDto request, String schoolId) async {
    final payroll = await _api.submitGesture(extras, request.toJson());
    final from = PayrollGestureKind.fromWire(request.kind)?.source;
    if (from != null) {
      await _payrolls.applyAck(
        payroll,
        from: from.wire,
        schoolId: schoolId,
        nowMs: _now(),
      );
    }
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
