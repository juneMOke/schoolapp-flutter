import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

String resolveSelectPlaceholder(BuildContext context, String? placeholder) {
  final fromWidget = placeholder?.trim() ?? '';
  if (fromWidget.isNotEmpty) {
    return fromWidget;
  }
  return AppLocalizations.of(context)?.selectPlaceholderChoose ?? '';
}

String resolveSelectSemanticLabel(
  BuildContext context,
  String label,
  bool required,
) {
  if (!required) {
    return label;
  }
  final suffix = AppLocalizations.of(context)?.requiredSemanticSuffix ?? '';
  if (suffix.isEmpty) {
    return label;
  }
  return '$label, $suffix';
}
