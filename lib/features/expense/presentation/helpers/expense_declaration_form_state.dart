import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/capture/captured_document.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_declaration_draft.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_draft.dart';

/// Ce que le formulaire saisit **en plus** pour une déclaration : l'heure du
/// décaissement, la photo du bon, la note sur l'accord reçu.
///
/// L'heure se lit à l'heure de l'école : le jour choisi **est** la date de
/// la dépense (F47), et c'est à Kinshasa que le serveur le vérifie.
class ExpenseDeclarationFormState {
  /// Le jour du décaissement, à l'heure de l'école.
  DateTime day;

  /// L'heure du décaissement, à l'heure de l'école.
  TimeOfDay time;

  CapturedDocument? voucher;
  final TextEditingController note = TextEditingController();

  ExpenseDeclarationFormState({required DateTime now})
    : day = SchoolTime.today(now),
      time = _timeOf(SchoolTime.wallClock(now));

  static TimeOfDay _timeOf(DateTime wall) =>
      TimeOfDay(hour: wall.hour, minute: wall.minute);

  /// L'instant UTC du décaissement.
  DateTime get disbursedAt =>
      SchoolTime.instantAt(day: day, hour: time.hour, minute: time.minute);

  /// Une heure dans le futur ne se déclare pas : l'écran la ramène à
  /// maintenant plutôt que de la laisser partir.
  bool isFuture(DateTime now) => disbursedAt.isAfter(now.toUtc());

  /// Ramène l'heure à maintenant si le jour choisi est aujourd'hui et
  /// l'heure, devant.
  void clampTo(DateTime now) {
    if (!isFuture(now)) return;
    day = SchoolTime.today(now);
    time = _timeOf(SchoolTime.wallClock(now));
  }

  bool get hasVoucher => voucher != null;

  /// La déclaration, à partir du contenu saisi au formulaire commun ; `null`
  /// tant qu'il manque la photo.
  ExpenseDeclarationDraft? draft(
    ExpenseDraft content, {
    required bool visaOnDeclare,
  }) {
    final voucher = this.voucher;
    if (voucher == null) return null;
    return ExpenseDeclarationDraft(
      typeId: content.typeId,
      title: content.title,
      description: content.description,
      amountInCents: content.amountInCents,
      currency: content.currency,
      supplier: content.supplier,
      fundingSource: content.fundingSource,
      disbursedAt: disbursedAt,
      note: note.text,
      voucherBytes: voucher.bytes,
      voucherContentType: voucher.mimeType.value,
      visaOnDeclare: visaOnDeclare,
      recordedByName: content.recordedByName,
    );
  }

  void dispose() => note.dispose();
}
