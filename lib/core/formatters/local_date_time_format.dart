/// `JJ/MM/AAAA à HH:MM`, en heure locale.
///
/// Formateur **pur**, sans données de locale à initialiser : il se rend dans un
/// test unitaire comme dans un widget.
///
/// Il vivait dans `boutique_sale_detail_page.dart`, où son commentaire annonçait
/// déjà qu'il était « partagé avec la mention d'impression ». Il l'est
/// désormais pour de bon : la même mention existe sous le ticket d'une vente et
/// sous celui d'un encaissement, et une modale de Facturation ne doit pas
/// importer une page de Boutique pour l'obtenir. Deux copies auraient divergé au
/// premier ajustement de format — exactement ce qui est arrivé aux quatre mises
/// en forme de montants avant `MoneyFormat`.
///
/// L'instant est ramené au fuseau local : les horodatages stockés sont en UTC,
/// et les afficher tels quels décalerait le geste de plusieurs heures.
String formatLocalDateTime(DateTime instant) {
  final local = instant.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}
