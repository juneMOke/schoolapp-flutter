/// Libellés **propres à la feature** de la carte de recherche bi-mode.
///
/// Tout ce qui est commun aux quatre modules — la bascule, ses aides, les noms
/// des champs d'identité, les actions — vient directement d'[AppLocalizations].
/// Un même geste ne doit pas s'appeler « Par classe » ici et « Par cycle et
/// niveau » ailleurs.
class BiModeSearchLabels {
  final String title;
  final String helpBanner;
  final String cycleLabel;
  final String levelLabel;
  final String levelPlaceholder;

  const BiModeSearchLabels({
    required this.title,
    required this.helpBanner,
    required this.cycleLabel,
    required this.levelLabel,
    required this.levelPlaceholder,
  });
}
