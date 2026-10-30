import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

/// Le ticket d'annulation d'un versement (continuité des tickets RC, lot B).
///
/// Le promoteur garde un exemplaire de chaque ticket et contrôle sa pile jour
/// par jour : un numéro de reçu annulé doit y avoir un papier, sinon il se lit
/// comme un saut. Ce ticket est ce papier — il porte le numéro, dit qu'il est
/// annulé, quand, pourquoi et par qui.
///
/// Composé sur la tablette, comme le ticket de caisse : tout ce qu'il imprime
/// est déjà en local.
class TicketCancellationModel extends Equatable {
  final String schoolName;
  final String? schoolAddress;
  final String? schoolLocality;
  final String? schoolEmail;
  final String? schoolPhone;
  final String? schoolTillPhone;

  /// Le numéro définitif du reçu annulé.
  final String receiptNumber;

  /// Quand le versement d'origine a été encaissé.
  final DateTime originalPaidAt;

  final String studentFullName;
  final String? classroomName;

  /// Ce que le tiroir avait reçu, par devise.
  final MoneyBag amount;

  /// Quand l'annulation a été posée.
  final DateTime cancelledAt;

  /// Le motif, déjà traduit.
  final String reason;

  /// La précision libre saisie avec le motif, `null` sans précision.
  final String? reasonDetail;

  /// L'argent a été rendu au payeur.
  final bool cashMoved;

  /// Le compte qui a annulé, `null` tant que le pull ne l'a pas nommé.
  final String? cancelledByName;

  final TicketCancellationLabels labels;

  const TicketCancellationModel({
    required this.schoolName,
    this.schoolAddress,
    this.schoolLocality,
    this.schoolEmail,
    this.schoolPhone,
    this.schoolTillPhone,
    required this.receiptNumber,
    required this.originalPaidAt,
    required this.studentFullName,
    this.classroomName,
    required this.amount,
    required this.cancelledAt,
    required this.reason,
    this.reasonDetail,
    required this.cashMoved,
    this.cancelledByName,
    required this.labels,
  });

  @override
  List<Object?> get props => [
    schoolName,
    schoolAddress,
    schoolLocality,
    schoolEmail,
    schoolPhone,
    schoolTillPhone,
    receiptNumber,
    originalPaidAt,
    studentFullName,
    classroomName,
    amount,
    cancelledAt,
    reason,
    reasonDetail,
    cashMoved,
    cancelledByName,
    labels,
  ];
}

/// Les libellés du ticket d'annulation, résolus par la présentation : le
/// domaine ne lit pas `AppLocalizations`.
class TicketCancellationLabels extends Equatable {
  final String title;
  final String receiptLabel;
  final String cancelledMark;
  final String issuedAtLabel;
  final String amountLabel;
  final String cancelledAtLabel;
  final String reasonLabel;
  final String detailLabel;
  final String cashReturnedLabel;
  final String yes;
  final String no;
  final String cancelledByLabel;
  final String classroomLabel;
  final String schoolPhoneLabel;
  final String tillPhoneLabel;

  /// Le motif traduit, par code (`REFUNDED`, `DUPLICATE`…).
  final Map<String, String> reasons;

  const TicketCancellationLabels({
    required this.title,
    required this.receiptLabel,
    required this.cancelledMark,
    required this.issuedAtLabel,
    required this.amountLabel,
    required this.cancelledAtLabel,
    required this.reasonLabel,
    required this.detailLabel,
    required this.cashReturnedLabel,
    required this.yes,
    required this.no,
    required this.cancelledByLabel,
    required this.classroomLabel,
    required this.schoolPhoneLabel,
    required this.tillPhoneLabel,
    required this.reasons,
  });

  @override
  List<Object?> get props => [
    title,
    receiptLabel,
    cancelledMark,
    issuedAtLabel,
    amountLabel,
    cancelledAtLabel,
    reasonLabel,
    detailLabel,
    cashReturnedLabel,
    yes,
    no,
    cancelledByLabel,
    classroomLabel,
    schoolPhoneLabel,
    tillPhoneLabel,
    reasons,
  ];
}
