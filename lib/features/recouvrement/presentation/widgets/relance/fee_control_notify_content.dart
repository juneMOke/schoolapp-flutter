import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_payer_identity.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/fee_section_titles_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_bloc.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/fee_control_fee_options.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/fee_control_query_phrase.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Un destinataire de la relance (O4) : **le parent d'un élève coché**.
///
/// Le parent n'est pas une personne référencée — il n'existe que comme
/// identité recopiée sur les versements, ou comme tuteur déclaré. D'où un nom
/// et un numéro tous deux facultatifs : un élève dont l'appareil ne connaît
/// aucun parent reste listé, pour qu'on sache qui n'a pas été joint.
class FeeControlNotifyRecipient extends Equatable {
  final String studentId;
  final String studentName;

  /// Nom du parent payeur, sinon du tuteur ; `null` si l'appareil n'en connaît
  /// aucun.
  final String? parentName;

  /// Numéro E.164, ou `null`.
  final String? phoneNumber;

  const FeeControlNotifyRecipient({
    required this.studentId,
    required this.studentName,
    this.parentName,
    this.phoneNumber,
  });

  bool get hasPhone => phoneNumber?.trim().isNotEmpty ?? false;

  @override
  List<Object?> get props => [studentId, studentName, parentName, phoneNumber];
}

/// Les parents connus d'un élève, payeurs d'abord puis tuteurs — l'ordre de
/// `GetPayerSuggestionsUseCase`.
typedef FeeControlParentLookup =
    Future<Either<Failure, List<LocalPayerIdentity>>> Function(
      String studentId,
    );

/// Résout un destinataire par élève coché, **dans l'ordre de l'écran**.
///
/// Le payeur prime sur le tuteur (« a déjà payé » est un fait constaté, le
/// tuteur une hypothèse) — mais un payeur sans numéro cède la place au premier
/// parent qui en a un : une relance sert à joindre. Une lecture en échec n'est
/// pas une panne de la relance : l'élève passe « sans téléphone ».
Future<List<FeeControlNotifyRecipient>> resolveNotifyRecipients(
  List<FeeControlRow> rows,
  FeeControlParentLookup lookup,
) async {
  final recipients = <FeeControlNotifyRecipient>[];
  for (final row in rows) {
    final student = row.summary.student;
    final parents = (await lookup(
      row.studentId,
    )).fold((_) => const <LocalPayerIdentity>[], (found) => found);
    final parent =
        parents
            .where((p) => p.phoneNumber?.trim().isNotEmpty ?? false)
            .firstOrNull ??
        parents.firstOrNull;
    final name = parent?.fullName ?? '';
    recipients.add(
      FeeControlNotifyRecipient(
        studentId: row.studentId,
        studentName: '${student.lastName} ${student.firstName}'.trim(),
        parentName: name.isEmpty ? null : name,
        phoneNumber: parent?.phoneNumber?.trim(),
      ),
    );
  }
  return recipients;
}

/// Le contexte de la relance : **frais · classe** — les frais nommés comme
/// leurs pastilles (`recouvrementFeeTitle`), la classe par son nom. Ni la
/// situation ni le plancher : le parent n'a que faire du filtre de l'écran.
String notifyContextLabel(
  FeeControlState state,
  AppLocalizations l10n, {
  required FeeSectionTitlesState titles,
}) {
  final fees = [
    for (final code in state.lastQuery?.feeCodes ?? const <String>[])
      recouvrementFeeTitle(code, titles, l10n),
  ].join(' + ');
  final classroom = FeeControlQueryPhrase.classroomName(state, l10n);
  return [fees, ?classroom].where((part) => part.isNotEmpty).join(' · ');
}

/// Le message prérempli (`relance.message`) : l'échéance est **aujourd'hui +
/// 7 jours**, au format jj/mm/aaaa ; sans nom d'école connu, la signature
/// retombe sur « la direction de l'école » plutôt qu'un « de . » orphelin.
String composeNotifyMessage(
  AppLocalizations l10n, {
  required String context,
  required String schoolName,
  required DateTime today,
}) {
  final due = DateTime(today.year, today.month, today.day + 7);
  final date = formatNotifyDate(due);
  final school = schoolName.trim();
  return school.isEmpty
      ? l10n.feeControlNotifyMessageNoSchool(context, date)
      : l10n.feeControlNotifyMessage(context, date, school);
}

/// jj/mm/aaaa — la forme des pièces de l'écran (feuille d'appel comprise).
String formatNotifyDate(DateTime moment) =>
    '${moment.day.toString().padLeft(2, '0')}/'
    '${moment.month.toString().padLeft(2, '0')}/${moment.year}';
