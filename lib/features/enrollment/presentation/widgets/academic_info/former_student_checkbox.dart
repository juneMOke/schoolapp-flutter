import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Ancien élève de l'école » — le *nouveau / ancien* du formulaire.
///
/// **Délibérément distinct du type d'inscription.** L'enum décrit le chemin
/// technique suivi par le dossier, cette case un fait déclaré au guichet. Les
/// deux divergent dès qu'une école démarre sur l'application : tous ses anciens
/// élèves y entrent en NEW_ENROLLMENT, faute de dossier N-1 en base, et le
/// guichet doit pouvoir le contredire.
///
/// En réinscription, la case est **vraie et verrouillée** : l'élève vient d'un
/// dossier de l'année précédente dans cette école, c'est un fait acquis et non
/// une déclaration. Verrouillée en *lecture seule pleine couleur* — jamais
/// grisée : la valeur reste une information à lire, pas un champ désactivé
/// dont on douterait.
class FormerStudentCheckbox extends StatelessWidget {
  final AppLocalizations l10n;
  final bool value;
  final ValueChanged<bool> onChanged;

  /// Modifiable au guichet. `false` en réinscription, où le fait est acquis.
  final bool editable;

  /// Mis en évidence tant que la valeur diffère de celle enregistrée.
  final bool isChanged;

  const FormerStudentCheckbox({
    super.key,
    required this.l10n,
    required this.value,
    required this.onChanged,
    this.editable = true,
    this.isChanged = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final help = editable
        ? l10n.formerStudentHelp
        : l10n.formerStudentLockedHelp;

    return Semantics(
      checked: value,
      enabled: editable,
      label: l10n.formerStudentLabel,
      child: InkWell(
        onTap: editable ? () => onChanged(!value) : null,
        borderRadius: AppRadius.brSm,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.spacingXS,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // `IgnorePointer` plutôt que `onChanged: null` : la case garde sa
              // pleine couleur en lecture seule, elle ne se grise pas.
              IgnorePointer(
                ignoring: !editable,
                child: ExcludeFocus(
                  excluding: !editable,
                  child: Checkbox(
                    value: value,
                    onChanged: (checked) => onChanged(checked ?? false),
                    activeColor: AppColors.bleuArdoise,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppDimensions.spacingS),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.formerStudentLabel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isChanged
                              ? AppColors.bleuArdoise
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        help,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
