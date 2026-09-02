import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/local/exchange_rate_dao.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';

/// La série de taux de l'**école courante**, lue en local.
///
/// Vit au socle et non dans la Facturation : les deux caisses en ont besoin, et
/// la table est un référentiel d'école — au même titre que le barème de
/// réductions, qui descend à la racine du même bundle.
///
/// **Une lecture ne remonte jamais d'erreur** : sans école résolue, ou sur une
/// base illisible, la série est vide. L'écran n'offre alors aucun choix de
/// devise, ce qui est exactement l'état d'avant la bascule — jamais un taux
/// inventé.
class ExchangeRateReader {
  final ExchangeRateDao _dao;
  final CurrentUserContext? _currentUser;

  const ExchangeRateReader({
    required ExchangeRateDao dao,
    CurrentUserContext? currentUser,
  }) : _dao = dao,
       _currentUser = currentUser;

  Future<List<ExchangeRate>> forCurrentSchool() async {
    final schoolId = _currentUser?.schoolId ?? '';
    if (schoolId.isEmpty) return const [];
    try {
      return await _dao.ratesForSchool(schoolId);
    } catch (_) {
      return const [];
    }
  }
}
