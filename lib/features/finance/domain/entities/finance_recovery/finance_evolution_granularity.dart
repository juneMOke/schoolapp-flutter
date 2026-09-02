/// Le grain de l'axe du temps du recouvrement.
///
/// Le serveur ne rend plus que [month] — l'axe fait douze compartiments, du
/// mois de début de l'année scolaire à son terme. Les deux autres valeurs
/// survivent parce que le champ existe toujours sur le fil et qu'une lecture ne
/// doit jamais échouer sur une valeur qu'elle ne connaît pas.
enum FinanceEvolutionGranularity { month, week, day }
