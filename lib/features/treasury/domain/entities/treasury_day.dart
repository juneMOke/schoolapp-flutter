import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_closure.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_register.dart';

/// Une caisse sur une journée de caisse, en centimes de sa devise.
class CashDaySummary extends Equatable {
  final CashRegister register;
  final int openingInCents;
  final int inflowsInCents;
  final int inflowsCount;
  final int outflowsInCents;
  final int outflowsCount;

  /// Ouverture + entrées − sorties, **sans** l'écart du jour : c'est le reste
  /// que la modale de clôture montre (R2).
  final int expectedInCents;
  final int gapInCents;

  /// Le déclaré si la journée est clôturée, l'attendu sinon. Il ouvre la
  /// journée suivante.
  final int closingBalanceInCents;
  final CashClosure? closure;

  /// Lignes arrivées après une clôture, en attente de réponse : la caisse ne
  /// se clôture pas tant qu'il en reste (R19).
  final int pendingAfterClosureCount;

  const CashDaySummary({
    required this.register,
    required this.openingInCents,
    required this.inflowsInCents,
    required this.inflowsCount,
    required this.outflowsInCents,
    required this.outflowsCount,
    required this.expectedInCents,
    required this.gapInCents,
    required this.closingBalanceInCents,
    this.closure,
    this.pendingAfterClosureCount = 0,
  });

  bool get isClosed => closure?.locksRegister ?? false;

  @override
  List<Object?> get props => [
    register,
    openingInCents,
    inflowsInCents,
    inflowsCount,
    outflowsInCents,
    outflowsCount,
    expectedInCents,
    gapInCents,
    closingBalanceInCents,
    closure,
    pendingAfterClosureCount,
  ];
}

/// Une journée de caisse : une entrée par caisse en service ce jour-là.
class TreasuryDay extends Equatable {
  final DateTime date;

  /// « Aujourd'hui » selon le serveur — jamais l'horloge de la tablette.
  final DateTime businessDate;

  /// Toutes les caisses en service ce jour-là sont clôturées (R10).
  final bool dayClosed;
  final List<CashDaySummary> registers;

  const TreasuryDay({
    required this.date,
    required this.businessDate,
    required this.dayClosed,
    required this.registers,
  });

  bool get isToday => date == businessDate;

  int get closedCount => registers.where((r) => r.isClosed).length;

  @override
  List<Object?> get props => [date, businessDate, dayClosed, registers];
}
