import 'package:equatable/equatable.dart';

/// Ce qu'un poste de frais a rapporté **dans la fenêtre**.
///
/// Un flux et rien d'autre : ni attendu, ni reste dû, ni taux. La caisse compte
/// ce qui est entré dans le tiroir ; ce qu'il reste à recouvrer sur ce poste est
/// la question de l'**autre** onglet, et l'y mêler ferait lire un taux de
/// recouvrement là où le caissier cherche un montant à rapprocher de ses
/// billets.
class TillFeeCodeAmount extends Equatable {
  final String code;

  /// Le libellé français de la nature, envoyé par le serveur. Jamais vide : le
  /// mapping retombe sur le code.
  final String label;

  /// Encaissé sur ce poste dans la fenêtre, en centimes.
  final int amount;

  const TillFeeCodeAmount({
    required this.code,
    required this.label,
    required this.amount,
  });

  @override
  List<Object?> get props => [code, label, amount];
}
