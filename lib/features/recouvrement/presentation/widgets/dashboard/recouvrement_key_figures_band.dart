import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_dashboard_bloc.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/recouvrement_key_figure_cards.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les quatre chiffres de tête : attendu, perçu, n'ont rien payé, partiel.
///
/// Rendus **seulement** quand une lecture a abouti et qu'elle a trouvé quelqu'un.
/// Quatre zéros avant d'avoir lu ne seraient pas une information, et l'état vide
/// du classement dit déjà mieux ce que veut dire « personne ».
class RecouvrementKeyFiguresBand extends StatelessWidget {
  const RecouvrementKeyFiguresBand({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<RecouvrementDashboardBloc, RecouvrementDashboardState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status || prev.figures != curr.figures,
      builder: (context, state) {
        final show =
            state.status == EnrollmentLoadStatus.success &&
            !state.figures.isEmpty;

        return AnimatedSwitcher(
          duration: AppMotion.layout,
          switchInCurve: AppMotion.outCurve,
          switchOutCurve: AppMotion.inCurve,
          child: show
              ? Padding(
                  key: const ValueKey('recouvrement-key-figures'),
                  padding: const EdgeInsets.only(
                    bottom: AppDimensions.spacingM,
                  ),
                  child: Semantics(
                    container: true,
                    label: l10n.recouvrementFiguresA11yLabel,
                    child: EteeloKpiBand(
                      cards: recouvrementKeyFigureCards(state.figures, l10n),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }
}
