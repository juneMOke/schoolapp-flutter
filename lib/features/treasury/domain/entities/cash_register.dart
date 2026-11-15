import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_closure.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';

/// Une caisse de l'école : une seule devise, choisie à la création, jamais
/// modifiable.
class CashRegister extends Equatable {
  final String id;
  final String name;
  final TreasuryCurrency currency;

  /// L'instant de création : rien de ce qui précède ne compte dans la caisse.
  final DateTime inServiceAt;

  /// Le premier jour de caisse, au calendrier de l'école.
  final DateTime inServiceOn;

  /// Ce que la caisse détenait à sa création, en centimes (CDF compris).
  final int openingAmountInCents;

  const CashRegister({
    required this.id,
    required this.name,
    required this.currency,
    required this.inServiceAt,
    required this.inServiceOn,
    required this.openingAmountInCents,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    currency,
    inServiceAt,
    inServiceOn,
    openingAmountInCents,
  ];
}

/// Le solde de fin d'une journée de caisse (courbe des 8 derniers jours).
class DayBalance extends Equatable {
  final DateTime day;
  final int balanceInCents;
  final bool closed;

  const DayBalance({
    required this.day,
    required this.balanceInCents,
    required this.closed,
  });

  @override
  List<Object?> get props => [day, balanceInCents, closed];
}

/// Une caisse telle que la montre l'écran Configuration.
class RegisterConfig extends Equatable {
  final CashRegister register;

  /// Le déclaré si la caisse est clôturée aujourd'hui, l'attendu sinon. C'est
  /// le « montant actuel » d'un ajustement.
  final int balanceInCents;

  /// La clôture **vivante** du jour : après une réouverture, elle redevient
  /// `null` (le serveur ne renvoie jamais ici une clôture rouverte).
  final CashClosure? todayClosure;
  final int adjustmentsCount;
  final List<DayBalance> last8Days;

  const RegisterConfig({
    required this.register,
    required this.balanceInCents,
    this.todayClosure,
    this.adjustmentsCount = 0,
    this.last8Days = const [],
  });

  /// Clôturée aujourd'hui, et pas rouverte : plus d'ajustement avant demain
  /// (R11).
  bool get closedToday => todayClosure?.locksRegister ?? false;

  @override
  List<Object?> get props => [
    register,
    balanceInCents,
    todayClosure,
    adjustmentsCount,
    last8Days,
  ];
}
