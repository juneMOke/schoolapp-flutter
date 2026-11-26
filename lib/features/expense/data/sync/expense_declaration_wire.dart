import 'package:school_app_flutter/features/expense/data/local/expense_declaration_row.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_day.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';

/// Lit la part **déclaration** d'un `ExpenseDelta` (v3) — sans jamais lever.
///
/// Un champ illisible devient vide, jamais une ligne écartée : une dépense
/// dont seul le visa est mal formé doit rester au registre. Un serveur
/// d'avant la v3 n'envoie aucun de ces champs, et tout se lit alors comme
/// une demande d'autorisation (F36).
abstract final class ExpenseDeclarationWire {
  static ExpenseDeclarationRow parse(Map<dynamic, dynamic> raw) {
    String? text(Object? value) {
      if (value is! String) return null;
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    String? instant(Object? value) =>
        DateTime.tryParse(text(value) ?? '')?.toUtc().toIso8601String();

    final mode = ExpenseMode.fromWire(text(raw['mode']));
    final visa = ExpenseVisaStatus.fromWire(
      text(raw['visaStatus']),
      mode: mode,
    );
    final cashDay = ExpenseDay.tryParse(text(raw['cashDay']));
    final voucher = raw['voucher'];
    final size = voucher is Map ? voucher['sizeBytes'] : null;
    final voucherType = voucher is Map ? text(voucher['contentType']) : null;
    return ExpenseDeclarationRow(
      mode: mode.wireValue,
      visaStatus: visa?.wireValue,
      visaById: text(raw['visaById']),
      visaByName: text(raw['visaByName']),
      visaAt: instant(raw['visaAt']),
      // Le motif n'a de sens que signalée ; un reste ferait lire un motif
      // sous une déclaration visée.
      flagReason: visa == ExpenseVisaStatus.flagged
          ? text(raw['flagReason'])
          : null,
      disbursedAt: instant(raw['paidAt']),
      cashDay: cashDay == null ? null : ExpenseDay.format(cashDay),
      afterClosure: raw['afterClosure'] == true,
      voucherId: voucher is Map ? text(voucher['id']) : null,
      voucherContentType: voucherType?.toLowerCase(),
      voucherSizeBytes: size is num ? size.toInt() : null,
      voucherUploadedAt: voucher is Map ? instant(voucher['uploadedAt']) : null,
    );
  }
}
