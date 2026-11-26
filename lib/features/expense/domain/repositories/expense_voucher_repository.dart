import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_voucher_image.dart';

/// La photo du bon d'une dépense déclarée.
abstract class ExpenseVoucherRepository {
  /// Les octets de la photo : depuis le poste s'ils y sont, sinon depuis le
  /// serveur, puis gardés chiffrés. `Right(null)` : la dépense n'a pas de
  /// photo (mode autorisation, ou `404`).
  Future<Either<Failure, ExpenseVoucherImage?>> voucherOf(Expense expense);

  /// La photo est-elle déjà sur ce poste ? C'est ce qui ouvre « Viser » :
  /// on ne vise pas un bon qu'on n'a pas vu (F40).
  Future<bool> isOnDevice(String expenseId);
}
