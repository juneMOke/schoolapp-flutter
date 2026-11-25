import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_voucher_image.dart';

/// Ce que la fiche d'une **déclaration** demande à l'écran qui l'ouvre (v3) :
/// la photo du bon, et si l'annulation reste offerte. La fiche ne connaît ni
/// le dépôt ni la Trésorerie.
class ExpenseDeclarationSupport {
  /// La photo, du poste ou du serveur ; `Right(null)` sans photo.
  final Future<Either<Failure, ExpenseVoucherImage?>> Function(Expense)
  loadVoucher;

  /// « Annuler » reste-t-il offert (F44) ?
  final Future<bool> Function(Expense) canCancel;

  /// La session peut déclarer : une déclaration refusée se redéclare (F45).
  final bool canRedeclare;

  const ExpenseDeclarationSupport({
    required this.loadVoucher,
    required this.canCancel,
    this.canRedeclare = false,
  });
}
