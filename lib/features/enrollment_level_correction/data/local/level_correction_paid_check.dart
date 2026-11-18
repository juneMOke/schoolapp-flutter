import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction_refusal.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/fee_tariff_scope.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/payment_in_force_sql.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Ce que le serveur refuserait, à coup sûr, d'une correction de niveau pour
/// un élève qui a **déjà payé** (contrat du lot F, PR back #243) — `null` si
/// rien ne s'y oppose ici.
///
/// Le jugement se fait **par nature de frais** (`fee_code`) et par devise :
///
/// - le **payé** d'une nature est celui que la tablette affiche : le miroir
///   serveur des créances actuelles (`amount_paid_in_cents`), plus les
///   versements locaux pas encore accusés (`PaymentInForceSql`) ;
/// - le **total cible** est la somme des montants des tarifs du niveau cible
///   pour cette nature (réductions sans effet, comme au serveur en V1) ;
/// - un payé nul ne bloque **jamais**.
///
/// Pour une nature payée : absente de la grille cible ⇒ [feeCodeAbsent] ;
/// présente mais dans une autre devise ⇒ [currencyChanged] ; payé
/// **strictement** supérieur au total cible ⇒ [overpaid] (l'égalité passe).
/// Les natures sont jugées dans l'ordre de leur code, pour que deux essais
/// rendent la même phrase.
///
/// Ce contrôle ne remplace pas la garde du serveur : un versement pris sur une
/// autre tablette n'est pas encore ici. Il épargne seulement au guichet un
/// geste dont le refus est certain.
Future<LevelCorrectionRefusal?> levelCorrectionPaidRefusal(
  DatabaseExecutor db, {
  required String studentId,
  required String academicYearId,
  required String toSchoolLevelId,
  required String? toSchoolLevelGroupId,
}) async {
  final paidRows = await db.rawQuery(
    '''
    SELECT sc.fee_code AS fee_code, sc.currency AS currency,
           SUM(sc.amount_paid_in_cents
               + ${PaymentInForceSql.pendingPaidForCharge('sc')}) AS paid
    FROM student_charges sc
    WHERE sc.student_id = ?
      AND (sc.academic_year_id = ? OR sc.academic_year_id IS NULL)
    GROUP BY sc.fee_code, sc.currency
    ORDER BY sc.fee_code, sc.currency
    ''',
    [studentId, academicYearId],
  );
  final paid = [
    for (final r in paidRows)
      if (((r['paid'] as int?) ?? 0) > 0)
        (
          feeCode: r['fee_code']! as String,
          currency: r['currency']! as String,
          cents: r['paid']! as int,
        ),
  ];
  if (paid.isEmpty) return null;

  final tariffs = await db.query(
    'ref_fee_tariffs',
    columns: const ['fee_code', 'currency', 'amount_in_cents'],
    where: FeeTariffScope.whereClause(schoolLevelGroupId: toSchoolLevelGroupId),
    whereArgs: FeeTariffScope.whereArgs(
      schoolLevelId: toSchoolLevelId,
      academicYearId: academicYearId,
      schoolLevelGroupId: toSchoolLevelGroupId,
    ),
  );
  final target = <String, Map<String, int>>{};
  for (final t in tariffs) {
    final byCurrency = target[t['fee_code']! as String] ??= {};
    final currency = t['currency']! as String;
    byCurrency[currency] =
        (byCurrency[currency] ?? 0) + ((t['amount_in_cents'] as int?) ?? 0);
  }

  for (final p in paid) {
    final byCurrency = target[p.feeCode];
    if (byCurrency == null) return LevelCorrectionRefusal.feeCodeAbsent;
    final total = byCurrency[p.currency];
    if (total == null) return LevelCorrectionRefusal.currencyChanged;
    if (p.cents > total) return LevelCorrectionRefusal.overpaid;
  }
  return null;
}
