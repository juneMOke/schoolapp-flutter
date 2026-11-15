import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_adjustment.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_register.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';
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
  TodayClosure? todayClosure,
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
final closedWithGap = TodayClosure(
  closedAt: DateTime.utc(2026, 10, 22, 16, 45),
  expectedInCents: 345000000,
  declaredInCents: 344500000,
  gapInCents: -500000,
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

/// L'hôte d'un écran du module : localisations françaises, un `Scaffold`.
Widget treasuryHost(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('fr'),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);
