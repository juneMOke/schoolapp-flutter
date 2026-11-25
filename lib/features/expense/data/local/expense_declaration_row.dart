import 'package:school_app_flutter/features/expense/domain/entities/expense_day.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_voucher.dart';

/// Les colonnes de la **déclaration** d'une ligne de `expenses` (v89), à
/// part du reste de la ligne : elles ne se saisissent pas au formulaire de
/// contenu, et le serveur seul les arbitre une fois la déclaration accusée.
///
/// Une ligne en mode autorisation les porte toutes vides — c'est [none].
class ExpenseDeclarationRow {
  final String mode;
  final String? visaStatus;
  final String? visaById;
  final String? visaByName;

  /// ISO-8601 UTC.
  final String? visaAt;
  final String? flagReason;

  /// ISO-8601 UTC.
  final String? disbursedAt;

  /// `YYYY-MM-DD`.
  final String? cashDay;
  final bool afterClosure;
  final String? voucherId;
  final String? voucherContentType;
  final int? voucherSizeBytes;

  /// ISO-8601 UTC.
  final String? voucherUploadedAt;

  const ExpenseDeclarationRow({
    required this.mode,
    this.visaStatus,
    this.visaById,
    this.visaByName,
    this.visaAt,
    this.flagReason,
    this.disbursedAt,
    this.cashDay,
    this.afterClosure = false,
    this.voucherId,
    this.voucherContentType,
    this.voucherSizeBytes,
    this.voucherUploadedAt,
  });

  static const ExpenseDeclarationRow none = ExpenseDeclarationRow(
    mode: 'AUTHORIZATION',
  );

  factory ExpenseDeclarationRow.fromMap(Map<String, Object?> map) =>
      ExpenseDeclarationRow(
        mode: (map['mode'] as String?) ?? ExpenseMode.authorization.wireValue,
        visaStatus: map['visa_status'] as String?,
        visaById: map['visa_by_id'] as String?,
        visaByName: map['visa_by_name'] as String?,
        visaAt: map['visa_at'] as String?,
        flagReason: map['flag_reason'] as String?,
        disbursedAt: map['disbursed_at'] as String?,
        cashDay: map['cash_day'] as String?,
        afterClosure: ((map['after_closure'] as num?)?.toInt() ?? 0) != 0,
        voucherId: map['voucher_id'] as String?,
        voucherContentType: map['voucher_content_type'] as String?,
        voucherSizeBytes: (map['voucher_size_bytes'] as num?)?.toInt(),
        voucherUploadedAt: map['voucher_uploaded_at'] as String?,
      );

  Map<String, Object?> toMap() => <String, Object?>{
    'mode': mode,
    'visa_status': visaStatus,
    'visa_by_id': visaById,
    'visa_by_name': visaByName,
    'visa_at': visaAt,
    'flag_reason': flagReason,
    'disbursed_at': disbursedAt,
    'cash_day': cashDay,
    'after_closure': afterClosure ? 1 : 0,
    'voucher_id': voucherId,
    'voucher_content_type': voucherContentType,
    'voucher_size_bytes': voucherSizeBytes,
    'voucher_uploaded_at': voucherUploadedAt,
  };

  ExpenseMode get expenseMode => ExpenseMode.fromWire(mode);

  ExpenseVisaStatus? get expenseVisaStatus =>
      ExpenseVisaStatus.fromWire(visaStatus, mode: expenseMode);

  /// La fiche de la photo, ou `null` quand elle ne se lit pas entière : une
  /// fiche à moitié remplie ne désigne rien de sûr.
  ExpenseVoucher? get voucher {
    final id = voucherId;
    final type = voucherContentType;
    final size = voucherSizeBytes;
    if (id == null || type == null || size == null) return null;
    return ExpenseVoucher(
      id: id,
      contentType: type,
      sizeBytes: size,
      uploadedAt: _instant(voucherUploadedAt),
    );
  }

  DateTime? get visaInstant => _instant(visaAt);

  DateTime? get disbursedInstant => _instant(disbursedAt);

  DateTime? get cashDate => ExpenseDay.tryParse(cashDay);

  static DateTime? _instant(String? raw) =>
      raw == null ? null : DateTime.tryParse(raw)?.toUtc();
}
