import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/network/api_error_parser.dart';
import 'package:school_app_flutter/core/network/online_guard.dart';
import 'package:school_app_flutter/features/treasury/data/wire/treasury_wire.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_closure.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_refusal.dart';

/// Un appel de la trésorerie rendu en `Either`, qui **garde le refus métier**.
///
/// L'intercepteur réduit tout 409 à un `ConflictFailure` sans `detailCode` ;
/// or « la caisse est déjà clôturée » et « le montant a bougé » n'appellent pas
/// le même geste. On relit donc le `detailCode` de la réponse ; tout le reste
/// (réseau, 401, 403, 5xx, réponse illisible) suit [guardOnline].
Future<Either<Failure, T>> guardTreasury<T>(Future<T> Function() call) async {
  try {
    return Right(await call());
  } on DioException catch (e) {
    final refusal = TreasuryRefusal.fromDetailCode(
      ApiErrorParser.detailCodeOf(e.response),
    );
    if (refusal != null) {
      return Left(
        TreasuryRefusalFailure(
          refusal,
          details: ApiErrorParser.detailsOf(e.response) ?? const {},
          closure: _closureOf(e.response?.data),
        ),
      );
    }
    return guardOnline<T>(() => Future.error(e));
  } catch (e) {
    // Même traduction que partout ailleurs : réponse illisible → serveur.
    return guardOnline<T>(() => Future.error(e));
  }
}

/// La clôture que porte un 409 de clôture, à la racine du corps. Illisible ⇒
/// `null` : le refus reste lisible sans elle.
CashClosure? _closureOf(Object? body) {
  if (body is! Map || body['closure'] == null) return null;
  try {
    return TreasuryWire.closureFromJson(body['closure']);
  } catch (_) {
    // FormatException comme TypeError (un champ du mauvais type) : on est
    // déjà dans le traitement d'un refus, rien ne doit s'en échapper.
    return null;
  }
}
