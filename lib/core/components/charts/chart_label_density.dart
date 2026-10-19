/// Une étiquette d'abscisse sur combien : assez pour que deux étiquettes
/// voisines gardent [minSpacing] dp entre leurs centres sur [width] dp.
///
/// Sur un téléphone, douze mois sous 300 dp de tracé se chevauchaient dès
/// le huitième point ; une sur deux (ou trois) se lit.
int chartLabelStep({
  required int count,
  required double width,
  required double minSpacing,
}) {
  if (count <= 1 || width <= 0) return 1;
  final fitting = (width / minSpacing).floor();
  if (fitting <= 0) return count;
  return (count / fitting).ceil().clamp(1, count);
}
