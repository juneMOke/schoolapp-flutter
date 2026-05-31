/// Point de données pour un graphique d'évolution en ligne.
class LineChartPoint {
  final String label;
  final double value;
  final bool isHighlighted;

  const LineChartPoint({
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });
}
