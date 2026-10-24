/// Ce que l'adresse d'un agent donne à son cubit : qui, quel mois `AAAA-MM`
/// (le mois en cours à défaut), et l'ouverture de l'année.
typedef HrPresenceAgentArgs = ({
  String agentId,
  String? month,
  DateTime? yearStart,
});
