import 'package:equatable/equatable.dart';

/// Une barre de l'axe du temps : ce qui est entré sur cet intervalle, dans la
/// devise du bloc.
///
/// **Les grandes lignes seulement** — total, frais, boutique — sans ventilation
/// par poste. Ce n'est pas une économie de place mais un choix de lecture : la
/// répartition se lit sur le résumé, une fois, là où on la cherche.
class TillBucket extends Equatable {
  /// `YYYY-MM-DD` sur un axe de journées (jour, semaine, mois), `YYYY-MM` sur
  /// l'axe annuel — **c'est la seule période où la clé change de forme**, et le
  /// formatteur de libellé doit s'en apercevoir.
  final String key;

  final int total;
  final int fees;
  final int boutique;

  /// L'intervalle en cours — celui qui n'est pas encore fini, et dont le montant
  /// montera encore avant la fermeture.
  final bool isCurrent;

  const TillBucket({
    required this.key,
    required this.total,
    required this.fees,
    required this.boutique,
    required this.isCurrent,
  });

  @override
  List<Object?> get props => [key, total, fees, boutique, isCurrent];
}
