import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/money/currency_code.dart';

/// Les caisses en espèces closes **aujourd'hui**, à l'heure de l'école (R11).
///
/// Une fois la caisse d'une devise clôturée, la tablette refuse elle-même tout
/// nouvel encaissement en espèces dans cette devise jusqu'au lendemain — ou
/// jusqu'à une réouverture. Le serveur, lui, ne refuse jamais un fait
/// d'argent : il l'inscrirait sur la journée suivante, et la caissière aurait
/// déclaré un reste qui ne comptait pas ce billet.
///
/// Partagé par l'encaissement, la correction d'un versement et la boutique ;
/// tenu par la Trésorerie, qui tire les clôtures (`treasury.closures`).
abstract class CashRegisterLock {
  /// Les devises (codes normalisés) dont la caisse est close aujourd'hui.
  Future<Set<String>> closedToday();
}

/// Un encaissement refusé parce que la caisse de [currency] est close
/// aujourd'hui.
class CashRegisterClosedFailure extends Failure {
  final String currency;

  const CashRegisterClosedFailure(this.currency)
    : super('Caisse clôturée aujourd\'hui');

  @override
  List<Object?> get props => [message, currency];
}

/// La garde commune : `Left` si l'une des [currencies] perçues a sa caisse
/// close aujourd'hui, `Right(unit)` sinon. Sans verrou (tests, module absent),
/// rien n'est retenu.
Future<Either<Failure, Unit>> guardCashRegisters(
  CashRegisterLock? lock,
  Iterable<String> currencies,
) async {
  if (lock == null) return const Right(unit);
  final Set<String> closed;
  try {
    closed = await lock.closedToday();
  } catch (_) {
    // Une base illisible ne doit pas fermer le guichet : le serveur range le
    // fait sur la bonne journée, et la ligne arrivée après clôture le dira.
    return const Right(unit);
  }
  for (final currency in currencies) {
    final code = CurrencyCode.normalize(currency);
    if (closed.contains(code)) return Left(CashRegisterClosedFailure(code));
  }
  return const Right(unit);
}
