/// Compare deux codes de niveau avec un tri naturel.
///
/// Exemples:
/// - 2B < 10A
/// - 1 < 1A < 1B
/// - A2 < A10
int compareLevelCodes(String a, String b) {
  final aTokens = _tokenize(a);
  final bTokens = _tokenize(b);

  final minLen = aTokens.length < bTokens.length
      ? aTokens.length
      : bTokens.length;

  for (var i = 0; i < minLen; i++) {
    final left = aTokens[i];
    final right = bTokens[i];

    final leftNum = int.tryParse(left);
    final rightNum = int.tryParse(right);

    if (leftNum != null && rightNum != null) {
      final cmp = leftNum.compareTo(rightNum);
      if (cmp != 0) return cmp;
      continue;
    }

    if (leftNum != null && rightNum == null) return -1;
    if (leftNum == null && rightNum != null) return 1;

    final cmp = left.toLowerCase().compareTo(right.toLowerCase());
    if (cmp != 0) return cmp;
  }

  return aTokens.length.compareTo(bTokens.length);
}

List<String> _tokenize(String input) {
  final matches = RegExp(r'\d+|\D+').allMatches(input.trim());
  return [for (final m in matches) m.group(0)!];
}
