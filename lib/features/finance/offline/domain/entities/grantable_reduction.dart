import 'package:equatable/equatable.dart';

/// Une réduction **proposable au guichet** : un code, un libellé.
///
/// Volontairement sans taux. En V1 la case à cocher n'affiche pas de
/// pourcentage — rien ne promet un montant, donc l'écart entre la remise
/// annoncée et une créance inchangée n'existe pas. Le jour où la V2 calculera,
/// c'est ici que le taux entrera, pas dans l'écran.
///
/// « Proposable » est plus fort qu'« actif » : un type sans aucune ligne de
/// barème ne réduira jamais rien, et le taux étant masqué il serait
/// indiscernable à l'écran d'un type qui réduit. Le cocher graverait un octroi
/// vide dont la V2 hériterait. Le filtre vit dans la requête, pas dans l'UI.
class GrantableReduction extends Equatable {
  final String code;
  final String label;

  const GrantableReduction({required this.code, required this.label});

  @override
  List<Object?> get props => [code, label];
}
