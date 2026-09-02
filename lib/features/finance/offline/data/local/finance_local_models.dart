// Barrel des modèles de tables locales du module Facturation (sqflite).
//
// Un modèle = une table = un fichier (`models/`) ; ce barrel reste le point
// d'import unique des appelants (DAO, mappers, sync) — zéro churn quand un
// modèle bouge.
export 'package:school_app_flutter/core/money/local/exchange_rate_local_model.dart';
export 'package:school_app_flutter/features/finance/offline/data/local/models/fee_tariff_local_model.dart';
export 'package:school_app_flutter/features/finance/offline/data/local/models/payment_allocation_local_model.dart';
export 'package:school_app_flutter/features/finance/offline/data/local/models/payment_local_model.dart';
export 'package:school_app_flutter/features/finance/offline/data/local/models/payment_tender_local_model.dart';
export 'package:school_app_flutter/features/finance/offline/data/local/models/student_charge_local_model.dart';
