import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/navigation/location_query.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/contracts/fee_control_contracts.dart';

/// La question posée par le contrôle des frais — frais, classe, situation et
/// montant —, telle que l'adresse la retient (spec v2, §0) et que la visite
/// suivante la reprend (R2 : « la classe de la dernière visite »).
class FeeControlQuestion {
  final List<String> feeCodes;

  /// Une classe, [feeControlUnassigned], ou `null` (rien de choisi).
  final String? classroomId;
  final FeeControlPaymentFilter situation;

  /// Le montant du segment « a payé au moins… », en centimes.
  final int? thresholdInCents;

  const FeeControlQuestion({
    this.feeCodes = const <String>[],
    this.classroomId,
    this.situation = FeeControlPaymentFilter.all,
    this.thresholdInCents,
  });

  /// La dernière question de la séance — reprise quand on revient par le
  /// menu. **Mémoire de la séance seulement**, sur ce poste : rien n'est écrit
  /// sur disque, rien ne se partage entre comptes d'un même appareil au-delà
  /// de la séance ouverte.
  static FeeControlQuestion? lastVisit;

  bool get isComplete => feeCodes.isNotEmpty && classroomId != null;

  FeeControlQuestion copyWith({
    List<String>? feeCodes,
    Object? classroomId = _keep,
    FeeControlPaymentFilter? situation,
    Object? thresholdInCents = _keep,
  }) => FeeControlQuestion(
    feeCodes: feeCodes ?? this.feeCodes,
    classroomId: identical(classroomId, _keep)
        ? this.classroomId
        : classroomId as String?,
    situation: situation ?? this.situation,
    thresholdInCents: identical(thresholdInCents, _keep)
        ? this.thresholdInCents
        : thresholdInCents as int?,
  );

  FeeControlIntent toIntent() => FeeControlIntent(
    classroomId: classroomId,
    feeCodes: feeCodes,
    situation: situation,
    thresholdInCents: thresholdInCents,
  );

  static FeeControlQuestion fromIntent(FeeControlIntent intent) =>
      FeeControlQuestion(
        feeCodes: intent.feeCodes,
        classroomId: intent.classroomId,
        situation: intent.situation,
        thresholdInCents: intent.thresholdInCents,
      );

  /// La question de l'adresse, ou `null` si elle n'en porte pas.
  static FeeControlQuestion? fromLocation(BuildContext context) {
    final router = LocationQuery.ownedBy(context);
    if (router == null) return null;
    final uri = router.routerDelegate.currentConfiguration.uri;
    final intent = FeeControlIntent.fromRoute(null, uri.queryParameters);
    return intent == null ? null : fromIntent(intent);
  }

  /// Écrit la question dans l'adresse (rien quand elle n'a pas changé).
  void writeLocation(BuildContext context) {
    final router = LocationQuery.ownedBy(context);
    if (router == null) return;
    final params = toIntent().toQueryParameters();
    LocationQuery.write(router, {
      for (final key in FeeControlIntent.queryKeys) key: params[key],
    });
  }

  /// Le montant à transmettre : en centimes, sans devise, sous « a payé au
  /// moins… » seulement. La devise, le bloc la prend sur les lignes lues.
  int? get requestedThresholdInCents =>
      situation.needsThreshold ? thresholdInCents : null;

  /// La requête de recherche, ou `null` si la question est incomplète.
  FeeControlSearchRequest? toRequest() {
    final classroom = classroomId;
    if (feeCodes.isEmpty || classroom == null) return null;
    return FeeControlSearchRequest(
      classroomId: classroom,
      feeCodes: feeCodes,
      statusFilter: situation,
      thresholdInCents: requestedThresholdInCents,
    );
  }
}

const _keep = Object();
