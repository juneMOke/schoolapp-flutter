import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Traduit un `aggregateType` d'outbox en libellé métier lisible.
///
/// Volontairement tolérant : un type inconnu (branche future, entrée héritée)
/// retombe sur sa valeur brute plutôt que de masquer la ligne — une écriture en
/// échec doit rester visible même si personne n'a encore écrit son libellé.
String syncAggregateLabel(AppLocalizations l10n, String aggregateType) {
  switch (aggregateType) {
    case 'ENROLLMENT':
      return l10n.syncAggregateEnrollment;
    case 'PAYMENT':
      return l10n.syncAggregatePayment;
    case 'ATTENDANCE':
      return l10n.syncAggregateAttendance;
    case 'DISCIPLINARY_CASE':
      return l10n.syncAggregateDisciplinaryCase;
    case 'ACADEMICS_NOTES_BATCH':
      return l10n.syncAggregateNotesBatch;
    case 'ACADEMICS_EVALUATION':
      return l10n.syncAggregateEvaluation;
    case 'CLASSROOM_TRANSFER':
      return l10n.syncAggregateClassroomTransfer;
    default:
      return aggregateType;
  }
}

/// Repère métier lisible extrait de l'`aggregateId`, quand il en porte un.
///
/// Sans lui, deux appels en échec sont strictement indiscernables dans la
/// feuille — alors que le message d'erreur demande précisément de rouvrir « la
/// journée concernée ». `ATTENDANCE` porte la clé naturelle
/// `classroomId|date|academicYearId` : la date en est la partie utile et
/// stable. Renvoie `null` quand aucun repère fiable ne peut être extrait —
/// mieux vaut ne rien afficher qu'un identifiant technique.
String? syncAggregateBusinessKey(String aggregateType, String aggregateId) {
  if (aggregateType != 'ATTENDANCE') return null;
  final parts = aggregateId.split('|');
  if (parts.length < 2) return null;
  final date = parts[1];
  return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date) ? date : null;
}
