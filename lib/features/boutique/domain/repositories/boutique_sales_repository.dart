import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_sales_page.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_sales_report.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/sales_query.dart';

/// Les ventes de la période et leur rapport — **100 % serveur**, comme la
/// table des reçus de la caisse Finances.
///
/// Pas de photo hors ligne : une liste paginée et filtrée ne se met pas en
/// cache proprement, et une vieille page se lirait comme la liste du jour.
/// Les ventes que le serveur ne connaît pas encore restent sur la tablette ;
/// l'écran les signale à part.
abstract class BoutiqueSalesRepository {
  Future<Either<Failure, BoutiqueSalesPage>> sales(SalesQuery query);

  /// Le rapport des ventes de [query], **toutes pages** : la page demandée est
  /// ignorée.
  Future<Either<Failure, BoutiqueSalesReport>> report(SalesQuery query);
}
