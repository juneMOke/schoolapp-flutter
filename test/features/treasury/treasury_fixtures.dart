import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_adjustment.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_closure.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_movement.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_register.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_day.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une caisse USD de 4 820,00 $, en service depuis le 1er octobre 2026.
final usdRegister = CashRegister(
  id: 'reg-usd',
  name: 'Caisse USD',
  currency: TreasuryCurrency.usd,
  inServiceAt: DateTime.utc(2026, 10, 1, 7),
  inServiceOn: DateTime(2026, 10, 1),
  openingAmountInCents: 522000,
);

/// Une caisse CDF de 3 450 000 FC, créée le 20 octobre 2026.
final cdfRegister = CashRegister(
  id: 'reg-cdf',
  name: 'Caisse CDF',
  currency: TreasuryCurrency.cdf,
  inServiceAt: DateTime.utc(2026, 10, 20, 7),
  inServiceOn: DateTime(2026, 10, 20),
  openingAmountInCents: 75000000,
);

RegisterConfig configOf(
  CashRegister register, {
  int balanceInCents = 482000,
  CashClosure? todayClosure,
  int adjustmentsCount = 0,
}) => RegisterConfig(
  register: register,
  balanceInCents: balanceInCents,
  todayClosure: todayClosure,
  adjustmentsCount: adjustmentsCount,
);

final usdConfig = configOf(usdRegister);
final cdfConfig = configOf(cdfRegister, balanceInCents: 345000000);

/// Une clôture d'aujourd'hui à 17:45 (heure de Kinshasa), avec un écart.
final closedWithGap = CashClosure(
  id: 'clo-1',
  registerId: 'reg-cdf',
  currency: TreasuryCurrency.cdf,
  cashDay: DateTime(2026, 10, 22),
  closedAt: DateTime.utc(2026, 10, 22, 16, 45),
  closedByName: 'Ilunga Céline',
  closedByRole: 'ACCOUNTANT',
  matches: false,
  expectedInCents: 345000000,
  declaredInCents: 344500000,
  gapInCents: -500000,
  justification: 'Erreur de rendu de monnaie',
);

final adjustment = CashAdjustment(
  id: 'adj-1',
  number: 'CF-AJ-2627-000001',
  registerId: 'reg-usd',
  cashDay: DateTime(2026, 10, 22),
  adjustedAt: DateTime.utc(2026, 10, 22, 14, 10),
  previousExpectedInCents: 482000,
  newAmountInCents: 490000,
  deltaInCents: 8000,
  reason: 'Recomptage de la caisse',
  createdByName: 'Junior Moke',
);

/// Le jeudi 22 octobre 2026, jour de la démo.
final demoDay = DateTime(2026, 10, 22);

/// La caisse USD du jour : 4 933 + 181 − 295 = 4 819 $.
CashDaySummary usdDay({
  CashClosure? closure,
  int pendingAfterClosureCount = 0,
}) => CashDaySummary(
  register: usdRegister,
  openingInCents: 493300,
  inflowsInCents: 18100,
  inflowsCount: 7,
  outflowsInCents: 29500,
  outflowsCount: 3,
  expectedInCents: 481900,
  gapInCents: closure?.gapInCents ?? 0,
  closingBalanceInCents: closure?.declaredInCents ?? 481900,
  closure: closure,
  pendingAfterClosureCount: pendingAfterClosureCount,
);

/// La caisse CDF du jour : reste attendu 3 450 000 FC.
CashDaySummary cdfDay({CashClosure? closure}) => CashDaySummary(
  register: cdfRegister,
  openingInCents: 332626900,
  inflowsInCents: 34196100,
  inflowsCount: 3,
  outflowsInCents: 21823000,
  outflowsCount: 1,
  expectedInCents: 345000000,
  gapInCents: closure?.gapInCents ?? 0,
  closingBalanceInCents: closure?.declaredInCents ?? 345000000,
  closure: closure,
);

TreasuryDay treasuryDay(
  List<CashDaySummary> registers, {
  DateTime? date,
  DateTime? businessDate,
}) => TreasuryDay(
  date: date ?? demoDay,
  businessDate: businessDate ?? demoDay,
  dayClosed: registers.every((r) => r.isClosed),
  registers: registers,
);

/// Un paiement de 20 $ fait hier soir, arrivé après la clôture d'hier.
final afterClosurePayment = CashMovement(
  id: 'mv-after',
  registerId: 'reg-usd',
  currency: TreasuryCurrency.usd,
  cashDay: demoDay,
  businessDay: DateTime(2026, 10, 21),
  occurredAt: DateTime.utc(2026, 10, 21, 16, 30),
  direction: MovementDirection.inflow,
  amountInCents: 2000,
  source: MovementSource.fees,
  nature: MovementNature.entry,
  label: 'Frais de scolarité — Kabongo Mwamba · 6e A',
  reference: 'CF-RC-2627-000123',
  afterClosure: true,
);

/// L'hôte d'un écran du module : localisations françaises, un `Scaffold`.
Widget treasuryHost(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('fr'),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);
