import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_warning.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'alerte des personnes encore « à pointer », avant de valider la journée :
/// leurs noms (les premiers, puis « et N autres »), et « Voir la liste » qui
/// ramène au registre filtré sur elles.
class PresenceUnmarkedNotice extends StatelessWidget {
  final List<String> names;

  /// `null` : pas de retour au registre proposé.
  final VoidCallback? onReview;

  const PresenceUnmarkedNotice({super.key, required this.names, this.onReview});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onReview = this.onReview;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        PresenceWarning(
          icon: Icons.person_search_outlined,
          message: PresenceLabels.unmarkedNames(l10n, names),
        ),
        if (onReview != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: EteeloButton.ghost(
              label: l10n.presenceMarkReviewUnmarked,
              icon: Icons.filter_list,
              onPressed: onReview,
              fullWidth: false,
            ),
          ),
        ],
      ],
    );
  }
}
